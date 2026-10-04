import Foundation
@MainActor final class RuleStore:ObservableObject {
 @Published var context:GameContext { didSet { saveContext() } }
 @Published var rules:[RuleRecord]=[]
 @Published private(set) var favoriteIDs:Set<String>=[]
 @Published private(set) var recentQuestions:[String]=[]
 private let defaults=UserDefaults.standard
 init(){
  if let d=defaults.data(forKey:"gameContext"),let saved=try? JSONDecoder().decode(GameContext.self,from:d){context=saved}else{context=GameContext()}
  favoriteIDs=Set(defaults.stringArray(forKey:"favoriteRuleIDs") ?? [])
  recentQuestions=defaults.stringArray(forKey:"recentQuestions") ?? []
  load()
 }
 var availableSports:[Sport] {
  switch context.organization {
   case .littleLeague:return [.baseball,.softball,.challenger]
   case .usssa,.babeRuth,.pony,.nfhs,.ncaa:return [.baseball,.softball]
   case .calRipken,.mlb,.perfectGame:return [.baseball]
  }
 }
 var availableDivisions:[Division] {
  if [.usssa,.perfectGame].contains(context.organization){return [.u5,.u6,.u7,.u8,.u9,.u10,.u11,.u12,.u13,.u14,.u15,.u16,.u17,.u18]}
  if context.organization == .calRipken{return [.teeBall,.minor,.major]}
  if context.organization == .babeRuth{return [.u13,.u14,.u15,.u16,.u17,.u18]}
  if context.organization == .pony{return [.u5,.u6,.u7,.u8,.u9,.u10,.u11,.u12,.u13,.u14,.u15,.u16,.u17,.u18]}
  if [.nfhs,.ncaa,.mlb].contains(context.organization){return [.senior]}
  switch context.sport{case .challenger:return [.challenger,.seniorChallenger];case .baseball:return [.teeBall,.minor,.major,.intermediate,.junior,.senior];case .softball:return [.teeBall,.minor,.major,.junior,.senior]}
 }
 func normalizeContext(){if !availableSports.contains(context.sport){context.sport=availableSports[0]};if !availableDivisions.contains(context.division){context.division=availableDivisions[0]}}
 var scopedRules:[RuleRecord]{rules.filter{$0.organization==context.organization && $0.season==context.season && $0.sport==context.sport && $0.divisions.contains(context.division) && $0.gameTypes.contains(context.gameType)}}
 func search(_ q:String)->[RuleRecord]{let s=q.lowercased();return scopedRules.sorted{score($0,s)>score($1,s)}.filter{score($0,s)>0}}
 private func score(_ r:RuleRecord,_ s:String)->Int{var n=0;if r.ruleNumber.lowercased().contains(s){n+=8};if r.topic.lowercased().contains(s){n+=6};if r.ruling.lowercased().contains(s){n+=4};if r.summary.lowercased().contains(s){n+=3};if r.keywords.contains(where:{$0.lowercased().contains(s)}){n+=5};return n}
 func isFavorite(_ r:RuleRecord)->Bool{favoriteIDs.contains(r.id)}
 func toggleFavorite(_ r:RuleRecord){if favoriteIDs.contains(r.id){favoriteIDs.remove(r.id)}else{favoriteIDs.insert(r.id)};defaults.set(Array(favoriteIDs),forKey:"favoriteRuleIDs")}
 var favoriteRules:[RuleRecord]{rules.filter{favoriteIDs.contains($0.id)}}
 func addRecentQuestion(_ q:String){let t=q.trimmingCharacters(in:.whitespacesAndNewlines);guard !t.isEmpty else{return};recentQuestions.removeAll{$0.caseInsensitiveCompare(t)==.orderedSame};recentQuestions.insert(t,at:0);recentQuestions=Array(recentQuestions.prefix(20));defaults.set(recentQuestions,forKey:"recentQuestions")}
 private func saveContext(){if let d=try? JSONEncoder().encode(context){defaults.set(d,forKey:"gameContext")}}
 private func load(){guard let u=Bundle.main.url(forResource:"rules_2026",withExtension:"json"),let d=try? Data(contentsOf:u),let x=try? JSONDecoder().decode([RuleRecord].self,from:d)else{return};rules=x}
}