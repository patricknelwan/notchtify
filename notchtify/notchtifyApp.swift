import SwiftUI

@main
struct NotchtifyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        // Simple floating test
        WindowGroup("Test Float") {
            Text("🏝️ I should be floating!")
                .font(.title)
                .padding(20)
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(20)
                .background(WindowMaker { window in
                    window?.level = .floating
                    window?.backgroundColor = .clear
                })
        }
        .windowStyle(.plain)
    }
}

struct WindowMaker: NSViewRepresentable {
    let callback: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { [view] in
            callback(view.window)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
