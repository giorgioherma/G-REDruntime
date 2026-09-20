module GRedRuntime

public class DiagnosticSnapshot extends IScriptable {
  public let schedulerWakeups: Int32;
  public let schedulerJobRuns: Int32;
  public let eventPublishes: Int32;
  public let eventDeliveries: Int32;
  public let inputEventsSeen: Int32;
  public let inputDeliveries: Int32;
  public let hookDispatches: Int32;
  public let hookDeliveries: Int32;
  public let stateCacheHits: Int32;
  public let stateCacheMisses: Int32;
}

public class Diagnostics extends IScriptable {
  private let m_schedulerWakeups: Int32;
  private let m_schedulerJobRuns: Int32;
  private let m_eventPublishes: Int32;
  private let m_eventDeliveries: Int32;
  private let m_inputEventsSeen: Int32;
  private let m_inputDeliveries: Int32;
  private let m_hookDispatches: Int32;
  private let m_hookDeliveries: Int32;
  private let m_stateCacheHits: Int32;
  private let m_stateCacheMisses: Int32;

  public func Reset() -> Void {
    this.m_schedulerWakeups = 0;
    this.m_schedulerJobRuns = 0;
    this.m_eventPublishes = 0;
    this.m_eventDeliveries = 0;
    this.m_inputEventsSeen = 0;
    this.m_inputDeliveries = 0;
    this.m_hookDispatches = 0;
    this.m_hookDeliveries = 0;
    this.m_stateCacheHits = 0;
    this.m_stateCacheMisses = 0;
  }

  public func SchedulerWakeup() -> Void { this.m_schedulerWakeups += 1; }
  public func SchedulerJobRun() -> Void { this.m_schedulerJobRuns += 1; }
  public func EventPublish() -> Void { this.m_eventPublishes += 1; }
  public func EventDelivery() -> Void { this.m_eventDeliveries += 1; }
  public func InputSeen() -> Void { this.m_inputEventsSeen += 1; }
  public func InputDelivery() -> Void { this.m_inputDeliveries += 1; }
  public func HookDispatch() -> Void { this.m_hookDispatches += 1; }
  public func HookDelivery() -> Void { this.m_hookDeliveries += 1; }
  public func StateCacheHit() -> Void { this.m_stateCacheHits += 1; }
  public func StateCacheMiss() -> Void { this.m_stateCacheMisses += 1; }

  public func Snapshot() -> ref<DiagnosticSnapshot> {
    let out = new DiagnosticSnapshot();
    out.schedulerWakeups = this.m_schedulerWakeups;
    out.schedulerJobRuns = this.m_schedulerJobRuns;
    out.eventPublishes = this.m_eventPublishes;
    out.eventDeliveries = this.m_eventDeliveries;
    out.inputEventsSeen = this.m_inputEventsSeen;
    out.inputDeliveries = this.m_inputDeliveries;
    out.hookDispatches = this.m_hookDispatches;
    out.hookDeliveries = this.m_hookDeliveries;
    out.stateCacheHits = this.m_stateCacheHits;
    out.stateCacheMisses = this.m_stateCacheMisses;
    return out;
  }
}
