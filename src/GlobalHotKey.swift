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
 static func currentSelectedText() throws -> String {
  guard let pid=NSWorkspace.shared.frontmostApplication?.processIdentifier,pid != ProcessInfo.processInfo.processIdentifier else { throw NSError(domain:"请先在其他应用中选中英文",code:1) }
  let app=AXUIElementCreateApplication(pid)
  AXUIElementSetMessagingTimeout(app,0.6)
  var focused:CFTypeRef?
  guard AXUIElementCopyAttributeValue(app,kAXFocusedUIElementAttribute as CFString,&focused) == .success,let focused,CFGetTypeID(focused) == AXUIElementGetTypeID() else { throw NSError(domain:"当前应用没有提供可读取的英文选区，请改用粘贴入口",code:2) }
  var element=unsafeBitCast(focused,to:AXUIElement.self)
  // Only inspect selection attributes on the focused element and its ancestors.
  // Never scan page contents, read the clipboard, or simulate copy keys.
  for _ in 0..<8 {
   var value:CFTypeRef?
   if AXUIElementCopyAttributeValue(element,kAXSelectedTextAttribute as CFString,&value) == .success {
    let text=(value as? String) ?? (value as? NSAttributedString)?.string
    if let text=SelectionPolicy.selectedText(text,originalPID:pid,currentPID:NSWorkspace.shared.frontmostApplication?.processIdentifier) { return text }
   }
   var parent:CFTypeRef?
   guard AXUIElementCopyAttributeValue(element,kAXParentAttribute as CFString,&parent) == .success,let parent,CFGetTypeID(parent) == AXUIElementGetTypeID() else { break }
   element=unsafeBitCast(parent,to:AXUIElement.self)
  }
  throw NSError(domain:"没有读取到当前选区；请确认英文已选中。若此应用不提供选区，请复制后粘贴到阅读器。",code:3)
 }
}
