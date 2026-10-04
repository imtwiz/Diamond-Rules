import SwiftUI
struct RuleSearchView:View {
 @EnvironmentObject var store:RuleStore; @State private var q=""
 var body:some View { List(q.isEmpty ? store.scopedRules:store.search(q)){r in NavigationLink{RuleDetailView(rule:r)}label:{VStack(alignment:.leading){Text("Rule "+r.ruleNumber).bold();Text(r.topic);Text(r.summary).font(.caption).foregroundStyle(.secondary)}}}.searchable(text:$q).navigationTitle("Rule Search") }
}
struct RuleDetailView:View { let rule:RuleRecord; var body:some View { List { Section("Ruling"){Text(rule.ruling)};Section("Summary"){Text(rule.summary)};if let t=rule.officialText,!t.isEmpty{Section("Official Text"){Text(t)}};if !rule.exceptions.isEmpty{Section("Exceptions"){ForEach(rule.exceptions,id:\.self){Text($0)}}};if let u=URL(string:rule.officialSource){Section{Link("Official Source",destination:u)}} }.navigationTitle("Rule "+rule.ruleNumber) } }