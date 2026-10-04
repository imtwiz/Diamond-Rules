import Foundation
@MainActor final class RuleStore:ObservableObject {
 @Published var context=GameContext(); @Published var rules:[RuleRecord]=[]
 init(){ load() }
 var scopedRules:[RuleRecord]{ rules.filter{$0.season==context.season && $0.sport==context.sport && $0.divisions.contains(context.division) && $0.gameTypes.contains(context.gameType)} }
 func search(_ q:String)->[RuleRecord]{ let s=q.lowercased(); return scopedRules.filter{ $0.ruleNumber.lowercased().contains(s)||$0.topic.lowercased().contains(s)||$0.summary.lowercased().contains(s)||$0.keywords.joined(separator:" ").lowercased().contains(s)} }
 private func load(){ guard let u=Bundle.main.url(forResource:"rules_2026",withExtension:"json"),let d=try? Data(contentsOf:u),let x=try? JSONDecoder().decode([RuleRecord].self,from:d) else{return}; rules=x }
}