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

class FloatingWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.isMovableByWindowBackground = true
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
        
        // Higher window level to float above menu bar but allow clicks
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 1)
        window.isOpaque = false
        window.hasShadow = false
        window.backgroundColor = NSColor.clear
        window.isMovableByWindowBackground = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.ignoresMouseEvents = false
        
        window.contentView = NSHostingView(rootView: floatingView)
        
        positionInNotch(window) // Changed method name for clarity
        window.orderFront(nil)
    }
    
    private func positionInNotch(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.frame
        let windowSize = window.frame.size
        
        // Position directly at the top center (in the notch area)
        let x = screenFrame.midX - (windowSize.width / 2)
        let y = screenFrame.maxY - windowSize.height // Position at very top
        
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

