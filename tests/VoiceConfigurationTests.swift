import Foundation
@main struct Tests {
 static func main() throws {
  let fm=FileManager.default
  let root=fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try fm.createDirectory(at:root,withIntermediateDirectories:true)
  defer { try? fm.removeItem(at:root) }
  let config=root.appendingPathComponent("voice.json")
  func rejects()->Bool { do { _=try VoiceConfiguration.load(from:config); return false } catch { return true } }
  assert(rejects(),"缺配置不得回退到作者声音")
  let python=root.appendingPathComponent("python"), model=root.appendingPathComponent("model"), audio=root.appendingPathComponent("sample.wav")
  try Data("fixture".utf8).write(to:python)
  try fm.setAttributes([.posixPermissions:0o700],ofItemAtPath:python.path)
  try fm.createDirectory(at:model,withIntermediateDirectories:true)
  try Data("fixture".utf8).write(to:audio)
  var data=["python":python.path,"model_path":model.path,"reference_audio":audio.path,"reference_text":"This is a test."]
  func save() throws { try JSONSerialization.data(withJSONObject:data).write(to:config) }
  try save()
  let loaded=try VoiceConfiguration.load(from:config)
  assert(loaded.reference_text == "This is a test.")
  data["model_path"]="https://example.invalid/model";try save();assert(rejects(),"拒绝远程模型路径")
  data["model_path"]=model.path;data["reference_text"]=" ";try save();assert(rejects(),"拒绝空白参考文字")
  data["reference_text"]="Test";data["reference_audio"]=model.path;try save();assert(rejects(),"参考音频不能是目录")
  print("PASS: 5 个独立配置与缺失资料检查")
 }
}
