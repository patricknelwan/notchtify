import SwiftUI

struct ContentView: View {
    @StateObject private var spotifyManager = SpotifyManager()
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 30) {
//            Header
            VStack {
                Text("Notchtify")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Dynamic Island for Spotify")
                    .foregroundColor(.secondary)
            }
            
//            Spotify Dynamic Island
            SpotifyDynamicIsland(
                spotifyManager: spotifyManager,
                isExpanded: $isExpanded
            )
            
//            Controls
            VStack(spacing: 15) {
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
                
//                Settings
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
                if let albumArt = spotifyManager.albumArtImage {
                    Image(nsImage: albumArt)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 20)
                        .cornerRadius(4)
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .overlay {
                            Image(systemName: "music.note")
                                .foregroundColor(.green)
                                .font(.system(size: 8))
                        }
                }
                
                Spacer()
                
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
                HStack(spacing: 12) {
                    if let albumArt = spotifyManager.albumArtImage {
                        Image(nsImage: albumArt)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .cornerRadius(8)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .overlay {
                                Image(systemName: "music.note")
                                    .foregroundColor(.gray)
                                    .font(.title2)
                            }
                    }
                    
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
                
//                Progress Bar (WIP)
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
                
//                Playback Control
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
