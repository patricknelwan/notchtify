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
    private var builtInScreen: NSScreen?
    
    @Published var isExpanded = false {
        didSet {
            updateWindowFrameInstantly()
        }
    }
    
    @Published var isContainerExpanded = false
    
    func createFloatingWindow(spotifyManager: SpotifyManager) {
        builtInScreen = getBuiltInScreen()
        
        let floatingView = FloatingDynamicIslandView()
            .environmentObject(spotifyManager)
            .environmentObject(self)
        
        floatingWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 200),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        guard let window = floatingWindow else { return }
        
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 1)
        window.isOpaque = false
        window.hasShadow = false
        window.backgroundColor = NSColor.clear
        window.isMovableByWindowBackground = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.ignoresMouseEvents = false
        
        window.contentView = NSHostingView(rootView: floatingView)
        
        positionInNotch(window)
        window.orderFront(nil)
    }
    
    private func getBuiltInScreen() -> NSScreen? {
        return NSScreen.screens.first
    }

    
    private func updateWindowFrameInstantly() {
        guard let window = floatingWindow else { return }
        guard let screen = builtInScreen else { return }
        let screenFrame = screen.frame
        
        let newWidth: CGFloat = (isExpanded ? 450 : getCompactWidth()) + 45
        let newHeight: CGFloat = (isExpanded ? 160 : getCompactHeight()) + 0
        
        let centeredX = screenFrame.midX - (newWidth / 2)
        
        let compactHeight: CGFloat = getCompactHeight()
        let topY = screenFrame.maxY - compactHeight
        let newY = topY - (newHeight - compactHeight)
        
        let centeredFrame = NSRect(
            x: centeredX,
            y: newY,
            width: newWidth,
            height: newHeight
        )
        
        window.setFrame(centeredFrame, display: false, animate: false)
    }


    
    private func positionInNotch(_ window: NSWindow) {
        // Use built-in screen for initial positioning too
        guard let screen = builtInScreen else { return }
        
        let screenFrame = screen.frame
        let windowSize = window.frame.size
        
        let x = screenFrame.midX - (windowSize.width / 2)
        let y = screenFrame.maxY - windowSize.height
        
        window.setFrame(
            NSRect(x: x, y: y, width: windowSize.width, height: windowSize.height),
            display: true,
            animate: false
        )
    }
    
    private func getCompactWidth() -> CGFloat {
        return 260
    }
    
    private func getCompactHeight() -> CGFloat {
        return 40
    }
}


struct FloatingDynamicIslandView: View {
    @EnvironmentObject var spotifyManager: SpotifyManager
    @EnvironmentObject var windowManager: FloatingWindowManager
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                SpotifyDynamicIsland(
                    spotifyManager: spotifyManager,
                    isExpanded: $windowManager.isExpanded,
                    windowManager: windowManager
                )
            }
            .frame(
                width: (windowManager.isExpanded ? 450 : getCompactWidth()) + 45,
                height: (windowManager.isExpanded ? 160 : getCompactHeight()) + 0
            )
            .contentShape(Rectangle())
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.clear) // To see the container
        .allowsHitTesting(true)
        .onAppear {
            spotifyManager.startMonitoring()
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
