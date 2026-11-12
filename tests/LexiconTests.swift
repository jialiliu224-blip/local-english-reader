import Foundation
@main struct Tests {
 static func main() {
  assert(Lexicon.isWord("prompt"));assert(!Lexicon.isWord("a prompt for input"))
  let prompt=Lexicon.concise("prompt",raw:"noun ① 提示 tíshì▸ a prompt example 示例")
  let lines=prompt.components(separatedBy:"\n")
  assert(lines.count<=5 && lines.count>=1,"最多五条")
  assert(lines[0].contains("提示词"),"AI学习用义优先")
  assert(lines.contains(where:{$0.contains("提示符")}),"保留Python提示符")
  assert(!prompt.contains("示例") && !prompt.contains("tíshì"),"不显示例句和拼音")
  let other=Lexicon.concise("sampleword",raw:"sampleword | BrE abc | noun ① (role) 功能 gōngnéng; 职责 zhízé▸ an example 例子 ② (purpose) 用途 yòngtú ③ Computing 模板 múbǎn")
  assert(other.components(separatedBy:"\n")[0].contains("模板"),"编程义优先")
  assert(!other.contains("gōng") && !other.contains("example") && !other.contains("例子"),"普通词也去掉拼音例句")
  assert(other.contains("功能、职责") && other.contains("用途"),"保留简短核心义")
  let single=Lexicon.concise("sampleword",raw:"noun ① 物体 wùtǐ")
  assert(single.components(separatedBy:"\n").count==1,"不凑满五条")
  assert(Lexicon.lookup("bank")!.components(separatedBy:"\n")[0].contains("银行"))
  assert(Lexicon.lookup("light")!.contains("轻的"))
  print("PASS: 12 个简洁释义、数量上限与领域排序检查")
 }
}
