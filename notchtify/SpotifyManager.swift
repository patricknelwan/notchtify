import SwiftUI
import Foundation

class SpotifyManager: ObservableObject {
    @Published var isSpotifyRunning = false
    @Published var isPlaying = false
    @Published var currentTrack = "No track playing"
    @Published var currentArtist = "Unknown artist"
    @Published var currentAlbum = ""
    @Published var trackPosition: Double = 0
    @Published var trackDuration: Double = 0
    @Published var autoExpand = true
    @Published var showProgress = false // Disable by default since it's unreliable
    
    private var timer: Timer?
    private var retryCount = 0
    private let maxRetries = 3
    
    init() {
        checkSpotifyStatus()
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.updateSpotifyStatus()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    func checkSpotifyStatus() {
        let script = """
        try
            tell application "Spotify"
                if it is running then
                    return "RUNNING"
                else
                    return "NOT_RUNNING"
                end if
            end tell
        on error
            return "NOT_FOUND"
        end try
        """
        
        executeAppleScript(script) { result in
            DispatchQueue.main.async {
                if let resultString = result?.stringValue {
                    print("✅ Spotify detection: \(resultString)")
                    self.isSpotifyRunning = (resultString == "RUNNING")
                    
                    if self.isSpotifyRunning {
                        self.attemptSpotifyConnection()
                    } else {
                        self.resetSpotifyInfo()
                    }
                }
            }
        }
    }

    
    private func attemptSpotifyConnection() {
        let script = """
        try
            tell application "Spotify"
                if it is running then
                    try
                        set currentTrack to name of current track
                        set currentArtist to artist of current track
                        set isPlayingState to (player state is playing)
                        return currentTrack & "|||" & currentArtist & "|||" & (isPlayingState as string)
                    on error
                        return "SPOTIFY_NO_TRACK"
                    end try
                else
                    return "SPOTIFY_NOT_RUNNING"
                end if
            end tell
        on error
            return "SPOTIFY_ERROR"
        end try
        """
        
        executeAppleScript(script) { result in
            DispatchQueue.main.async {
                if let resultString = result?.stringValue {
                    print("🎵 Spotify response: \(resultString)")
                    
                    if resultString.contains("|||") {
                        // Successfully got track info
                        let components = resultString.components(separatedBy: "|||")
                        if components.count == 3 {
                            self.currentTrack = components[0].isEmpty ? "No track playing" : components[0]
                            self.currentArtist = components[1].isEmpty ? "Unknown artist" : components[1]
                            self.isPlaying = components[2] == "true"
                            self.retryCount = 0
                        }
                    } else if resultString == "SPOTIFY_NO_TRACK" {
                        // Spotify is running but no track info
                        self.currentTrack = "No track playing"
                        self.currentArtist = "Unknown artist"
                        self.isPlaying = false
                    } else if resultString == "SPOTIFY_ERROR" && self.retryCount < self.maxRetries {
                        // Retry connection
                        self.retryCount += 1
                        print("🔄 Retrying Spotify connection (\(self.retryCount)/\(self.maxRetries))")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.attemptSpotifyConnection()
                        }
                    } else {
                        // All retries failed
                        self.currentTrack = "Spotify not responding"
                        self.currentArtist = "Try restarting Spotify"
                        self.isPlaying = false
                    }
                }
            }
        }
    }
    
    private func updateSpotifyStatus() {
        guard isSpotifyRunning else {
            checkSpotifyStatus() // Re-check if Spotify was started
            return
        }
        
        attemptSpotifyConnection()
    }
    
    private func resetSpotifyInfo() {
        currentTrack = "No track playing"
        currentArtist = "Unknown artist"
        currentAlbum = ""
        isPlaying = false
        trackPosition = 0
        trackDuration = 0
    }
    
    func togglePlayPause() {
        executeSimpleSpotifyCommand("playpause")
    }
    
    func nextTrack() {
        executeSimpleSpotifyCommand("next track")
    }
    
    func previousTrack() {
        executeSimpleSpotifyCommand("previous track")
    }
    
    private func executeSimpleSpotifyCommand(_ command: String) {
        let script = """
        try
            tell application "Spotify"
                \(command)
                return "SUCCESS"
            end tell
        on error errMsg
            return "ERROR: " & errMsg
        end try
        """
        
        executeAppleScript(script) { result in
            if let resultString = result?.stringValue {
                print("🎮 Command '\(command)' result: \(resultString)")
                if resultString == "SUCCESS" {
                    // Wait a moment then update status
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.updateSpotifyStatus()
                    }
                }
            }
        }
    }
    
    private func executeAppleScript(_ script: String, completion: @escaping (NSAppleEventDescriptor?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            var error: NSDictionary?
            let appleScript = NSAppleScript(source: script)
            let result = appleScript?.executeAndReturnError(&error)
            
            if let error = error {
                print("❌ AppleScript error: \(error)")
            }
            
            completion(result)
        }
    }
    
    deinit {
        stopMonitoring()
    }
}
