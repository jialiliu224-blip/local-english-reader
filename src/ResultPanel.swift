import Cocoa
final class PassiveResultPanel:NSPanel {
 override var canBecomeKey:Bool { false }
 override var canBecomeMain:Bool { false }
}
@MainActor final class ReadingResult {
 let panel=PassiveResultPanel(contentRect:NSRect(x:0,y:0,width:360,height:240),styleMask:[.titled,.closable,.nonactivatingPanel,.utilityWindow],backing:.buffered,defer:false)
 let english=NSTextField(wrappingLabelWithString:""),chinese=NSTextView()
 let scroll=NSScrollView()
 init() {
  panel.title="英文 · 中文释义"; panel.level = .floating; panel.hidesOnDeactivate=false; panel.isReleasedWhenClosed=false
  panel.collectionBehavior=[.canJoinAllSpaces,.fullScreenAuxiliary,.ignoresCycle]
  let content=panel.contentView!
  english.font = .systemFont(ofSize:17,weight:.medium); english.maximumNumberOfLines=3; english.isSelectable=true
  scroll.hasVerticalScroller=true; scroll.autohidesScrollers=true; scroll.drawsBackground=false
  chinese.font = .systemFont(ofSize:17); chinese.textColor = .labelColor; chinese.drawsBackground=false; chinese.isEditable=false; chinese.isSelectable=true; chinese.isRichText=false
  chinese.isVerticallyResizable=true; chinese.isHorizontallyResizable=false; chinese.autoresizingMask=[.width]
  chinese.textContainerInset=NSSize(width:0,height:4); chinese.textContainer?.widthTracksTextView=true
  chinese.maxSize=NSSize(width:CGFloat.greatestFiniteMagnitude,height:CGFloat.greatestFiniteMagnitude)
  scroll.documentView=chinese; content.addSubview(english); content.addSubview(scroll)
 }
 func show(english:String,chinese:String) {
  self.english.stringValue=english; self.chinese.string=chinese; self.english.toolTip=english
  let point=NSEvent.mouseLocation
  let screen=NSScreen.screens.first { NSMouseInRect(point,$0.frame,false) } ?? NSScreen.main
  let shortHeight=max(200.0,min(290.0,120.0+Double(chinese.components(separatedBy:"\n").count)*27.0))
  let height=min(chinese.count<240 ? shortHeight:(chinese.count>500 ? 410.0:300.0),(screen?.visibleFrame.height ?? 700)*0.65)
  panel.setContentSize(NSSize(width:360,height:height))
  self.english.frame=NSRect(x:16,y:height-82,width:328,height:62)
  scroll.frame=NSRect(x:16,y:12,width:328,height:height-102)
  self.chinese.frame=NSRect(origin:.zero,size:scroll.contentSize)
  if let container=self.chinese.textContainer,let layout=self.chinese.layoutManager {
   layout.ensureLayout(for:container)
   self.chinese.setFrameSize(NSSize(width:scroll.contentSize.width,height:max(scroll.contentSize.height,layout.usedRect(for:container).height+12)))
  }
  scroll.contentView.scroll(to:.zero); scroll.reflectScrolledClipView(scroll.contentView)
  if let frame=screen?.visibleFrame { panel.setFrameOrigin(NSPoint(x:frame.maxX-panel.frame.width-18,y:frame.maxY-panel.frame.height-18)) }
  panel.orderFrontRegardless()
 }
 func hide() { panel.orderOut(nil) }
}
