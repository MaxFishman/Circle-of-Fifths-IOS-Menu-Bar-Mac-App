import SwiftUI

@main
struct CircleOfFifthsMenuBarApp: App {
    var body: some Scene {
        MenuBarExtra("Circle of Fifths", systemImage: "music.note") {
            ContentView()
                .frame(width: 500, height: 560)
                .padding(10)
        }
        .menuBarExtraStyle(.window)
    }
}
