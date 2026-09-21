# Changelog

All notable G-REDruntime development passes are recorded here.

A pass is only marked **Accepted** after compile, runtime, functional, and profiling review. Candidate builds do not automatically become the next base.

## [0.2.0-pass2] — Pass 2.0: Shared Input & Hotpath Integration

**Status:** Candidate / awaiting full acceptance

### Framework

#### Changed — InputHub

- Added wildcard/global subscription support through `SubscribeAll()`.
- Added `HasSubscribersFor(actionName)`.
- Added `InputEvent.consumed`.
- Input listeners can now propagate consumption back through the shared bridge.
- Added automatic registration refresh when subscriptions change.
- Added action-specific engine listener registration when no wildcard consumer exists.
- Added global engine listener registration when at least one wildcard consumer exists.
- Added deduplication of registered action names.
- Added correct unregister behavior for both global and action-specific registrations.
- `ListenerAction.GetName()` and `ListenerAction.GetType()` remain centrally decoded once per observed action before subscriber delivery.

#### Changed — Runtime

- Framework version advanced from `0.1.0-pass1` to `0.2.0-pass2`.

### Associated integration patch set

Pass 2.0 also introduces a separate differential mod patch set targeting:

- `custom_quickslots`
- `FlushingEtiquette`
- `BrowserExtension`
- `Enhanced Vehicle System`

The third-party patches are not stored as complete mods in this repository.

The integration work is intended to:

- route compatible input-heavy workloads through the shared InputHub
- reduce duplicate input decoding and listener work
- remove avoidable per-input scans
- reuse stable references where behavior remains live
- reduce repeated same-callback vehicle/input lookups

### Base status

This version does **not** become the accepted project base until the full Pass 2.0 framework + mod patch set passes:

- full-stack REDscript compilation
- normal game startup/load
- feature-specific smoke tests
- regression testing
- GRSP/profile comparison

---

## [0.1.0-pass1] — Pass 1: Core Framework

**Status:** Accepted / validated

### Added

#### Runtime

- Added G-REDruntime `ScriptableSystem` runtime singleton.
- Added framework lifecycle initialization and shutdown.
- Added player-attach propagation.
- Added public accessors for framework services.
- Added manual diagnostics dump support.

#### StateCache

- Added lazy cached access to:
  - `PlayerSystem`
  - local `PlayerPuppet`
  - `QuestsSystem`
  - `StatsSystem`
  - `DelaySystem`
  - `TransactionSystem`
  - `BlackboardSystem`
  - `ScriptableSystemsContainer`
- Added state-cache hit/miss diagnostics.

#### DirtyFlags

- Added named dirty flags.
- Added per-flag monotonically increasing versions.
- Added consume-once dirty state.
- Added global clear support.

#### EventBus

- Added topic-based subscriptions.
- Added wildcard topic subscriptions.
- Added explicit unsubscribe handles.
- Added zero-dispatch fast path while no subscribers exist.

#### InputHub

- Added shared input bridge.
- Added lazy player input listener registration.
- Added action-specific/wildcard subscription model.
- Added centralized action name/type decoding.
- Added automatic unregister when the last subscriber leaves.

#### Scheduler

- Added lazy central `DelaySystem` scheduler.
- Added repeating and one-shot jobs.
- Added minimum 50 ms job interval.
- Added stale-callback generation guard.
- Added shutdown cancellation.
- Scheduler remains dormant with zero registered jobs.

#### HookBus

- Added hook registration/dispatch infrastructure for later consolidation work.
- No broad game-hook targets were installed in Pass 1.

#### Diagnostics

- Added counters for:
  - scheduler wakeups
  - scheduler job runs
  - event publications
  - event deliveries
  - input events observed
  - input deliveries
  - hook dispatches
  - hook deliveries
  - state-cache hits
  - state-cache misses
- No periodic logging was introduced.

### Validation

Pass 1 successfully:

- compiled inside the full live REDscript stack
- emitted the complete modded REDscript cache
- loaded and ran normally in-game
- survived normal gameplay/lifecycle testing

Pass 1 became the accepted baseline for Pass 2 development.
