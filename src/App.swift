import Cocoa
import Translation
import ApplicationServices

@MainActor final class ReaderApp: NSObject, NSApplicationDelegate, NSWindowDelegate, NSSoundDelegate, NSTextViewDelegate {
 let window = NSPanel(contentRect: NSRect(x:0,y:0,width:570,height:430), styleMask:[.titled,.closable,.resizable], backing:.buffered,defer:false)
 let input=NSTextView(), chinese=NSTextView(), status=NSTextField(labelWithString:"选中英文后从“服务”菜单触发，也可粘贴英文到上方。")
 var state=ReaderState()
 var process:Process?, sound:NSSound?, translationTask:Task<Void,Never>?, timer:Timer?
 var translationTimer:Timer?
 var temp:URL?, errorText:String?, speechSoundID:UUID?
 var captureTask:Task<Void,Never>?
 var globalHotKey:GlobalReadHotKey?
 var voiceBackend:Process?
 let resultPanel=ReadingResult()
 var backgroundMode=false
 var requestedText=""
 var statusItem:NSStatusItem?
 var python:String { (try? VoiceConfiguration.load().python) ?? "" }
 func applicationDidFinishLaunching(_ notification: Notification) {
  NSApp.setActivationPolicy(.regular)
  let main=NSMenu(), appItem=NSMenuItem(); main.addItem(appItem)
  let appMenu=NSMenu(); appItem.submenu=appMenu
  appMenu.addItem(withTitle:"退出英文阅读器",action:#selector(NSApplication.terminate(_:)),keyEquivalent:"q")
  appMenu.addItem(withTitle:"打开阅读器设置",action:#selector(openSettings),keyEquivalent:"")
  appMenu.addItem(withTitle:"设置选区读取权限…",action:#selector(requestSelectionPermission),keyEquivalent:"")
  let editItem=NSMenuItem(); main.addItem(editItem); let editMenu=NSMenu(title:"编辑"); editItem.submenu=editMenu
  editMenu.addItem(withTitle:"拷贝",action:#selector(NSText.copy(_:)),keyEquivalent:"c")
  editMenu.addItem(withTitle:"粘贴",action:#selector(NSText.paste(_:)),keyEquivalent:"v")
  editMenu.addItem(withTitle:"全选",action:#selector(NSText.selectAll(_:)),keyEquivalent:"a")
  NSApp.mainMenu=main; NSApp.servicesProvider=self
  window.title="Local English Reader"; window.level = .floating; window.delegate=self
  window.minSize=NSSize(width:570,height:400); window.isReleasedWhenClosed=false
  let v=window.contentView!
  let title=NSTextField(labelWithString:"英文 · 用我的声音朗读")
  title.font = .systemFont(ofSize:17,weight:.semibold); title.frame=NSRect(x:20,y:375,width:500,height:25); title.autoresizingMask=[.minYMargin,.width]; v.addSubview(title)
  addText(input,frame:NSRect(x:20,y:245,width:530,height:120),editable:true,to:v)
  input.font = .systemFont(ofSize:19); input.delegate=self
  let label=NSTextField(labelWithString:"中文意思 · 朗读结束后显示")
  label.frame=NSRect(x:20,y:210,width:520,height:25); label.autoresizingMask=[.width,.minYMargin]; v.addSubview(label)
  addText(chinese,frame:NSRect(x:20,y:88,width:530,height:115),editable:false,to:v)
  chinese.font = .systemFont(ofSize:19)
  status.frame=NSRect(x:20,y:51,width:530,height:30); status.font = .systemFont(ofSize:12); status.lineBreakMode = .byWordWrapping; status.maximumNumberOfLines=2; status.autoresizingMask=[.width]; v.addSubview(status)
  for (title,x,action) in [("朗读并翻译",20,#selector(readTyped)),("停止",155,#selector(stop)),("重听英文",245,#selector(replay)),("关闭",455,#selector(closePanel))] {
   let b=NSButton(title:title,target:self,action:action); b.bezelStyle = .rounded; b.frame=NSRect(x:x,y:12,width:title=="朗读并翻译" ? 125:90,height:32); v.addSubview(b)
  }
  window.center()
  statusItem=NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
  statusItem?.button?.title="读"
  let quickMenu=NSMenu()
  for (title,action) in [("打开阅读器设置",#selector(openSettings)),("停止朗读",#selector(stop)),("重听英文",#selector(replay)),("退出",#selector(NSApplication.terminate(_:)))] {
   let item=NSMenuItem(title:title,action:action,keyEquivalent:""); item.target=action == #selector(NSApplication.terminate(_:)) ? NSApp:self; quickMenu.addItem(item)
  }
  statusItem?.menu=quickMenu
  ensureVoiceBackend()
  if CommandLine.arguments.contains("--settings") { show() }
  do { globalHotKey=try GlobalReadHotKey { [weak self] in self?.readGlobalSelection() }; status.stringValue="在其他应用选中英文，按 \(GlobalReadHotKey.label)；首次需授予阅读器辅助功能权限。" }
  catch { status.stringValue="\(GlobalReadHotKey.label) 注册失败，可能被其他程序占用；仍可使用服务菜单。" }
  if CommandLine.arguments.contains("--smoke-background") || CommandLine.arguments.contains("--smoke-dictionary") { let word=CommandLine.arguments.contains("--smoke-dictionary") ? "prompt":"Variable"; input.string=word; begin(word,background:true); print("SMOKE_EDITOR_AT_START=\(window.isVisible)"); fflush(stdout) }
 }
 func addText(_ text:NSTextView,frame:NSRect,editable:Bool,to view:NSView) {
  let scroll=NSScrollView(frame:frame); scroll.borderType = .bezelBorder; scroll.hasVerticalScroller=true; scroll.autoresizingMask=[.width,.minYMargin]
  text.frame=NSRect(origin:.zero,size:scroll.contentSize); text.minSize=NSSize(width:0,height:scroll.contentSize.height); text.maxSize=NSSize(width:CGFloat.greatestFiniteMagnitude,height:CGFloat.greatestFiniteMagnitude); text.isEditable=editable; text.isRichText=false; text.isSelectable=true; text.textContainerInset=NSSize(width:10,height:10)
  text.isVerticallyResizable=true; text.isHorizontallyResizable=false; text.autoresizingMask=[.width]; text.textContainer?.widthTracksTextView=true
  scroll.documentView=text; view.addSubview(scroll)
 }
 func ensureVoiceBackend() {
  if voiceBackend?.isRunning == true { return }
  guard let config=try? VoiceConfiguration.load(), let script=Bundle.main.url(forResource:"voice_backend",withExtension:"py") else { return }
  let backend=Process(); backend.executableURL=URL(fileURLWithPath:config.python); backend.arguments=[script.path]
  var environment=ProcessInfo.processInfo.environment; environment["HF_HUB_OFFLINE"]="1"; environment["HF_HUB_DISABLE_TELEMETRY"]="1"; environment["PYTHONDONTWRITEBYTECODE"]="1"; backend.environment=environment
  backend.standardOutput=FileHandle.nullDevice; backend.standardError=FileHandle.nullDevice
  do { try backend.run(); voiceBackend=backend } catch { voiceBackend=nil }
 }
 @objc func requestSelectionPermission() {
  let options=[kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String:true] as CFDictionary
  _=AXIsProcessTrustedWithOptions(options)
 }
 @objc func openSettings() { show() }
 func applicationShouldHandleReopen(_ sender:NSApplication,hasVisibleWindows flag:Bool)->Bool { show(); return true }
 func setStatus(_ message:String,error:Bool=false) {
  status.stringValue=message
  if error { statusItem?.button?.title="读"; if backgroundMode { resultPanel.show(english:requestedText,chinese:message) } }
 }
 func readGlobalSelection() {
  guard AXIsProcessTrusted() else { backgroundMode=true; requestedText=""; stop(); setStatus("需要辅助功能权限。请点击菜单栏“读” → 打开阅读器设置，再设置选区读取权限。",error:true); return }
  if NSWorkspace.shared.frontmostApplication?.processIdentifier == ProcessInfo.processInfo.processIdentifier { readTyped(); return }
  let target=NSWorkspace.shared.frontmostApplication
  stop(); backgroundMode=true
  status.stringValue="正在读取选区…"
  captureTask=Task { [weak self] in
   guard let self else { return }
   do {
    let text=try await SelectionCapture.currentSelectedText(target:target)
    try Task.checkCancellation()
    self.captureTask=nil;self.input.string=text;self.window.orderOut(nil);self.begin(text,background:true)
   } catch is CancellationError { return }
   catch {
    guard !Task.isCancelled else { return }
    self.captureTask=nil;self.requestedText="";self.setStatus((error as NSError).domain,error:true)
   }
  }
 }
 func show() { window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps:true) }
 @objc func readSelection(_ pasteboard:NSPasteboard,userData:String?,error:AutoreleasingUnsafeMutablePointer<NSString?>) {
  guard let text=pasteboard.string(forType:.string),!text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { stop(); error.pointee="请先选中英文。"; return }
  input.string=text; window.orderOut(nil); begin(text,background:true)
 }
 @objc func readTyped() { begin(input.string) }
 func textDidChange(_ notification:Notification) {
  guard notification.object as? NSTextView === input else { return }; stop(); status.stringValue="英文已改变，请点击朗读并翻译。"
 }
 func cancelWork() {
  captureTask?.cancel();captureTask=nil
  translationTimer?.invalidate(); translationTimer=nil
  translationTask?.cancel(); translationTask=nil; timer?.invalidate(); timer=nil
  if let process,process.isRunning { process.terminate() }; process=nil
  sound?.stop(); sound=nil; speechSoundID=nil
  if let temp { try? FileManager.default.removeItem(at:temp) }; temp=nil
 }
 @objc func stop() { cancelWork(); _=state.begin(); chinese.string=""; status.stringValue="已停止。"; statusItem?.button?.title="读"; resultPanel.hide() }
 @objc func closePanel() { stop(); window.orderOut(nil) }
 func windowShouldClose(_ sender:NSWindow)->Bool { stop(); return true }
 func applicationShouldTerminateAfterLastWindowClosed(_ sender:NSApplication)->Bool { false }
 func applicationWillTerminate(_ notification:Notification) { globalHotKey?.invalidate(); cancelWork(); if voiceBackend?.isRunning == true { voiceBackend?.terminate() } }
 @objc func replay() {
  guard let sound,!sound.isPlaying else { return }
  speechSoundID=state.id; status.stringValue="正在重听英文…"; statusItem?.button?.title="朗读…"; sound.play()
 }
 func begin(_ raw:String,background:Bool=false) {
  backgroundMode=background; requestedText=raw; resultPanel.hide()
  let text=raw.trimmingCharacters(in:.whitespacesAndNewlines)
  guard !text.isEmpty,text.count<=1500,text.range(of:"[A-Za-z]",options:.regularExpression) != nil else { stop(); status.stringValue="请选中或粘贴英文；每次不超过 1500 个字符。"; setStatus(status.stringValue,error:true); return }
  do { _=try VoiceConfiguration.load() } catch { stop(); setStatus("请先配置本机声音：参阅 README 中的 voice.json 设置步骤。",error:true); return }
  cancelWork(); ensureVoiceBackend(); let id=state.begin(); errorText=nil; chinese.string=""; status.stringValue="正在用你的声音生成英文，请稍候…"; statusItem?.button?.title="合成…"
  translationTimer=Timer.scheduledTimer(withTimeInterval:45,repeats:false) { [weak self] _ in Task { @MainActor in
   guard let self,self.state.translationTimedOut(id:id) else { return }; self.translationTask?.cancel(); self.errorText="本次翻译等待超过 45 秒，请重试。"; self.refresh()
  } }
  translationTask=Task { [weak self] in
   guard let self else { return }
   if let definition=Lexicon.lookup(text) {
    guard !Task.isCancelled,self.state.id==id else { return }
    self.translationTimer?.invalidate(); self.translationTimer=nil; self.state.translationReady(definition,id:id); self.refresh(); return
   }
   let source=Locale.Language(identifier:"en-GB"),target=Locale.Language(identifier:"zh-Hans")
   let availability=await LanguageAvailability().status(from:source,to:target)
   guard !Task.isCancelled,self.state.id==id else { return }
   guard availability == .installed else { self.translationTimer?.invalidate(); self.translationTimer=nil; self.errorText="本地英中翻译语言包尚未就绪。请在系统设置 → 通用 → 语言与地区 → 翻译语言中完成下载。"; self.refresh(); return }
   do {
    let response=try await TranslationSession(installedSource:source,target:target).translate(text)
    guard !Task.isCancelled,self.state.id==id else { return }
    self.translationTimer?.invalidate(); self.translationTimer=nil; self.state.translationReady(Lexicon.isWord(text) ? "1. "+response.targetText:response.targetText,id:id); self.refresh()
   } catch { guard self.state.id==id,!Task.isCancelled else { return }; self.translationTimer?.invalidate(); self.translationTimer=nil; self.errorText="本次翻译失败，请重试。"; self.refresh() }
  }
  do {
   let dir=FileManager.default.temporaryDirectory.appendingPathComponent("local-english-reader-"+id.uuidString,isDirectory:true)
   try FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true,attributes:[.posixPermissions:0o700]); temp=dir
   let output=dir.appendingPathComponent("voice.wav"),request=dir.appendingPathComponent("request.json")
   try JSONSerialization.data(withJSONObject:["text":text,"output":output.path]).write(to:request)
   guard let script=Bundle.main.url(forResource:"voice",withExtension:"py") else { throw NSError(domain:"缺少语音脚本",code:1) }
   let job=Process(); job.executableURL=URL(fileURLWithPath:python); job.arguments=[script.path,request.path]
   var env=ProcessInfo.processInfo.environment; env["HF_HUB_OFFLINE"]="1"; env["HF_HUB_DISABLE_TELEMETRY"]="1"; env["PYTHONDONTWRITEBYTECODE"]="1"; job.environment=env
   // Use a file, not an unread pipe: model output cannot fill a pipe and deadlock.
   let log=dir.appendingPathComponent("generation.log"); FileManager.default.createFile(atPath:log.path,contents:nil)
   let handle=try FileHandle(forWritingTo:log); job.standardOutput=handle; job.standardError=handle
   job.terminationHandler={ [weak self] job in
    try? handle.close()
    let succeeded=job.terminationStatus==0
    Task { @MainActor in
     guard let self,self.state.id==id else { return }
     self.timer?.invalidate(); self.timer=nil; self.process=nil
     guard succeeded,let audio=NSSound(contentsOf:output,byReference:false) else { self.translationTask?.cancel(); self.state.fail(id:id); self.setStatus("本人声音生成失败，请重试；确认本机 Qwen 环境仍可用。",error:true); return }
     self.sound=audio; self.speechSoundID=id; audio.delegate=self; self.status.stringValue="正在用你的声音朗读英文…"; self.statusItem?.button?.title="朗读…"
     if !audio.play() { self.state.fail(id:id); self.setStatus("音频播放失败，请检查声音输出设备。",error:true) }
    }
   }
   process=job; try job.run()
   timer=Timer.scheduledTimer(withTimeInterval:180,repeats:false) { [weak self] _ in Task { @MainActor in guard let self,self.state.id==id else { return }; self.stop(); self.setStatus("生成等待超过 3 分钟，已停止，请缩短所选文本后重试。",error:true) } }
  } catch { cancelWork(); state.fail(id:id); setStatus("无法启动本机语音工具，请检查现有 Qwen 环境。",error:true) }
 }
 func sound(_ sound:NSSound,didFinishPlaying flag:Bool) {
  guard sound === self.sound,let id=speechSoundID,id==state.id,flag else { return }
  state.speechFinished(id:id); refresh()
 }
 func refresh() {
  if let text=state.visibleTranslation { chinese.string=text; status.stringValue="朗读完成 · 中文不朗读，可重听或关闭。"; statusItem?.button?.title="读"; if backgroundMode && PresentationPolicy.showResult(speechDone:state.speechCompleted,hasResult:true) { resultPanel.show(english:requestedText,chinese:text)
   if CommandLine.arguments.contains("--smoke-background") || CommandLine.arguments.contains("--smoke-dictionary") {
    print("SMOKE_EDITOR_AT_END=\(window.isVisible)"); print("SMOKE_CARD_VISIBLE=\(resultPanel.panel.isVisible)"); print("SMOKE_CHINESE=\(text)"); fflush(stdout)
    DispatchQueue.main.asyncAfter(deadline:.now()+2) { NSApp.terminate(nil) }
   }
  } }
  else if state.speechCompleted {
   chinese.string=errorText ?? "正在等待中文翻译…"; status.stringValue="英文朗读完成。"; statusItem?.button?.title=errorText == nil ? "译…":"读"; if backgroundMode,let errorText { resultPanel.show(english:requestedText,chinese:errorText) }
  }
 }
}
@main struct Main {
 @MainActor static func main() {
  let application=NSApplication.shared
  if CommandLine.arguments.contains("--check-integration") {
   do { let key=try GlobalReadHotKey(action:{}); print("HOTKEY=\(GlobalReadHotKey.label) registered"); key.invalidate() }
   catch { print("HOTKEY=\(GlobalReadHotKey.label) failed: \(error)") }
   print("SELECTION_ACCESS=\(AXIsProcessTrusted())")
   return
  }
  let delegate=ReaderApp()
  application.delegate=delegate
  application.run()
 }
}
