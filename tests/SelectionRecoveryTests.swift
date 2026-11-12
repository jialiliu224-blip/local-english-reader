import Foundation
@main struct Tests {
 @MainActor static func main() async throws {
  var warmed=false,probes=0,waits=0
  let recovered=try await SelectionRecovery.read(canWarmup:true,isCurrent:{true},probe:{ probes+=1;return warmed && waits>=2 ? "template":nil },warmup:{warmed=true},wait:{waits+=1})
  assert(recovered=="template" && warmed && waits==2,"冷接口要在同一次请求中恢复")
  warmed=false;waits=0
  let fast=try await SelectionRecovery.read(canWarmup:true,isCurrent:{true},probe:{"prompt"},warmup:{warmed=true},wait:{waits+=1})
  assert(fast=="prompt" && !warmed && waits==0,"已就绪选区无需唤醒或等待")
  warmed=false
  do { _=try await SelectionRecovery.read(canWarmup:false,isCurrent:{true},probe:{nil},warmup:{warmed=true},wait:{});assertionFailure() }
  catch SelectionRecovery.Failure.unavailable {}
  assert(!warmed,"普通应用不启用 Chrome 模式")
  var current=true;probes=0
  do { _=try await SelectionRecovery.read(canWarmup:true,isCurrent:{current},probe:{probes+=1;return nil},warmup:{},wait:{current=false});assertionFailure() }
  catch SelectionRecovery.Failure.applicationChanged {}
  assert(probes==1,"切换应用后不得继续读取")
  do { _=try await SelectionRecovery.read(canWarmup:true,isCurrent:{true},probe:{nil},warmup:{},wait:{throw CancellationError()});assertionFailure() }
  catch is CancellationError {}
  probes=0
  do { _=try await SelectionRecovery.read(canWarmup:true,isCurrent:{true},probe:{probes+=1;return nil},warmup:{},wait:{});assertionFailure() }
  catch SelectionRecovery.Failure.unavailable {}
  assert(probes<=31,"没有选区时重试必须有上限")
  print("PASS: 6 个 Chrome 初始化、快路径、应用切换、取消和上限检查")
 }
}
