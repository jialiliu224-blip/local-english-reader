import Foundation
import CoreServices
struct Lexicon {
 // Learning priority, not measured word-frequency probabilities.
 static let defaults:[String:[String]] = [
  "bank":["【名词】银行","【名词】河岸","【动词】存入银行","【名词】储备"],
  "light":["【名词】光、灯","【形容词】轻的","【形容词】浅色的","【动词】点燃、照亮"],
  "key":["【编程】键","【API】密钥","【名词】钥匙","【名词】关键","【形容词】关键的"],
  "value":["【编程】值","【名词】价值","【动词】重视、估价"],
  "model":["【AI】模型","【名词】样式、型号","【名词】模特","【动词】建模、塑造"],
  "token":["【AI】词元","【编程】令牌","【名词】代币","【名词】象征"],
  "completion":["【AI】生成结果","【名词】完成"],
  "index":["【Python】索引","【名词】目录","【名词】指数"],
  "range":["【Python】整数序列","【名词】范围","【名词】种类","【动词】变化、排列"],
  "tuple":["【Python】元组"],
  "set":["【Python】集合","【动词】设置、设定","【名词】一套、一组","【形容词】固定的"],
  "iterable":["【Python】可迭代对象"],
  "async":["【Python】异步"],
  "await":["【Python】等待异步结果","【动词】等待"],
  "with":["【Python】上下文管理","【介词】和、用、带着"],
  "try":["【Python】异常处理","【动词】尝试","【名词】尝试"],
  "def":["【Python】定义函数"],
  "self":["【Python】实例自身","【名词】自我"],
  "pass":["【Python】空操作","【动词】通过、传递","【名词】通行证"],
  "raise":["【Python】抛出异常","【动词】提高、举起","【动词】筹集"],
  "property":["【Python】属性","【名词】财产","【名词】性质"],
  "file":["【编程】文件","【名词】档案","【动词】归档","【名词】锉刀"],
  "open":["【Python】打开文件","【动词】打开","【形容词】开放的、开着的"],
  "close":["【编程】关闭","【动词】关上","【形容词】近的、亲密的"],
  "prompt":["【AI】提示词","【Python】提示符","【名词】提示、提醒","【动词】促使、提示","【形容词】迅速的、及时的"],
  "template":["【编程】模板","【名词】样板、范本","【名词】型板"],
  "function":["【编程】函数","【名词】功能、作用","【动词】运转、起作用","【名词】职责","【名词】大型聚会"],
  "class":["【Python】类","【名词】班级、课程","【名词】类别、等级"],
  "object":["【Python】对象","【名词】物体、东西","【名词】目标","【动词】反对"],
  "return":["【Python】返回","【动词】回来、返回","【动词】归还、退回","【名词】回报、收益","【名词】返程"],
  "string":["【Python】字符串","【名词】线、绳","【名词】一串","【动词】串起"],
  "list":["【Python】列表","【名词】清单、目录","【动词】列出"],
  "dictionary":["【Python】字典","【名词】词典"],
  "type":["【Python】类型","【名词】种类","【动词】打字、输入"],
  "input":["【Python】输入","【名词】投入、意见"],
  "print":["【Python】打印、输出","【动词】印刷","【名词】印刷文字"],
  "float":["【Python】浮点数","【动词】漂浮","【名词】浮标"],
  "integer":["【Python】整数"],
  "argument":["【Python】实参","【名词】争论","【名词】论点、理由"],
  "parameter":["【Python】形参","【名词】参数、限定条件"],
  "attribute":["【Python】属性","【名词】特征","【动词】归因于"],
  "method":["【Python】方法","【名词】方式、做法"],
  "instance":["【Python】实例","【名词】例子、情形"],
  "module":["【Python】模块","【名词】组件、单元"],
  "variable":["【编程】变量","【形容词】可变的","【名词】可变因素"],
  "exception":["【Python】异常","【名词】例外"],
  "format":["【Python】格式化","【名词】格式、版式","【动词】整理格式"],
  "import":["【Python】导入","【动词】进口","【名词】进口商品"],
  "package":["【Python】包","【名词】包裹","【动词】包装"],
  "decorator":["【Python】装饰器","【名词】装潢工"],
  "lambda":["【Python】匿名函数","【名词】希腊字母"],
  "literal":["【Python】字面量","【形容词】字面的、逐字的"],
  "generator":["【Python】生成器","【名词】发电机"],
  "iterator":["【Python】迭代器"],
  "yield":["【Python】产出、暂停让出","【动词】产生","【动词】让步","【名词】产量、收益"]
 ]
 static var preferencesURL:URL { FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/LocalEnglishReader/word_glosses.json") }
 static func preferred(_ word:String)->[String]? {
  if let data=try? Data(contentsOf:preferencesURL),let custom=try? JSONDecoder().decode([String:[String]].self,from:data),let entries=custom[word.lowercased()],!entries.isEmpty { return entries }
  return defaults[word.lowercased()]
 }
 static func isWord(_ raw:String)->Bool {
  let text=raw.trimmingCharacters(in:.whitespacesAndNewlines)
  return !text.isEmpty && text.range(of:"\\A[A-Za-z]+(?:[-'][A-Za-z]+)*\\z",options:.regularExpression) != nil
 }
 static func lookup(_ raw:String)->String? {
  let text=raw.trimmingCharacters(in:.whitespacesAndNewlines)
  guard isWord(text) else { return nil }
  if let entries=preferred(text) { return render(entries) }
  guard let entry=DCSCopyTextDefinition(nil,text as CFString,CFRange(location:0,length:text.utf16.count))?.takeRetainedValue() else { return nil }
  let result=concise(text,raw:entry as String)
  return result.isEmpty ? nil:result
 }
 static func render(_ entries:[String])->String {
  var unique=[String]()
  for entry in entries {
   let clean=entry.trimmingCharacters(in:.whitespacesAndNewlines)
   if !clean.isEmpty && !unique.contains(clean) { unique.append(clean) }
  }
  return unique.prefix(5).enumerated().map { "\($0.offset+1). \($0.element)" }.joined(separator:"\n")
 }
 static func partOfSpeech(_ text:String,default current:String)->String {
  let mapping=["intransitive verb":"动词","transitive verb":"动词","adjective":"形容词","adverb":"副词","preposition":"介词","pronoun":"代词","noun":"名词","verb":"动词"]
  let regex=try! NSRegularExpression(pattern:"\\b(intransitive verb|transitive verb|adjective|adverb|preposition|pronoun|noun|verb)\\b")
  guard let match=regex.matches(in:text,range:NSRange(text.startIndex...,in:text)).last,let range=Range(match.range,in:text) else { return current }
  return mapping[String(text[range])] ?? current
 }
 static func concise(_ word:String,raw:String)->String {
  if let entries=preferred(word) { return render(entries) }
  let parts=raw.split(separator:"|",maxSplits:2,omittingEmptySubsequences:false)
  let body=parts.count==3 ? String(parts[2]):raw
  let pieces=body.components(separatedBy:CharacterSet(charactersIn:"①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳"))
  let chinese=try! NSRegularExpression(pattern:"[\\p{Han}]+(?:…[\\p{Han}]+)*")
  var pos="词义",entries=[(Int,Int,String)](),seen=Set<String>()
  for (index,piece) in pieces.enumerated() {
   if index==0 { pos=partOfSpeech(piece,default:pos) }
   var head=piece.components(separatedBy:"▸")[0]
   head=head.replacingOccurrences(of:"\\([^)]*\\)|‹[^›]*›|«[^»]*»",with:"",options:.regularExpression)
   let words=chinese.matches(in:head,range:NSRange(head.startIndex...,in:head)).compactMap { Range($0.range,in:head).map { String(head[$0]) } }
   let meaning=Array(words.prefix(3)).joined(separator:"、")
   if !meaning.isEmpty && !seen.contains(meaning) {
    seen.insert(meaning)
    let technical=head.contains("Computing")
    entries.append((technical ? 0:1,index,"【\(technical ? "编程":pos)】\(meaning)"))
   }
   pos=partOfSpeech(piece,default:pos)
  }
  return render(entries.sorted { $0.0 == $1.0 ? $0.1 < $1.1:$0.0 < $1.0 }.map { $0.2 })
 }
}
