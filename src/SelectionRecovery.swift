import Foundation

@MainActor enum SelectionRecovery {
 enum Failure:Error { case unavailable, applicationChanged }
 static func read(canWarmup:Bool,isCurrent:()->Bool,probe:()->String?,warmup:()->Void,
                  wait:() async throws ->Void = { try await Task.sleep(for:.milliseconds(100)) }) async throws ->String {
  func check() throws {
   try Task.checkCancellation()
   guard isCurrent() else { throw Failure.applicationChanged }
  }
  try check()
  if let text=probe() { try check(); return text }
  guard canWarmup else { throw Failure.unavailable }
  try check();warmup()
  let deadline=ContinuousClock.now.advanced(by:.seconds(3))
  for _ in 0..<30 {
   try await wait();try check()
   guard ContinuousClock.now < deadline else { break }
   if let text=probe() { try check();return text }
  }
  throw Failure.unavailable
 }
}
