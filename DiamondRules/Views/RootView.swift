import SwiftUI
struct RootView:View {
 @EnvironmentObject var store:RuleStore
 var body:some View { TabView {
  NavigationStack { AskView() }.tabItem{Label("Ask AI",systemImage:"sparkles")}
  NavigationStack { RuleSearchView() }.tabItem{Label("Rules",systemImage:"book")}
  NavigationStack { SettingsView() }.tabItem{Label("Setup",systemImage:"slider.horizontal.3")}
 }}
}
struct SettingsView:View {
 @EnvironmentObject var store:RuleStore
 var body:some View { Form {
  Picker("Organization",selection:$store.context.organization){ForEach(Organization.allCases){Text($0.rawValue).tag($0)}}
  Picker("Sport",selection:$store.context.sport){ForEach(store.availableSports){Text($0.rawValue).tag($0)}}
  Picker("Division / Age",selection:$store.context.division){ForEach(store.availableDivisions){Text($0.rawValue).tag($0)}}
  Picker("Game",selection:$store.context.gameType){ForEach(GameType.allCases){Text($0.rawValue).tag($0)}}
  Section("Rules Source"){Text(store.context.organization == .usssa ? "USSSA rules remain separate from Little League rules." : "Little League rules remain separate from USSSA rules.").font(.caption).foregroundStyle(.secondary)}
  Section("Disclaimer"){Text("Diamond Rules is an independent rules-reference tool. It is not affiliated with, endorsed by, sponsored by, or an official application of Little League, USSSA, or any other governing organization whose rules are referenced or interpreted. Official rules and rulings from the applicable governing organization remain controlling.").font(.caption).foregroundStyle(.secondary)}
 }.navigationTitle("Game Setup").onChange(of:store.context.organization){_,_ in store.normalizeContext()}.onChange(of:store.context.sport){_,_ in store.normalizeContext()} }
}