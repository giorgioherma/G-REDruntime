# G-REDruntime integration overlay model

This document defines how an existing Cyberpunk 2077 REDscript mod is connected to G-REDruntime without converting that mod into a framework-specific package.

The installed mod remains authoritative.

## Preferred order

Use the least invasive integration that can preserve behavior:

```text
1. no mod change
   framework service can be consumed transparently

2. additive adapter
   original mod files remain at their existing paths
   add one small adapter file beside them

3. differential in-place patch
   change only the measured implementation points that cannot be adapted safely
   keep the original file paths and public surface

4. no integration
   when behavior/lifetime/invalidation cannot be proven safe
```

The framework does not rewrite arbitrary mods automatically.

## Additive adapter pattern

When REDscript wrapping or an existing public method gives a safe boundary, keep the original mod source untouched and add an integration file under that mod's normal path.

Example package shape:

```text
r6/scripts/ExistingMod/Main.reds
r6/scripts/ExistingMod/Feature.reds
r6/scripts/ExistingMod/GRedRuntimeAdapter.reds
```

The adapter may call:

```text
GRedRuntime.Runtime.Get(game)
runtime.GetStateCache()
runtime.GetDirtyFlags()
runtime.GetEventBus()
runtime.GetInputHub()
runtime.GetScheduler()
runtime.GetContextService()
runtime.GetHookBus()
```

The adapter belongs to the integration overlay, not to G-REDruntime core.

Reason: an adapter that names an optional mod's types creates a compile dependency on that mod. Keeping it outside the core lets the core compile and remain dormant whether or not that optional mod exists.

## Differential patch pattern

Some optimizations cannot be expressed safely from an additive wrapper. Examples include:

- replacing a private per-frame scan with an indexed structure;
- reusing a value inside a private callback body;
- moving a private timer to the shared scheduler while preserving the original timing contract;
- adding precise invalidation at the exact point where the mod mutates state.

In those cases, patch the minimum existing source at its original path.

Do not:

- rename the mod folder;
- move source under `G-RedRuntime`;
- rename public classes/methods merely for framework use;
- ship a second shadow copy of the mod;
- make unrelated optional mods compile dependencies.

## Framework capability mapping

Profiler evidence should determine which service, if any, is appropriate.

| GRSP evidence | Candidate framework service | Required proof before integration |
| --- | --- | --- |
| repeated stable system lookup | `StateCache` | handle lifetime is session-safe |
| same derived state recalculated after no change | `DirtyFlags` / `ContextService` | every mutation has an invalidation path |
| repeated independent timers | `Scheduler` | original cadence/latency contract is preserved |
| duplicate input listeners | `InputHub` | action filtering and consumption semantics are preserved |
| repeated publish/subscribe plumbing | `EventBus` | ordering and delivery semantics are preserved |
| repeated shared game-hook boundary | `HookBus` | one wrapper can reproduce original callback order and arguments |

A high call count alone is not proof that work can be cached, throttled, or consolidated.

## Ownership and removal

Every integration overlay should have an explicit file ownership list.

```text
added files
  -> remove only if still exact integration-owned content

modified pre-existing files
  -> back up and verify before replacement
  -> restore exact original on removal
  -> never overwrite an externally changed file blindly
```

This is the same transactional ownership rule used by the profiler managers.

## Acceptance

An integration is not accepted from source inspection alone.

Required evidence:

```text
REDscript compile
game load
feature regression check
GRSP before/after comparison
CapFrameX before/after when frame pacing matters
uninstall/restore verification
```

The goal is not to make mods look like G-REdruntime mods. The goal is to reduce duplicated runtime work while the mods keep their existing package identity and external behavior.
