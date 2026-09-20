module GRedRuntime

public class ScheduledJob extends IScriptable {
  private let m_id: Int32;
  private let m_name: CName;
  private let m_interval: Float;
  private let m_elapsed: Float;
  private let m_repeat: Bool;
  private let m_enabled: Bool;

  public func Configure(name: CName, interval: Float, repeat: Bool) -> ref<ScheduledJob> {
    this.m_name = name;
    this.m_interval = interval;
    if this.m_interval < 0.05 {
      this.m_interval = 0.05;
    }
    this.m_repeat = repeat;
    this.m_enabled = true;
    this.m_elapsed = 0.00;
    return this;
  }

  public func Execute(runtime: ref<Runtime>) -> Void {}

  public func GetID() -> Int32 { return this.m_id; }
  public func GetName() -> CName { return this.m_name; }
  public func GetInterval() -> Float { return this.m_interval; }
  public func IsEnabled() -> Bool { return this.m_enabled; }
  public func IsRepeating() -> Bool { return this.m_repeat; }

  public func Disable() -> Void {
    this.m_enabled = false;
  }

  public func Enable() -> Void {
    this.m_enabled = true;
  }

  public func ResetTimer() -> Void {
    this.m_elapsed = 0.00;
  }

  public func InternalSetID(id: Int32) -> Void {
    this.m_id = id;
  }

  public func InternalAdvance(delta: Float) -> Bool {
    if !this.m_enabled {
      return false;
    }

    this.m_elapsed += delta;
    if this.m_elapsed < this.m_interval {
      return false;
    }

    this.m_elapsed -= this.m_interval;
    if this.m_elapsed > this.m_interval {
      this.m_elapsed = 0.00;
    }
    return true;
  }
}

public class SchedulerTickCallback extends DelayCallback {
  private let m_scheduler: wref<Scheduler>;
  private let m_generation: Uint32;

  public static func Create(scheduler: ref<Scheduler>, generation: Uint32) -> ref<SchedulerTickCallback> {
    let self = new SchedulerTickCallback();
    self.m_scheduler = scheduler;
    self.m_generation = generation;
    return self;
  }

  public func Call() -> Void {
    if IsDefined(this.m_scheduler) {
      this.m_scheduler.OnTick(this.m_generation);
    }
  }
}

public class Scheduler extends IScriptable {
  private let m_runtime: wref<Runtime>;
  private let m_state: wref<StateCache>;
  private let m_diagnostics: wref<Diagnostics>;
  private let m_jobs: array<ref<ScheduledJob>>;
  private let m_nextID: Int32;
  private let m_activeJobs: Int32;
  private let m_running: Bool;
  private let m_generation: Uint32;
  private let m_tickInterval: Float;
  private let m_delayID: DelayID;

  public func Initialize(runtime: ref<Runtime>, state: ref<StateCache>, diagnostics: ref<Diagnostics>) -> Void {
    this.m_runtime = runtime;
    this.m_state = state;
    this.m_diagnostics = diagnostics;
    this.m_nextID = 1;
    this.m_tickInterval = 0.05;
    this.m_generation = 1u;
  }

  public func Shutdown() -> Void {
    this.m_running = false;
    this.m_generation += 1u;

    let delaySystem = this.m_state.GetDelaySystem();
    let invalidID: DelayID;
    if IsDefined(delaySystem) && NotEquals(this.m_delayID, invalidID) {
      delaySystem.CancelDelay(this.m_delayID);
    }
    this.m_delayID = invalidID;

    let i: Int32 = 0;
    let count = ArraySize(this.m_jobs);
    while i < count {
      if IsDefined(this.m_jobs[i]) {
        this.m_jobs[i].Disable();
      }
      i += 1;
    }
    this.m_activeJobs = 0;
  }

  public func Register(job: ref<ScheduledJob>) -> Int32 {
    if !IsDefined(job) {
      return 0;
    }

    let id = this.m_nextID;
    this.m_nextID += 1;
    job.InternalSetID(id);
    job.Enable();
    job.ResetTimer();
    ArrayPush(this.m_jobs, job);
    this.m_activeJobs += 1;
    this.EnsureRunning();
    return id;
  }

  public func Unregister(id: Int32) -> Bool {
    let i: Int32 = 0;
    let count = ArraySize(this.m_jobs);
    while i < count {
      let job = this.m_jobs[i];
      if IsDefined(job) && job.GetID() == id && job.IsEnabled() {
        job.Disable();
        this.m_activeJobs -= 1;
        return true;
      }
      i += 1;
    }
    return false;
  }

  public func HasJobs() -> Bool {
    return this.m_activeJobs > 0;
  }

  public func GetActiveJobCount() -> Int32 {
    return this.m_activeJobs;
  }

  public func OnTick(generation: Uint32) -> Void {
    if !this.m_running || generation != this.m_generation {
      return;
    }

    if IsDefined(this.m_diagnostics) {
      this.m_diagnostics.SchedulerWakeup();
    }

    let i: Int32 = 0;
    let enabledCount: Int32 = 0;
    let count = ArraySize(this.m_jobs);
    while i < count {
      let job = this.m_jobs[i];
      if IsDefined(job) && job.IsEnabled() {
        if job.InternalAdvance(this.m_tickInterval) {
          if IsDefined(this.m_diagnostics) {
            this.m_diagnostics.SchedulerJobRun();
          }

          job.Execute(this.m_runtime);

          if !job.IsRepeating() && job.IsEnabled() {
            job.Disable();
          }
        }

        if job.IsEnabled() {
          enabledCount += 1;
        }
      }
      i += 1;
    }
    this.m_activeJobs = enabledCount;

    if this.m_activeJobs > 0 {
      this.ScheduleNext();
    } else {
      this.m_running = false;
      let invalidID: DelayID;
      this.m_delayID = invalidID;
    }
  }

  private func EnsureRunning() -> Void {
    if this.m_running || this.m_activeJobs <= 0 {
      return;
    }

    this.m_running = true;
    this.m_generation += 1u;
    this.ScheduleNext();
  }

  private func ScheduleNext() -> Void {
    let delaySystem = this.m_state.GetDelaySystem();
    if !IsDefined(delaySystem) {
      this.m_running = false;
      return;
    }

    this.m_delayID = delaySystem.DelayCallback(
      SchedulerTickCallback.Create(this, this.m_generation),
      this.m_tickInterval,
      false
    );
  }
}
