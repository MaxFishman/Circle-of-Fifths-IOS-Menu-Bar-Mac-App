import SwiftUI

@main
struct CircleOfFifthsMenuBarApp: App {
    var body: some Scene {
        MenuBarExtra("Circle of Fifths", systemImage: "music.note") {
            ContentView()
                .frame(width: 560, height: 650)
                .padding(14)
        }
        .menuBarExtraStyle(.window)
    }
}
