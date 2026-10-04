import SwiftUI

struct RootView:View {
 @EnvironmentObject var store:RuleStore
 @AppStorage("didCompleteSetup") private var didCompleteSetup=false
 @State private var tab=0
 var body:some View {
  TabView(selection:$tab){
   NavigationStack{HomeView(tab:$tab)}.tabItem{Label("Home",systemImage:"house.fill")}.tag(0)
   NavigationStack{RuleSearchView()}.tabItem{Label("Search",systemImage:"magnifyingglass")}.tag(1)
   NavigationStack{AskView()}.tabItem{Label("Ask AI",systemImage:"mic.circle.fill")}.tag(2)
   NavigationStack{FavoritesView()}.tabItem{Label("Favorites",systemImage:"star.fill")}.tag(3)
   NavigationStack{MoreView()}.tabItem{Label("More",systemImage:"ellipsis.circle")}.tag(4)
  }.fullScreenCover(isPresented:Binding(get:{!didCompleteSetup},set:{if !$0{didCompleteSetup=true}})){SetupWizardView{didCompleteSetup=true}}
 }
}

struct HomeView:View {
 @EnvironmentObject var store:RuleStore; @Binding var tab:Int
 let quick=["Interference","Obstruction","Dropped Third Strike","Infield Fly","Pitch Count","Batting Out of Order"]
 var body:some View { ScrollView{VStack(alignment:.leading,spacing:18){
  VStack(alignment:.leading,spacing:3){Text("Diamond Rules").font(.largeTitle).bold();Text("Fast answers. Exact context. Game ready.").foregroundStyle(.secondary)}
  VStack(alignment:.leading,spacing:7){HStack{Label("Current Game",systemImage:"baseball.diamond.bases").font(.headline);Spacer();NavigationLink("Change"){SettingsView()}.font(.caption.bold())};Text("\(store.context.organization.rawValue) • \(store.context.sport.rawValue)").bold();Text("\(store.context.division.rawValue) • \(store.context.gameType.rawValue) • \(store.context.ruleMode.rawValue)").font(.subheadline).foregroundStyle(.secondary)}.padding().background(.blue.opacity(.09),in:RoundedRectangle(cornerRadius:18))
  HStack(spacing:12){Button{tab=1}label:{ActionTile(title:"Search Rules",icon:"magnifyingglass")};Button{tab=2}label:{ActionTile(title:"Ask AI",icon:"mic.fill")}}
  Text("Quick Game-Day Questions").font(.headline)
  LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:10){ForEach(quick,id:\.self){q in NavigationLink{RuleSearchView(initialQuery:q)}label:{Text(q).font(.subheadline.bold()).frame(maxWidth:.infinity,minHeight:48).background(.thinMaterial,in:RoundedRectangle(cornerRadius:12))}}}
  HStack{Label("\(store.scopedRules.count) matching rules",systemImage:"checkmark.seal");Spacer();Text("2026").bold()}.font(.caption).foregroundStyle(.secondary).padding(.top,4)
  Text("Diamond Rules is an independent reference tool. Official governing-organization rules and authorized officials remain controlling.").font(.caption2).foregroundStyle(.secondary)
 }.padding()}}.navigationBarTitleDisplayMode(.inline)
}

struct ActionTile:View { let title:String;let icon:String;var body:some View{VStack(spacing:10){Image(systemName:icon).font(.title);Text(title).bold()}.frame(maxWidth:.infinity,minHeight:100).background(.blue.opacity(.1),in:RoundedRectangle(cornerRadius:18))}}

struct MoreView:View {
 var body:some View { List {
  Section("Game"){NavigationLink{SettingsView()}{Label("Change Setup",systemImage:"slider.horizontal.3")};NavigationLink{RecentQuestionsView()}{Label("Recent Questions",systemImage:"clock")}}
  Section("Reference"){NavigationLink{QuickGuidesView()}{Label("Quick Guides",systemImage:"bolt.fill")};NavigationLink{RuleBooksView()}{Label("Rule Books & Sources",systemImage:"books.vertical")}}
  Section("App"){NavigationLink{LegalView()}{Label("About & Legal",systemImage:"info.circle")}}
 }.navigationTitle("More") }
}

struct SettingsView:View {
 @EnvironmentObject var store:RuleStore
 var body:some View { Form {
  Section("Governing Organization"){Picker("Organization",selection:$store.context.organization){ForEach(Organization.allCases){Text($0.rawValue).tag($0)}}}
  Section("Sport"){Picker("Sport",selection:$store.context.sport){ForEach(store.availableSports){Text($0.rawValue).tag($0)}}}
  Section("Division / Age"){Picker("Division",selection:$store.context.division){ForEach(store.availableDivisions){Text($0.rawValue).tag($0)}}}
  Section("Season Type"){Picker("Season",selection:$store.context.gameType){ForEach(GameType.allCases){Text($0.rawValue).tag($0)}}}
  Section("Rule Context"){Picker("Context",selection:$store.context.ruleMode){ForEach(RuleMode.allCases){Text($0.rawValue).tag($0)}}}
 }.navigationTitle("Game Setup").onChange(of:store.context.organization){_,_ in store.normalizeContext()}.onChange(of:store.context.sport){_,_ in store.normalizeContext()} }
}

struct SetupWizardView:View {
 @EnvironmentObject var store:RuleStore; @Environment(\.dismiss) private var dismiss; let done:()->Void
 var body:some View { NavigationStack{Form{
  Section{VStack(alignment:.leading,spacing:6){Text("Welcome to Diamond Rules").font(.title).bold();Text("Set the game context once. Every search and AI answer will stay inside this ruleset.").foregroundStyle(.secondary)}}
  Section("1. Governing Organization"){Picker("Organization",selection:$store.context.organization){ForEach(Organization.allCases){Text($0.rawValue).tag($0)}}}
  Section("2. Sport"){Picker("Sport",selection:$store.context.sport){ForEach(store.availableSports){Text($0.rawValue).tag($0)}}}
  Section("3. Division / Age"){Picker("Division",selection:$store.context.division){ForEach(store.availableDivisions){Text($0.rawValue).tag($0)}}}
  Section("4. Season Type"){Picker("Season",selection:$store.context.gameType){ForEach(GameType.allCases){Text($0.rawValue).tag($0)}}}
  Section("5. Rule Context"){Picker("Context",selection:$store.context.ruleMode){ForEach(RuleMode.allCases){Text($0.rawValue).tag($0)}}}
  Section{Button("Start Using Diamond Rules"){done();dismiss()}.buttonStyle(.borderedProminent).frame(maxWidth:.infinity)}
  Section{Text("Independent rules-reference tool. Not affiliated with or endorsed by any governing organization.").font(.caption).foregroundStyle(.secondary)}
 }.navigationTitle("Game Setup").onChange(of:store.context.organization){_,_ in store.normalizeContext()}.onChange(of:store.context.sport){_,_ in store.normalizeContext()}}}
}

struct QuickGuidesView:View {
 let topics=["Interference","Obstruction","Appeals","Batting Out of Order","Dropped Third Strike","Infield Fly","Pitch Count","Courtesy Runner","Mandatory Play","Equipment"]
 var body:some View{List(topics,id:\.self){t in NavigationLink{RuleSearchView(initialQuery:t)}label:{Label(t,systemImage:"bolt")}}.navigationTitle("Quick Guides")}
}
struct RuleBooksView:View {
 @EnvironmentObject var store:RuleStore
 var body:some View{List{Section("Loaded Reference"){Text("\(store.rules.count) verified/reference records bundled for offline search.");Text("Full official text is shown only where authorized and stored.")};Section("Current Ruleset"){Text(store.context.organization.rawValue);Text(store.context.sport.rawValue)}}.navigationTitle("Rule Books & Sources")}
}
struct LegalView:View {
 var body:some View{List{Section("Diamond Rules"){Text("An independent educational rules-reference application designed for fast baseball and softball game-day lookup.")};Section("Disclaimer"){Text("Diamond Rules is not affiliated with, endorsed by, sponsored by, or an official application of Little League, USSSA, Babe Ruth League, Cal Ripken Baseball, PONY, NFHS, NCAA, MLB, Perfect Game, or any other governing organization whose rules are referenced or interpreted. Official rules and rulings from the applicable governing organization remain controlling.")};Section("AI"){Text("AI responses are grounded in matching verified rule records when available. When the database does not adequately support a ruling, official verification is required.")}}.navigationTitle("About & Legal")}
}