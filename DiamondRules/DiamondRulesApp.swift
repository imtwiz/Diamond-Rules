import SwiftUI
@main struct DiamondRulesApp: App {
    @StateObject private var store = RuleStore()
    var body: some Scene { WindowGroup { RootView().environmentObject(store) } }
}