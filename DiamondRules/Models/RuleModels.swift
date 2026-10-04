import Foundation

enum Organization:String,Codable,CaseIterable,Identifiable {
 case littleLeague="Little League", usssa="USSSA", babeRuth="Babe Ruth League", calRipken="Cal Ripken Baseball", pony="PONY Baseball & Softball", nfhs="NFHS", ncaa="NCAA", mlb="MLB", perfectGame="Perfect Game"
 var id:String{rawValue}
}
enum Sport:String,Codable,CaseIterable,Identifiable { case baseball="Baseball",softball="Softball",challenger="Challenger"; var id:String{rawValue} }
enum Division:String,Codable,CaseIterable,Identifiable {
 case teeBall="Tee Ball",minor="Minor",major="Major",intermediate="Intermediate (50/70)",junior="Junior",senior="Senior",challenger="Challenger",seniorChallenger="Senior Challenger"
 case u5="5U",u6="6U",u7="7U",u8="8U",u9="9U",u10="10U",u11="11U",u12="12U",u13="13U",u14="14U",u15="15U",u16="16U",u17="17U",u18="18U"
 var id:String{rawValue}
}
enum GameType:String,Codable,CaseIterable,Identifiable { case regular="Regular Season",tournament="Tournament"; var id:String{rawValue} }\nenum RuleMode:String,Codable,CaseIterable,Identifiable { case gameTime="Game-Time Rules",nonGameTime="Non-Game-Time Rules"; var id:String{rawValue} }

struct GameContext:Codable {
 var organization:Organization = .littleLeague
 var sport:Sport = .baseball
 var division:Division = .major
 var season:Int = 2026
 var gameType:GameType = .regular
 var ruleMode:RuleMode = .gameTime
}

struct RuleRecord:Codable,Identifiable {
 let id:String
 let organization:Organization
 let sport:Sport
 let divisions:[Division]
 let season:Int
 let gameTypes:[GameType]
 let ruleNumber:String
 let topic:String
 let summary:String
 let ruling:String
 let exceptions:[String]
 let keywords:[String]
 let relatedRules:[String]
 let officialSource:String
 let verified:Bool
 let officialText:String?
 let sourceLabel:String?
 let reviewedOn:String?
}
struct AIAnswer:Codable { let ruling:String; let explanation:String; let ruleNumbers:[String]; let exceptions:[String]; let confidence:String; let requiresOfficialVerification:Bool }
