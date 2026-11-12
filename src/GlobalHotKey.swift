import Cocoa
import Carbon
import ApplicationServices

@MainActor final class GlobalReadHotKey {
 static let usesR = UserDefaults.standard.string(forKey:"readHotKey") == "option-r"
 static var label:String { usesR ? "⌥R":"⌥Esc" }
 static var keyCode:UInt32 { usesR ? UInt32(kVK_ANSI_R):UInt32(kVK_Escape) }
 var hotKey:EventHotKeyRef?,handler:EventHandlerRef?
 let action:()->Void
 init(action:@escaping ()->Void) throws {
  self.action=action
  var event=EventTypeSpec(eventClass:OSType(kEventClassKeyboard),eventKind:UInt32(kEventHotKeyPressed))
  let installed=InstallEventHandler(GetApplicationEventTarget(),{ _, event, context in
   guard let context,let event else { return OSStatus(eventNotHandledErr) }
   var identity=EventHotKeyID()
   let result=GetEventParameter(event,EventParamName(kEventParamDirectObject),EventParamType(typeEventHotKeyID),nil,MemoryLayout<EventHotKeyID>.size,nil,&identity)
   guard result == noErr,identity.signature == 0x44585244,identity.id==1 else { return OSStatus(eventNotHandledErr) }
   let owner=Unmanaged<GlobalReadHotKey>.fromOpaque(context).takeUnretainedValue()
   Task { @MainActor in owner.action() }
   return noErr
  },1,&event,Unmanaged.passUnretained(self).toOpaque(),&handler)
  guard installed == noErr else { throw NSError(domain:"无法监听朗读快捷键",code:Int(installed)) }
  let registered=RegisterEventHotKey(Self.keyCode,UInt32(optionKey),EventHotKeyID(signature:0x44585244,id:1),GetApplicationEventTarget(),0,&hotKey)
  guard registered == noErr else { if let handler { RemoveEventHandler(handler); self.handler=nil }; throw NSError(domain:"\(Self.label) 已被其他程序占用",code:Int(registered)) }
 }
 func invalidate() { if let hotKey { UnregisterEventHotKey(hotKey) }; if let handler { RemoveEventHandler(handler) }; hotKey=nil; handler=nil }
}

@MainActor enum SelectionCapture {
 static var preparedChromePIDs=Set<pid_t>()
 static func currentSelectedText(target:NSRunningApplication?) async throws -> String {
  guard let target,target.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
   throw NSError(domain:"请先在其他应用中选中英文",code:1)
  }
  let pid=target.processIdentifier
  let app=AXUIElementCreateApplication(pid)
  AXUIElementSetMessagingTimeout(app,0.25)
  let isChrome=["com.google.Chrome","com.google.Chrome.beta","com.google.Chrome.dev","com.google.Chrome.canary","org.chromium.Chromium"].contains(target.bundleIdentifier ?? "")
  do {
   return try await SelectionRecovery.read(canWarmup:isChrome,isCurrent:{
    !target.isTerminated && NSWorkspace.shared.frontmostApplication?.processIdentifier == pid
   },probe:{ selectedText(in:app,pid:pid) },warmup:{
    // Chromium activates accessibility lazily. Request it only after a failed
    // selection read, at most once per process; do not toggle VoiceOver itself.
    guard preparedChromePIDs.insert(pid).inserted else { return }
    var role:CFTypeRef?
    _=AXUIElementCopyAttributeValue(app,kAXRoleAttribute as CFString,&role)
    _=AXUIElementSetAttributeValue(app,"AXEnhancedUserInterface" as CFString,kCFBooleanTrue)
   })
  } catch is CancellationError { throw CancellationError() }
  catch SelectionRecovery.Failure.applicationChanged {
   throw NSError(domain:"选区读取期间切换了应用，请重新选中英文后按快捷键。",code:4)
  } catch {
   throw NSError(domain:"没有读取到当前选区；请重新选中后重试，或使用阅读器的粘贴入口。",code:3)
  }
 }
 static func selectedText(in app:AXUIElement,pid:pid_t)->String? {
  var focused:CFTypeRef?
  guard AXUIElementCopyAttributeValue(app,kAXFocusedUIElementAttribute as CFString,&focused) == .success,
        let focused,CFGetTypeID(focused) == AXUIElementGetTypeID() else { return nil }
  var element=unsafeBitCast(focused,to:AXUIElement.self)
  // Inspect selection attributes only on the focused element and ancestors.
  // No page scanning, clipboard access, copy simulation, or window activation.
  for _ in 0..<8 {
   guard NSWorkspace.shared.frontmostApplication?.processIdentifier == pid else { return nil }
   var value:CFTypeRef?
   if AXUIElementCopyAttributeValue(element,kAXSelectedTextAttribute as CFString,&value) == .success {
    let text=(value as? String) ?? (value as? NSAttributedString)?.string
    if let text=SelectionPolicy.selectedText(text,originalPID:pid,currentPID:NSWorkspace.shared.frontmostApplication?.processIdentifier) { return text }
   }
   var parent:CFTypeRef?
   guard AXUIElementCopyAttributeValue(element,kAXParentAttribute as CFString,&parent) == .success,
         let parent,CFGetTypeID(parent) == AXUIElementGetTypeID() else { break }
   element=unsafeBitCast(parent,to:AXUIElement.self)
  }
  return nil
 }
}
