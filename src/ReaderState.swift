import Foundation
struct ReaderState {
 private(set) var id = UUID()
 private var speechDone = false
 private var translation: String?
 private var translationClosed = false
 var speechCompleted: Bool { speechDone }
 var visibleTranslation: String? { speechDone ? translation : nil }
 mutating func begin() -> UUID { id = UUID(); speechDone = false; translation = nil; translationClosed = false; return id }
 mutating func translationReady(_ text: String, id: UUID) { guard id == self.id, !translationClosed else { return }; translation = text }
 mutating func translationTimedOut(id: UUID) -> Bool { guard id == self.id, translation == nil, !translationClosed else { return false }; translationClosed = true; return true }
 mutating func speechFinished(id: UUID) { guard id == self.id else { return }; speechDone = true }
 mutating func fail(id: UUID) { guard id == self.id else { return }; translation = nil; speechDone = false; translationClosed = true }
}
