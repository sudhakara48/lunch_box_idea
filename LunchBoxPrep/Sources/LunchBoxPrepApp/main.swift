import SwiftUI
import LunchBoxPrep

struct LunchBoxPrepMacApp: App {
    var body: some Scene {
        WindowGroup {
            AppRoot()
                .frame(minWidth: 400, minHeight: 700)
        }
    }
}

LunchBoxPrepMacApp.main()
