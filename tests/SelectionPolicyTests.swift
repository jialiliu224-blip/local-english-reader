import Foundation
@main struct Tests {
 static func main() {
  assert(SelectionPolicy.selectedText(nil,originalPID:12,currentPID:12) == nil,"无选区时不读取其他内容")
  assert(SelectionPolicy.selectedText("  ",originalPID:12,currentPID:12) == nil,"空选区不朗读")
  assert(SelectionPolicy.selectedText("return",originalPID:12,currentPID:13) == nil,"切换应用后拒绝旧结果")
  assert(SelectionPolicy.selectedText("return",originalPID:12,currentPID:nil) == nil,"应用消失时拒绝旧结果")
  assert(SelectionPolicy.selectedText(" return ",originalPID:12,currentPID:12) == "return","保留当前应用的实际选区")
  print("PASS: 5 个选区与应用身份断言")
 }
}
