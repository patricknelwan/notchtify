import SwiftUI

struct ContentView: View {
    @EnvironmentObject var spotifyManager: SpotifyManager
    
    var body: some View {
        VStack(spacing: 25) {
            VStack(spacing: 12) {
                Text("Notchtify")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Dynamic Island for Spotify")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                Text("Status")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    Circle()
                        .fill(spotifyManager.isSpotifyRunning ? .green : .red)
                        .frame(width: 10, height: 10)
                    
                    Text(spotifyManager.isSpotifyRunning ? "Connected to Spotify" : "Spotify not detected")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                if spotifyManager.isSpotifyRunning && spotifyManager.isPlaying {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Now Playing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            if let albumArt = spotifyManager.albumArtImage {
                                Image(nsImage: albumArt)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 40, height: 40)
                                    .cornerRadius(6)
                            } else {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        Image(systemName: "music.note")
                                            .foregroundColor(.gray)
                                    }
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(spotifyManager.currentTrack)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                
                                Text(spotifyManager.currentArtist)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
            }
            
            if spotifyManager.isSpotifyRunning {
                VStack(spacing: 12) {
                    Text("Controls")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 20) {
                        Button(action: { spotifyManager.previousTrack() }) {
                            Image(systemName: "backward.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: { spotifyManager.togglePlayPause() }) {
                            Image(systemName: spotifyManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button(action: { spotifyManager.nextTrack() }) {
                            Image(systemName: "forward.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            
            VStack(spacing: 12) {
                Text("Settings")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Auto-expand when track changes", isOn: $spotifyManager.autoExpand)
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Appearance")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Island Position")
                            Spacer()
                            Text("Menu Bar Center")
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 16)
                        
                        HStack {
                            Text("Animation Speed")
                            Spacer()
                            Text("Normal")
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 16)
                    }
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Text("Check your menu bar for the Dynamic Island!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
                
                HStack(spacing: 16) {
                    Button("Quit Notchtify") {
                        NSApplication.shared.terminate(nil)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("About") {
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(30)
        .frame(width: 420, height: 650)
        .onAppear {
            spotifyManager.startMonitoring()
        }
        .onDisappear {
            spotifyManager.stopMonitoring()
        }
    }
}

#Preview {
    ContentView()
}
