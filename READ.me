G-RedRuntime — Pass 1 Core Framework
Version: 0.1.0-pass1

PURPOSE
=======
This is the first permanent REDscript optimization framework pass.
It is NOT a profiler and it does not require GRSP to run.

Pass 1 builds the reusable core only. Existing mods are not connected yet.
The goal of the first test is therefore:

1. prove the framework compiles and survives normal gameplay;
2. measure the empty-framework overhead with GRSP + CapFrameX;
3. verify that the scheduler stays dormant when no jobs are registered;
4. verify that the InputHub does not decode input when nobody subscribes;
5. establish a clean baseline before adapters are added in Pass 2.

INSTALL
=======
Extract into the Cyberpunk 2077 game root.

Installed path:
  r6\scripts\G-RedRuntime\

No DLL is involved. These are REDscript files.

DEPENDENCIES
============
Required:
  - redscript

Not required by the framework core:
  - Codeware
  - CET
  - GRSP
  - 0-Engine

GRSP + CapFrameX are only used for our performance testing.
CET is useful only for the optional manual diagnostic command below.

PASS 1 COMPONENTS
=================
Core / Runtime
  - ScriptableSystem singleton
  - lifecycle ownership
  - component access
  - player-attach propagation

State / StateCache
  - lazy cached GameInstance systems
  - PlayerSystem
  - local PlayerPuppet
  - QuestsSystem
  - StatsSystem
  - DelaySystem
  - TransactionSystem
  - BlackboardSystem
  - ScriptableSystemsContainer
  - cache hit/miss diagnostics

Events / DirtyFlags
  - named dirty flags
  - monotonically increasing per-flag generation/version
  - consume-once dirty checks

Events / EventBus
  - topic subscriptions
  - wildcard topic support
  - explicit unsubscribe handles
  - no dispatch work while empty

Input / InputHub
  - one shared engine input listener, registered lazily only when needed
  - NO permanent PlayerPuppet.OnAction wrapper in Pass 1
  - action name/type decoded once only when subscribers exist
  - action-specific or wildcard subscriptions
  - listener is unregistered when the last subscriber leaves

Scheduler
  - one lazy central DelaySystem loop
  - completely dormant when no jobs exist
  - arbitrary job interval >= 50 ms
  - repeating and one-shot jobs
  - generation guard against stale callbacks
  - shutdown cancellation

Hooks / HookBus
  - registration/dispatch infrastructure for future consolidated game hooks
  - no additional game hook targets are installed in Pass 1

Diagnostics
  - scheduler wakeups / job executions
  - event publications / deliveries
  - input observations / deliveries
  - hook dispatches / deliveries
  - state-cache hits / misses
  - no periodic logging

IMPORTANT PERFORMANCE DESIGN
============================
Pass 1 does NOT start a background scheduler merely because the framework exists.
The scheduler starts only after the first adapter registers a job and stops when
there are no enabled jobs.

InputHub registers no player input listener at all while it has no subscribers.
ListenerAction.GetName/GetType are therefore not called by G-RedRuntime in the empty framework.

There is no every-frame framework poll in Pass 1.
There is no movement-state poll in Pass 1.
There is no automatic quest-fact, combat, UI, equipment, vehicle or blackboard
polling yet. Those will be added only when the integration data justifies them.

MANUAL STATUS CHECK
===================
After loading a save, CET console can call:

  Game.GetPlayer():GRedRuntimeDump()

This only logs when you manually call it. It is not part of normal runtime work.
For a fresh framework with no adapters, expected scheduler counters are:

  scheduler wakeups = 0
  jobRuns = 0
  activeJobs = 0

Input/event/hook deliveries should also remain 0 because no adapters are connected.
State cache misses/hits may show a few lifecycle accesses.

FIRST TEST
==========
Keep the rest of the mod stack unchanged.

A. Launch the game.
B. Check r6\logs\redscript_r*.log for compilation errors.
C. Load the same save / area used for the established JIG tests.
D. Optionally run Game.GetPlayer():GRedRuntimeDump() once to confirm readiness.
E. Run the same clean JIG capture with GRSP and CapFrameX.
F. Send:
     - GRSP capture folder
     - matching CapFrameX capture
     - redscript log if there was any compile/runtime issue

For Pass 1 we compare against the framework-OFF JIG baseline before attaching any
existing mod to the framework.

UNINSTALL
=========
Delete:

  r6\scripts\G-RedRuntime

No save data is intentionally persisted by Pass 1.

PASS 2 DIRECTION
================
If the empty core is clean, Pass 2 will connect a meaningful group of real mods,
not one tiny adapter at a time. Candidate classes from profiling are:

  - always-on / input-heavy workload
  - periodic/shared-state polling workload
  - wrapper-chain workload
  - burst/amplification workload

The framework will then grow only where those integrations prove a shared primitive
is useful.
