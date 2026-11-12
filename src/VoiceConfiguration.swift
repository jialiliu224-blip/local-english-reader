import Foundation

struct VoiceConfiguration: Decodable {
 let python:String
 let model_path:String
 let reference_audio:String
 let reference_text:String
 static var url:URL {
  FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/LocalEnglishReader/voice.json")
 }
 static func load(from source:URL = url) throws -> VoiceConfiguration {
  let config=try JSONDecoder().decode(Self.self,from:Data(contentsOf:source))
  let fm=FileManager.default
  let paths=[config.python,config.model_path,config.reference_audio]
  guard paths.allSatisfy({ $0.hasPrefix("/") }), !config.reference_text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,
        fm.isExecutableFile(atPath:config.python) else {
   throw NSError(domain:"Local voice configuration is incomplete",code:1)
  }
  var isAudioDirectory:ObjCBool=false
  guard fm.fileExists(atPath:config.reference_audio,isDirectory:&isAudioDirectory), !isAudioDirectory.boolValue else {
   throw NSError(domain:"Reference audio file is unavailable",code:3)
  }
  var isDirectory:ObjCBool=false
  guard fm.fileExists(atPath:config.model_path,isDirectory:&isDirectory), isDirectory.boolValue else {
   throw NSError(domain:"Local model directory is unavailable",code:2)
  }
  return config
 }
}
