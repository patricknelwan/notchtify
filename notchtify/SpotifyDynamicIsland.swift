import SwiftUI

struct SpotifyDynamicIsland: View {
    @ObservedObject var spotifyManager: SpotifyManager
    @Binding var isExpanded: Bool
    @State private var isHovered = false
    @State private var playingScale: CGFloat = 1.0
    
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
        .scaleEffect(playingScale * (isHovered && !isExpanded ? 1.05 : 1.0))
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: playingScale)
        .overlay {
            if isExpanded {
                SpotifyExpandedView(spotifyManager: spotifyManager)
            } else {
                SpotifyCompactView(
                    spotifyManager: spotifyManager,
                    dynamicIslandWidth: getCompactWidth()
                )
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
        .onChange(of: spotifyManager.isPlaying) { oldValue, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                playingScale = newValue ? 1.1 : 1.0
            }
        }
    }
    
    private func getCompactWidth() -> CGFloat {
        if spotifyManager.isSpotifyRunning && spotifyManager.isPlaying {
            return 260
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
    let dynamicIslandWidth: CGFloat
    @State private var visualizerVisible = false
    
    var body: some View {
        HStack(spacing: 8) {
            if spotifyManager.isSpotifyRunning && spotifyManager.isPlaying {
                Group {
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
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.1).combined(with: .opacity),
                    removal: .identity
                ))
                .animation(.spring(response: 1.2, dampingFraction: 0.8), value: spotifyManager.albumArtImage != nil)
                
                Spacer()
                
                HStack(spacing: 1) {
                    ForEach(0..<3) { index in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(.green)
                            .frame(width: 2, height: CGFloat.random(in: 4...12))
                            .scaleEffect(visualizerVisible ? 1.0 : 0.1)
                            .animation(
                                .spring(response: 1.0, dampingFraction: 0.7)
                                .delay(Double(index) * 0.2),
                                value: visualizerVisible
                            )
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: UUID()
                            )
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .identity
                ))
                .onAppear {
                    withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                        visualizerVisible = true
                    }
                }
                .onDisappear {
                    visualizerVisible = false
                }
                
            } else if spotifyManager.isSpotifyRunning {
                HStack(spacing: 6) {
                    Image(systemName: "music.note")
                        .foregroundColor(.green)
                        .font(.system(size: 9))
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                    
                    Text("Ready")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .transition(.slide.combined(with: .opacity))
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .identity
                ))
                
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "music.note")
                        .foregroundColor(.red)
                        .font(.system(size: 8))
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                    
                    Text("Offline")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .transition(.slide.combined(with: .opacity))
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .identity
                ))
            }
        }
        .animation(.spring(response: 1.2, dampingFraction: 0.8), value: spotifyManager.isPlaying)
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
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Text(spotifyManager.currentArtist.isEmpty ? "Unknown artist" : spotifyManager.currentArtist)
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                        
                        if !spotifyManager.currentAlbum.isEmpty {
                            Text(spotifyManager.currentAlbum)
                                .font(.body)
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
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            
                            Spacer()
                            
                            Text(formatTime(spotifyManager.trackDuration))
                                .font(.caption)
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
                            .font(.title)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        spotifyManager.togglePlayPause()
                    } label: {
                        Image(systemName: spotifyManager.isPlaying ? "pause.fill" : "play.fill")
                            .foregroundColor(.white)
                            .font(.largeTitle)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        spotifyManager.nextTrack()
                    } label: {
                        Image(systemName: "forward.fill")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.title)
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
                    
                    Text("Please open Spotify to control playbook")
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
