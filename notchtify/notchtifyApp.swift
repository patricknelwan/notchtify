import SwiftUI
import AppKit

@main
struct NotchtifyApp: App {
    @StateObject private var spotifyManager = SpotifyManager()
    @StateObject private var floatingWindowManager = FloatingWindowManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(spotifyManager)
                .onAppear {
                    floatingWindowManager.createFloatingWindow(spotifyManager: spotifyManager)
                }
        }
        .windowStyle(.hiddenTitleBar)
    }
}

class FloatingWindowManager: ObservableObject {
    private var floatingWindow: NSWindow?
    
    func createFloatingWindow(spotifyManager: SpotifyManager) {
        print("🏝️ Creating floating window...")
        
        let floatingView = FloatingDynamicIslandView()
            .environmentObject(spotifyManager)
        
        // Create a LARGE fixed window that can contain both compact and expanded states
        floatingWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 200), // Large enough for expanded state
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        guard let window = floatingWindow else { return }
        
        // Configure window
        window.level = .floating
        window.isOpaque = false
        window.hasShadow = false
        window.backgroundColor = NSColor.clear
        window.isMovableByWindowBackground = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        
        // Set SwiftUI view as content
        window.contentView = NSHostingView(rootView: floatingView)
        
        // Position at notch location
        positionAtNotchLocation(window)
        
        // Show window
        window.makeKeyAndOrderFront(nil)
        
        print("✅ Fixed-size floating window created!")
    }
    
    private func positionAtNotchLocation(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.frame
        let windowSize = window.frame.size
        
        // Position so the window is centered at the notch
        let x = screenFrame.midX - (windowSize.width / 2)
        let y = screenFrame.maxY - windowSize.height - 2
        
        window.setFrame(
            NSRect(x: x, y: y, width: windowSize.width, height: windowSize.height),
            display: true,
            animate: false
        )
        
        print("📍 Fixed window positioned at notch center")
    }
}

struct FloatingDynamicIslandView: View {
    @EnvironmentObject var spotifyManager: SpotifyManager
    @State private var isExpanded = false
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                SpotifyDynamicIsland(
                    spotifyManager: spotifyManager,
                    isExpanded: $isExpanded
                )
                
                Spacer()
            }
            Spacer()
        }
        .background(Color.clear)
        .allowsHitTesting(true)
        .contentShape(Rectangle())
        .onAppear {
            spotifyManager.startMonitoring()
        }
    }
}


