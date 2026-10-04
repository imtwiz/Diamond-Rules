import Foundation
enum AppConfig { static let apiBaseURL=URL(string:"https://diamond-rules.onrender.com")! }
final class AIService {
 struct Request:Codable { let question:String; let context:GameContext; let candidateRules:[RuleRecord]; let conversation:[ConversationItem] }
 struct ConversationItem:Codable { let role:String; let text:String }
 func ask(question:String,context:GameContext,candidates:[RuleRecord],conversation:[ConversationItem]=[]) async throws -> AIAnswer {
  var r=URLRequest(url:AppConfig.apiBaseURL.appending(path:"ask")); r.httpMethod="POST"; r.setValue("application/json",forHTTPHeaderField:"Content-Type"); r.httpBody=try JSONEncoder().encode(Request(question:question,context:context,candidateRules:candidates,conversation:conversation))
  let (d,res)=try await URLSession.shared.data(for:r); guard let h=res as? HTTPURLResponse,(200..<300).contains(h.statusCode) else { throw URLError(.badServerResponse) }; return try JSONDecoder().decode(AIAnswer.self,from:d)
 }
}