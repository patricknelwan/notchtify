import SwiftUI

struct ContentView: View {
    @StateObject private var spotifyManager = SpotifyManager()
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack {
                Text("Notchtify")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Dynamic Island for Spotify")
                    .foregroundColor(.secondary)
            }
            
            // Spotify Dynamic Island
            SpotifyDynamicIsland(
                spotifyManager: spotifyManager,
                isExpanded: $isExpanded
            )
            
            // Connection Status
            HStack {
                Circle()
                    .fill(spotifyManager.isSpotifyRunning ? .green : .red)
                    .frame(width: 8, height: 8)
                
                Text(spotifyManager.isSpotifyRunning ? "Connected to Spotify" : "Spotify not detected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Controls
            VStack(spacing: 15) {
                Button("Toggle Island") {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                if spotifyManager.isSpotifyRunning {
                    HStack(spacing: 15) {
                        Button("⏮") {
                            spotifyManager.previousTrack()
                        }
                        .buttonStyle(.bordered)
                        
                        Button(spotifyManager.isPlaying ? "⏸" : "▶️") {
                            spotifyManager.togglePlayPause()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("⏭") {
                            spotifyManager.nextTrack()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Button("Refresh Spotify Status") {
                    spotifyManager.checkSpotifyStatus()
                }
                .buttonStyle(.bordered)
                
                // Settings
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Auto-expand when music changes", isOn: $spotifyManager.autoExpand)
                    Toggle("Show track progress", isOn: $spotifyManager.showProgress)
                }
                .padding(.top)
            }
        }
        .padding(40)
        .frame(width: 500, height: 600)
        .onAppear {
            spotifyManager.startMonitoring()
        }
        .onDisappear {
            spotifyManager.stopMonitoring()
        }
    }
}

struct SpotifyDynamicIsland: View {
    @ObservedObject var spotifyManager: SpotifyManager
    @Binding var isExpanded: Bool
    
    var body: some View {
        // Using UnevenRoundedRectangle for sharp top, rounded bottom
        UnevenRoundedRectangle(
            cornerRadii: .init(
                topLeading: 0,      // Sharp top left
                bottomLeading: isExpanded ? 30 : 20,  // Rounded bottom left
                bottomTrailing: isExpanded ? 30 : 20, // Rounded bottom right
                topTrailing: 0      // Sharp top right
            )
        )
        .fill(.black)
        .frame(
            width: isExpanded ? 450 : getCompactWidth(),
            height: isExpanded ? 160 : 40
        )
        .overlay {
            if isExpanded {
                SpotifyExpandedView(spotifyManager: spotifyManager)
            } else {
                SpotifyCompactView(spotifyManager: spotifyManager)
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        }
        // FIXED: Updated onChange for macOS 14.0+
        .onChange(of: spotifyManager.currentTrack) { oldValue, newValue in
            if spotifyManager.autoExpand && spotifyManager.isPlaying {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isExpanded = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        isExpanded = false
                    }
                }
            }
        }
    }
    
    private func getCompactWidth() -> CGFloat {
        if spotifyManager.isSpotifyRunning && spotifyManager.isPlaying {
            return 280
        } else {
            return 200
        }
    }
}



struct SpotifyCompactView: View {
    @ObservedObject var spotifyManager: SpotifyManager
    
    var body: some View {
        HStack(spacing: 8) {
            if spotifyManager.isSpotifyRunning && spotifyManager.isPlaying {
                // Mini Album Cover (replaces green circle)
                AsyncImage(url: URL(string: "https://via.placeholder.com/20x20/333333/FFFFFF?text=♫")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .overlay {
                            Image(systemName: "music.note")
                                .foregroundColor(.green)
                                .font(.system(size: 8))
                        }
                }
                .frame(width: 20, height: 20)
                .cornerRadius(4)
                
                Spacer() // Pushes audio visualization to the right
                
                // Audio visualization
                HStack(spacing: 1) {
                    ForEach(0..<3) { index in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(.green)
                            .frame(width: 2, height: CGFloat.random(in: 4...12))
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(Double(index) * 0.2), value: UUID())
                    }
                }
                
            } else if spotifyManager.isSpotifyRunning {
                Image(systemName: "music.note")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Spacer()
                
                Text("Spotify ready")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            } else {
                Image(systemName: "music.note")
                    .foregroundColor(.red)
                    .font(.caption)
                
                Spacer()
                
                Text("No Spotify")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 12)
    }
}


struct SpotifyExpandedView: View {
    @ObservedObject var spotifyManager: SpotifyManager
    
    var body: some View {
        VStack(spacing: 15) {
            if spotifyManager.isSpotifyRunning {
                // Track Info with Album Art
                HStack(spacing: 12) {
                    // Album Art (placeholder for now - can be enhanced to fetch real cover)
                    AsyncImage(url: URL(string: "https://via.placeholder.com/50x50/333333/FFFFFF?text=♫")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .overlay {
                                Image(systemName: "music.note")
                                    .foregroundColor(.gray)
                                    .font(.title2)
                            }
                    }
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(spotifyManager.currentTrack.isEmpty ? "No track" : spotifyManager.currentTrack)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(spotifyManager.currentArtist.isEmpty ? "Unknown artist" : spotifyManager.currentArtist)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                        
                        if !spotifyManager.currentAlbum.isEmpty {
                            Text(spotifyManager.currentAlbum)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                }
                
                // Progress Bar (if enabled)
                if spotifyManager.showProgress && spotifyManager.trackDuration > 0 {
                    VStack(spacing: 4) {
                        ProgressView(value: spotifyManager.trackPosition, total: spotifyManager.trackDuration)
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                            .scaleEffect(y: 0.5)
                        
                        HStack {
                            Text(formatTime(spotifyManager.trackPosition))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                            
                            Spacer()
                            
                            Text(formatTime(spotifyManager.trackDuration))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                
                // Playback Controls
                HStack(spacing: 25) {
                    Button {
                        spotifyManager.previousTrack()
                    } label: {
                        Image(systemName: "backward.fill")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.title2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        spotifyManager.togglePlayPause()
                    } label: {
                        Image(systemName: spotifyManager.isPlaying ? "pause.fill" : "play.fill")
                            .foregroundColor(.white)
                            .font(.title)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        spotifyManager.nextTrack()
                    } label: {
                        Image(systemName: "forward.fill")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.title2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "music.note.slash")
                        .foregroundColor(.red)
                        .font(.title)
                    
                    Text("Spotify Not Running")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Please open Spotify to control playback")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 20)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}


#Preview {
    ContentView()
}
