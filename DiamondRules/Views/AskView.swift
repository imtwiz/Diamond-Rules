import SwiftUI
struct AskView:View {
 @EnvironmentObject var store:RuleStore; @State private var question=""; @State private var answer:AIAnswer?; @State private var busy=false; @State private var error:String?
 var body:some View { Form {
  Section("Situation"){TextField("What happened?",text:$question,axis:.vertical); Button(busy ? "Checking…" : "Get Ruling"){Task{await ask()}}.disabled(question.isEmpty||busy)}
  if let a=answer { Section("Ruling"){Text(a.ruling).font(.title2).bold();Text(a.explanation); if !a.ruleNumbers.isEmpty{Text("Rule: "+a.ruleNumbers.joined(separator:", ")).bold()}; Text("Confidence: "+a.confidence); if a.requiresOfficialVerification{Text("Official rule verification required.").foregroundStyle(.orange)}}}
  if let error{Section{Text(error).foregroundStyle(.red)}}
 }.navigationTitle("Diamond Rules") }
 func ask() async { busy=true;defer{busy=false}; do { answer=try await AIService().ask(question:question,context:store.context,candidates:Array(store.search(question).prefix(8)));error=nil } catch { self.error="Could not reach the rules service.";answer=nil } }
}