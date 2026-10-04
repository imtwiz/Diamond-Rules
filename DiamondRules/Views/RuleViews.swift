import SwiftUI
struct RuleSearchView:View {
 @EnvironmentObject var store:RuleStore; @State private var q=""
 let quick=["Dropped Third Strike","Infield Fly","Mercy Rule","Pitch Count","Time Limit","Balk","Obstruction","Runner Interference","Bat Rules","Equipment"]
 var body:some View { List {
  if q.isEmpty { Section("Quick Searches"){ForEach(quick,id:\.self){term in Button(term){q=term}}} }
  Section(q.isEmpty ? "Rules":"Results"){ForEach(q.isEmpty ? store.scopedRules:store.search(q)){r in NavigationLink{RuleDetailView(rule:r)}label:{VStack(alignment:.leading,spacing:4){HStack{Text("Rule "+r.ruleNumber).bold();if store.isFavorite(r){Image(systemName:"star.fill").foregroundStyle(.yellow)}};Text(r.topic);Text(r.summary).font(.caption).foregroundStyle(.secondary)}}}}
 }.searchable(text:$q,prompt:"Situation, keyword, or rule number").navigationTitle("Search Rules") }
}
struct RuleDetailView:View {
 @EnvironmentObject var store:RuleStore; let rule:RuleRecord
 var body:some View { List {
  Section{VStack(alignment:.leading,spacing:5){Text(rule.organization.rawValue+" "+rule.sport.rawValue).font(.headline);Text(rule.divisions.map{$0.rawValue}.joined(separator:", ")+" • "+rule.gameTypes.map{$0.rawValue}.joined(separator:", ")).font(.caption).foregroundStyle(.secondary)}}
  Section("Ruling"){Text(rule.ruling).font(.title3).bold()}
  Section("Summary"){Text(rule.summary)}
  if let t=rule.officialText,!t.isEmpty{Section("Official Rule Text"){Text(t)}}
  if !rule.exceptions.isEmpty{Section("Exceptions / Notes"){ForEach(rule.exceptions,id:\.self){Text($0)}}}
  if !rule.relatedRules.isEmpty{Section("Related Rules"){ForEach(rule.relatedRules,id:\.self){Text($0)}}}
  Section("Verification"){Label(rule.verified ? "Verified record":"Official verification required",systemImage:rule.verified ? "checkmark.seal.fill":"exclamationmark.triangle.fill");if let s=rule.sourceLabel{Text(s).font(.caption)};if let d=rule.reviewedOn{Text("Reviewed: "+d).font(.caption).foregroundStyle(.secondary)}}
  if let u=URL(string:rule.officialSource){Section{Link("Open Official Source",destination:u)}}
 }.navigationTitle("Rule "+rule.ruleNumber).toolbar{Button{store.toggleFavorite(rule)}label:{Image(systemName:store.isFavorite(rule) ? "star.fill":"star")}} }
}
struct FavoritesView:View {
 @EnvironmentObject var store:RuleStore
 var body:some View { List(store.favoriteRules){r in NavigationLink{RuleDetailView(rule:r)}label:{VStack(alignment:.leading){Text("Rule "+r.ruleNumber).bold();Text(r.topic)}}}.navigationTitle("Favorites").overlay{if store.favoriteRules.isEmpty{ContentUnavailableView("No Favorites",systemImage:"star",description:Text("Save rules for quick game-day access."))}} }
}
struct RecentQuestionsView:View {
 @EnvironmentObject var store:RuleStore
 var body:some View { List(store.recentQuestions,id:\.self){Text($0)}.navigationTitle("Recent Questions").overlay{if store.recentQuestions.isEmpty{ContentUnavailableView("No Recent Questions",systemImage:"clock",description:Text("Questions you ask AI will appear here."))}} }
}