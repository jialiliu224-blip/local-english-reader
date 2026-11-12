import Foundation
struct SelectionPolicy {
 static func selectedText(_ text:String?,originalPID:Int32,currentPID:Int32?)->String? {
  guard originalPID == currentPID,let text else { return nil }
  let trimmed=text.trimmingCharacters(in:.whitespacesAndNewlines)
  return trimmed.isEmpty ? nil:trimmed
 }
}
