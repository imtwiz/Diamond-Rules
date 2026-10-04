import SwiftUI
import Speech
import AVFoundation

struct AskView:View {
 @EnvironmentObject var store:RuleStore
 @StateObject private var speech=SpeechRecognizer()
 @State private var question=""
 @State private var answer:AIAnswer?
 @State private var busy=false
 @State private var error:String?
 @State private var speakMode=true

 var body:some View {
  ScrollView {
   VStack(spacing:18) {
    Picker("Input",selection:$speakMode){Text("Speak").tag(true);Text("Type").tag(false)}.pickerStyle(.segmented)
    contextCard
    if speakMode {
     VStack(spacing:14) {
      Image(systemName:speech.isRecording ? "waveform.circle.fill":"mic.circle.fill").font(.system(size:84)).foregroundStyle(.blue)
      Text(speech.isRecording ? "Listening…" : "Tap to start speaking").font(.title3).bold()
      Button(speech.isRecording ? "Stop Listening":"Speak Question"){Task{await toggleSpeech()}}.buttonStyle(.borderedProminent).controlSize(.large)
     }.frame(maxWidth:.infinity).padding(.vertical,10)
    }
    TextField("Ask any baseball or softball rules question…",text:$question,axis:.vertical).textFieldStyle(.roundedBorder).lineLimit(3...7)
    Button(busy ? "Checking…" : "Get Ruling"){Task{await ask()}}.buttonStyle(.borderedProminent).controlSize(.large).frame(maxWidth:.infinity).disabled(question.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty||busy)
    if let a=answer { answerCard(a) }
    if let error { Text(error).foregroundStyle(.red).frame(maxWidth:.infinity,alignment:.leading) }
    Text("Diamond Rules is independent and is not affiliated with, endorsed by, sponsored by, or an official application of any governing organization whose rules are referenced or interpreted. Official rules and authorized officials remain controlling.").font(.caption).foregroundStyle(.secondary).padding(.top)
   }.padding()
  }.navigationTitle("Ask AI").onChange(of:speech.transcript){_,v in if !v.isEmpty{question=v}}
 }
 private var contextCard:some View { VStack(alignment:.leading,spacing:5){Text("CURRENT SELECTION").font(.caption2).bold().foregroundStyle(.secondary);Text("\(store.context.organization.rawValue)  |  \(store.context.sport.rawValue)  |  \(store.context.division.rawValue)").bold();Text("\(store.context.gameType.rawValue)  |  \(store.context.ruleMode.rawValue)").font(.caption)}.frame(maxWidth:.infinity,alignment:.leading).padding().background(.blue.opacity(0.08),in:RoundedRectangle(cornerRadius:14)) }
 @ViewBuilder private func answerCard(_ a:AIAnswer)->some View { VStack(alignment:.leading,spacing:10){Text(a.ruling).font(.title2).bold();Text(a.explanation);if !a.ruleNumbers.isEmpty{Label("Rule "+a.ruleNumbers.joined(separator:", "),systemImage:"book.closed").bold()};Text("Confidence: "+a.confidence).font(.caption);if a.requiresOfficialVerification{Label("Official rule verification required.",systemImage:"exclamationmark.triangle.fill").foregroundStyle(.orange)}}.frame(maxWidth:.infinity,alignment:.leading).padding().background(.thinMaterial,in:RoundedRectangle(cornerRadius:16)) }
 private func toggleSpeech() async { if speech.isRecording { speech.stop(); return }; do { try await speech.start() } catch { self.error=error.localizedDescription } }
 private func ask() async { speech.stop();store.addRecentQuestion(question);busy=true;defer{busy=false};do{answer=try await AIService().ask(question:question,context:store.context,candidates:Array(store.search(question).prefix(8)));error=nil}catch{self.error="Could not reach the rules service.";answer=nil}}
}

@MainActor final class SpeechRecognizer:NSObject,ObservableObject {
 @Published var transcript=""; @Published var isRecording=false
 private let recognizer=SFSpeechRecognizer(locale:Locale(identifier:"en-US"))
 private let engine=AVAudioEngine(); private var request:SFSpeechAudioBufferRecognitionRequest?; private var task:SFSpeechRecognitionTask?
 func start() async throws {
  let speechOK=await withCheckedContinuation{c in SFSpeechRecognizer.requestAuthorization{c.resume(returning:$0 == .authorized)}}
  guard speechOK else { throw NSError(domain:"DiamondRules",code:1,userInfo:[NSLocalizedDescriptionKey:"Speech recognition permission is required."]) }
  let micOK=await AVAudioApplication.requestRecordPermission()
  guard micOK else { throw NSError(domain:"DiamondRules",code:2,userInfo:[NSLocalizedDescriptionKey:"Microphone permission is required."]) }
  stop(); transcript=""
  let req=SFSpeechAudioBufferRecognitionRequest(); req.shouldReportPartialResults=true; request=req
  let node=engine.inputNode; let format=node.outputFormat(forBus:0); node.installTap(onBus:0,bufferSize:1024,format:format){buffer,_ in req.append(buffer)}
  engine.prepare();try engine.start();isRecording=true
  task=recognizer?.recognitionTask(with:req){[weak self] result,error in Task{@MainActor in guard let self else{return};if let result{self.transcript=result.bestTranscription.formattedString;if result.isFinal{self.stop()}};if error != nil{self.stop()}}}
 }
 func stop(){ if engine.isRunning{engine.stop()};engine.inputNode.removeTap(onBus:0);request?.endAudio();task?.cancel();request=nil;task=nil;isRecording=false }
}