import SwiftUI
struct RootView:View {
 @EnvironmentObject var store:RuleStore
 var body:some View { TabView {
  NavigationStack { HomeView() }.tabItem{Label("Home",systemImage:"house.fill")}
  NavigationStack { RuleSearchView() }.tabItem{Label("Search",systemImage:"magnifyingglass")}
  NavigationStack { AskView() }.tabItem{Label("Ask AI",systemImage:"mic.circle.fill")}
  NavigationStack { MoreView() }.tabItem{Label("More",systemImage:"ellipsis.circle")}
 }}
}
struct HomeView:View {
 @EnvironmentObject var store:RuleStore
 var body:some View { ScrollView{VStack(alignment:.leading,spacing:18){
  Text("Diamond Rules").font(.largeTitle).bold()
  Text("Your Baseball & Softball Rules Companion").foregroundStyle(.secondary)
  VStack(alignment:.leading,spacing:6){Text("CURRENT SELECTION").font(.caption2).bold().foregroundStyle(.secondary);Text("\(store.context.organization.rawValue) • \(store.context.sport.rawValue) • \(store.context.division.rawValue)").bold();Text("\(store.context.gameType.rawValue) • \(store.context.ruleMode.rawValue)").font(.caption)}.padding().frame(maxWidth:.infinity,alignment:.leading).background(.blue.opacity(.08),in:RoundedRectangle(cornerRadius:16))
  Text("Game-Day Tools").font(.headline)
  NavigationLink{RuleSearchView()}{Label("Search Rules",systemImage:"magnifyingglass").frame(maxWidth:.infinity,alignment:.leading).padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:14))}
  NavigationLink{AskView()}{Label("Speak or Type Ask AI",systemImage:"mic.fill").frame(maxWidth:.infinity,alignment:.leading).padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:14))}
  HStack{NavigationLink{FavoritesView()}{Label("Favorites",systemImage:"star.fill")};Spacer();NavigationLink{RecentQuestionsView()}{Label("Recent",systemImage:"clock.fill")}}.padding()
 }.padding()}}.navigationBarTitleDisplayMode(.inline)
}
struct MoreView:View {
 var body:some View { List {
  NavigationLink{SettingsView()}{Label("Change Setup",systemImage:"slider.horizontal.3")}
  NavigationLink{FavoritesView()}{Label("Favorites",systemImage:"star")}
  NavigationLink{RecentQuestionsView()}{Label("Recent Questions",systemImage:"clock")}
 }.navigationTitle("More") }
}
struct SettingsView:View {
 @EnvironmentObject var store:RuleStore
 var body:some View { Form {
  Section("1. Governing Organization"){Picker("Organization",selection:$store.context.organization){ForEach(Organization.allCases){Text($0.rawValue).tag($0)}}}
  Section("2. Sport"){Picker("Sport",selection:$store.context.sport){ForEach(store.availableSports){Text($0.rawValue).tag($0)}}}
  Section("3. Division / Age"){Picker("Division",selection:$store.context.division){ForEach(store.availableDivisions){Text($0.rawValue).tag($0)}}}
  Section("4. Season Type"){Picker("Season",selection:$store.context.gameType){ForEach(GameType.allCases){Text($0.rawValue).tag($0)}}}
  Section("5. Rule Context"){Picker("Context",selection:$store.context.ruleMode){ForEach(RuleMode.allCases){Text($0.rawValue).tag($0)}}}
  Section("Important Disclaimer"){Text("Diamond Rules is an independent rules-reference tool. It is not affiliated with, endorsed by, sponsored by, or an official application of any governing organization whose rules are referenced or interpreted. Official rules and rulings from the applicable governing organization remain controlling.").font(.caption)}
 }.navigationTitle("Setup").onChange(of:store.context.organization){_,_ in store.normalizeContext()}.onChange(of:store.context.sport){_,_ in store.normalizeContext()} }
}