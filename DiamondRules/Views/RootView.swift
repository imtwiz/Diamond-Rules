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
  Picker("Program",selection:$store.context.sport){ForEach(Sport.allCases){Text($0.rawValue).tag($0)}}
  Picker("Division",selection:$store.context.division){ForEach(Division.allCases){Text($0.rawValue).tag($0)}}
  Picker("Game",selection:$store.context.gameType){ForEach(GameType.allCases){Text($0.rawValue).tag($0)}}
 }.navigationTitle("Game Setup") }
}