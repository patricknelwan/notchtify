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
    @Published var isExpanded = false {
        didSet {
            // Update window frame instantly without animation
            updateWindowFrameInstantly()
        }
    }
    
    func createFloatingWindow(spotifyManager: SpotifyManager) {
        let floatingView = FloatingDynamicIslandView()
            .environmentObject(spotifyManager)
            .environmentObject(self) // Pass window manager as environment object
        
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
    
    private func updateWindowFrameInstantly() {
        guard let window = floatingWindow else { return }
        
        // Get current window position before resize
        let currentFrame = window.frame
        
        // Calculate new dimensions
        let newWidth: CGFloat = (isExpanded ? 450 : getCompactWidth()) + 40
        let newHeight: CGFloat = (isExpanded ? 160 : getCompactHeight()) + 2
        
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        
        // Calculate the centered X position for the NEW width
        let centeredX = screenFrame.midX - (newWidth / 2)
        
        // Keep the same Y position (top stays fixed to notch)
        let centeredFrame = NSRect(
            x: centeredX,  // Recalculated center for new width
            y: screenFrame.maxY - newHeight,
            width: newWidth,
            height: newHeight
        )
        
        window.setFrame(centeredFrame, display: false, animate: false)
    }



    private func getCompactWidth() -> CGFloat {
        return 260 // Match your SpotifyDynamicIsland
    }

    private func getCompactHeight() -> CGFloat {
        return 40 // Match your SpotifyDynamicIsland
    }

    private func positionInNotch(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        
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
}

struct FloatingDynamicIslandView: View {
    @EnvironmentObject var spotifyManager: SpotifyManager
    @EnvironmentObject var windowManager: FloatingWindowManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Container that's 2 pixels larger than the Dynamic Island
            ZStack {
                // Your perfect Dynamic Island (unchanged)
                SpotifyDynamicIsland(
                    spotifyManager: spotifyManager,
                    isExpanded: $windowManager.isExpanded
                )
            }
            .frame(
                width: (windowManager.isExpanded ? 450 : getCompactWidth()) + 40,
                height: (windowManager.isExpanded ? 160 : getCompactHeight()) + 2
            )
            // KEY: This centers the content within the larger frame
            .contentShape(Rectangle())
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.clear)
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

