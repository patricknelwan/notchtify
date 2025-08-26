import SwiftUI

@main
struct NotchtifyApp: App {
    @StateObject private var spotifyManager = SpotifyManager()
    
    var body: some Scene {
        // Main control window (can be hidden)
        WindowGroup {
            ContentView()
                .environmentObject(spotifyManager)
        }
        .windowStyle(.hiddenTitleBar)
        
        // Floating Dynamic Island
        WindowGroup("Dynamic Island") {
            FloatingDynamicIsland()
                .environmentObject(spotifyManager)
        }
        .windowLevel(.floating)              // Always on top
        .windowStyle(.plain)                 // No title bar
        .windowResizability(.contentSize)    // Can't resize
        .defaultWindowPlacement { content, context in
            // Position at top center of screen
            let displayBounds = context.defaultDisplay.visibleRect
            let size = content.sizeThatFits(.unspecified)
            let position = CGPoint(
                x: displayBounds.midX - (size.width / 2),
                y: displayBounds.maxY - size.height - 20
            )
            return WindowPlacement(position, size: size)
        }
    }
}

struct FloatingDynamicIsland: View {
    @EnvironmentObject var spotifyManager: SpotifyManager
    @State private var isExpanded = false
    
    var body: some View {
        SpotifyDynamicIsland(
            spotifyManager: spotifyManager,
            isExpanded: $isExpanded
        )
        .background(Color.clear)
        .onAppear {
            spotifyManager.startMonitoring()
        }
    }
}
