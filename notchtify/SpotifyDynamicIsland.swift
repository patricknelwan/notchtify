import SwiftUI

struct SpotifyDynamicIsland: View {
    @ObservedObject var spotifyManager: SpotifyManager
    @Binding var isExpanded: Bool
    @State private var isHovered = false
    
    var body: some View {
        UnevenRoundedRectangle(
            cornerRadii: .init(
                topLeading: 0,
                bottomLeading: isExpanded ? 30 : 20,
                bottomTrailing: isExpanded ? 30 : 20,
                topTrailing: 0
            )
        )
        .fill(.black)
        .frame(
            width: isExpanded ? 450 : getCompactWidth(),
            height: isExpanded ? 160 : getCompactHeight()
        )
        .scaleEffect(isHovered && !isExpanded ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
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
        .onHover { hovering in
            isHovered = hovering
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
    
    private func getCompactHeight() -> CGFloat {
        if spotifyManager.isSpotifyRunning && spotifyManager.isPlaying {
            return 40
        } else if spotifyManager.isSpotifyRunning {
            return 32
        } else {
            return 28
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
                HStack(spacing: 6) {
                    Image(systemName: "music.note")
                        .foregroundColor(.green)
                        .font(.system(size: 9))
                    
                    Text("Ready")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "music.note")
                        .foregroundColor(.red)
                        .font(.system(size: 8))
                    
                    Text("Offline")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
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
                            .frame(width: 80, height: 80)
                            .cornerRadius(12)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay {
                                Image(systemName: "music.note")
                                    .foregroundColor(.gray)
                                    .font(.title)
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(spotifyManager.currentTrack.isEmpty ? "No track" : spotifyManager.currentTrack)
                            .font(.title2)  // Increased from .headline to .title2
                            .fontWeight(.semibold)  // Added weight for better readability
                            .foregroundColor(.white)
                            .lineLimit(2)  // Increased from 1 to 2 lines for longer titles
                        
                        Text(spotifyManager.currentArtist.isEmpty ? "Unknown artist" : spotifyManager.currentArtist)
                            .font(.title3)  // Increased from .subheadline to .title3
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                        
                        if !spotifyManager.currentAlbum.isEmpty {
                            Text(spotifyManager.currentAlbum)
                                .font(.body)  // Increased from .caption to .body
                                .foregroundColor(.white.opacity(0.5))
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                }
                
                if spotifyManager.showProgress && spotifyManager.trackDuration > 0 {
                    VStack(spacing: 4) {
                        ProgressView(value: spotifyManager.trackPosition, total: spotifyManager.trackDuration)
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                            .scaleEffect(y: 0.5)
                        
                        HStack {
                            Text(formatTime(spotifyManager.trackPosition))
                                .font(.caption)  // Increased from .caption2 to .caption
                                .foregroundColor(.white.opacity(0.6))
                            
                            Spacer()
                            
                            Text(formatTime(spotifyManager.trackDuration))
                                .font(.caption)  // Increased from .caption2 to .caption
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                
                HStack(spacing: 25) {
                    Button {
                        spotifyManager.previousTrack()
                    } label: {
                        Image(systemName: "backward.fill")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.title)  // Increased from .title2 to .title
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        spotifyManager.togglePlayPause()
                    } label: {
                        Image(systemName: spotifyManager.isPlaying ? "pause.fill" : "play.fill")
                            .foregroundColor(.white)
                            .font(.largeTitle)  // Increased from .title to .largeTitle
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        spotifyManager.nextTrack()
                    } label: {
                        Image(systemName: "forward.fill")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.title)  // Increased from .title2 to .title
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
