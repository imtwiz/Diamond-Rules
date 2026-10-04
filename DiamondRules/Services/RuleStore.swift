import Foundation
@MainActor final class RuleStore:ObservableObject {
 @Published var context=GameContext(); @Published var rules:[RuleRecord]=[]
 init(){ load() }

 var availableSports:[Sport] {
  switch context.organization {
   case .littleLeague: return [.baseball,.softball,.challenger]
   case .usssa,.babeRuth,.pony,.nfhs,.ncaa: return [.baseball,.softball]
   case .calRipken,.mlb,.perfectGame: return [.baseball]
  }
 }
 var availableDivisions:[Division] {
  if [.usssa,.perfectGame].contains(context.organization) { return [.u5,.u6,.u7,.u8,.u9,.u10,.u11,.u12,.u13,.u14,.u15,.u16,.u17,.u18] }
  if context.organization == .calRipken { return [.teeBall,.minor,.major] }
  if context.organization == .babeRuth { return [.u13,.u14,.u15,.u16,.u17,.u18] }
  if context.organization == .pony { return [.u5,.u6,.u7,.u8,.u9,.u10,.u11,.u12,.u13,.u14,.u15,.u16,.u17,.u18] }
  if [.nfhs,.ncaa,.mlb].contains(context.organization) { return [.senior] }
  switch context.sport {
   case .challenger: return [.challenger,.seniorChallenger]
   case .baseball: return [.teeBall,.minor,.major,.intermediate,.junior,.senior]
   case .softball: return [.teeBall,.minor,.major,.junior,.senior]
  }
 }
 func normalizeContext(){ if !availableSports.contains(context.sport){context.sport=availableSports[0]}; if !availableDivisions.contains(context.division){context.division=availableDivisions[0]} }

 var scopedRules:[RuleRecord]{ rules.filter{$0.organization==context.organization && $0.season==context.season && $0.sport==context.sport && $0.divisions.contains(context.division) && $0.gameTypes.contains(context.gameType)} }
 func search(_ q:String)->[RuleRecord]{ let s=q.lowercased(); return scopedRules.filter{ $0.ruleNumber.lowercased().contains(s)||$0.topic.lowercased().contains(s)||$0.summary.lowercased().contains(s)||$0.keywords.joined(separator:" ").lowercased().contains(s)} }
 private func load(){ guard let u=Bundle.main.url(forResource:"rules_2026",withExtension:"json"),let d=try? Data(contentsOf:u),let x=try? JSONDecoder().decode([RuleRecord].self,from:d) else{return}; rules=x }
}