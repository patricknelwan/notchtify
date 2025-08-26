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
        
        let floatingView = FloatingDynamicIslandView()
            .environmentObject(spotifyManager)
        
        floatingWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 200),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        guard let window = floatingWindow else { return }
        
//        Configure for menu bar floating
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 1) // Above menu bar
        window.isOpaque = false
        window.hasShadow = false
        window.backgroundColor = NSColor.clear
        window.isMovableByWindowBackground = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        
//        Set SwiftUI view as content
        window.contentView = NSHostingView(rootView: floatingView)
        
        positionInMenuBar(window)
        
        window.makeKeyAndOrderFront(nil)
    }
    
    private func positionInMenuBar(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.frame
        let menuBarHeight: CGFloat = 24 // Standard menu bar height
        let windowSize = window.frame.size
        
        let x = screenFrame.midX - (windowSize.width / 2)
        let y = screenFrame.maxY - menuBarHeight - windowSize.height + menuBarHeight // Position within menu bar
        
        window.setFrame(
            NSRect(x: x, y: y, width: windowSize.width, height: windowSize.height),
            display: true,
            animate: false
        )
    }
}


struct FloatingDynamicIslandView: View {
    @EnvironmentObject var spotifyManager: SpotifyManager
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            SpotifyDynamicIsland(
                spotifyManager: spotifyManager,
                isExpanded: $isExpanded
            )
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.clear)
        .allowsHitTesting(true)
        .contentShape(Rectangle())
        .onAppear {
            spotifyManager.startMonitoring()
        }
    }
}



