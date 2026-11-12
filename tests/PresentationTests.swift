import Foundation
@main struct Tests {
 static func main() {
  assert(!PresentationPolicy.showEditor(background:true),"快捷键不打开编辑窗口")
  assert(PresentationPolicy.showEditor(background:false),"手动设置仍能打开窗口")
  assert(!PresentationPolicy.showResult(speechDone:false,hasResult:true),"朗读未结束不显示翻译")
  assert(!PresentationPolicy.showResult(speechDone:true,hasResult:false),"无译文不显示空卡片")
  assert(PresentationPolicy.showResult(speechDone:true,hasResult:true),"朗读后显示结果")
  print("PASS: 5 个后台朗读与结果显示断言")
 }
}
