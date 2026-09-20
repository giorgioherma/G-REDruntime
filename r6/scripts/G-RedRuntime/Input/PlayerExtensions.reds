module GRedRuntime

@addMethod(PlayerPuppet)
public func GRedRuntimeDump() -> Void {
  let runtime = Runtime.Get(this.GetGame());
  if IsDefined(runtime) {
    runtime.DumpDiagnostics();
  } else {
    LogChannel(n"G-RedRuntime", "G-RedRuntime is not available");
  }
}
