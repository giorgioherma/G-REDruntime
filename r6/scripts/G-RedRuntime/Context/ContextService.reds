module GRedRuntime

public class ContextService extends IScriptable {
  private let m_state: wref<StateCache>;
  private let m_dirty: wref<DirtyFlags>;
  private let m_mountedVehicle: wref<VehicleObject>;
  private let m_vehicleRefreshAt: Float;
  private let m_inCombat: Bool;
  private let m_combatKnown: Bool;
  private let m_combatRefreshAt: Float;
  private let m_refreshInterval: Float;

  public func Initialize(state: ref<StateCache>, dirty: ref<DirtyFlags>) -> Void {
    this.m_state = state;
    this.m_dirty = dirty;
    this.m_refreshInterval = 0.05;
    this.m_vehicleRefreshAt = -1.00;
    this.m_combatRefreshAt = -1.00;
  }

  public func Shutdown() -> Void {
    this.m_mountedVehicle = null;
    this.m_vehicleRefreshAt = -1.00;
    this.m_combatRefreshAt = -1.00;
    this.m_combatKnown = false;
    this.m_state = null;
    this.m_dirty = null;
  }

  public func Invalidate() -> Void {
    this.m_vehicleRefreshAt = -1.00;
    this.m_combatRefreshAt = -1.00;
    this.m_combatKnown = false;
  }

  public func GetPlayer() -> wref<PlayerPuppet> {
    if !IsDefined(this.m_state) {
      return null;
    }
    return this.m_state.GetPlayer();
  }

  public func GetMountedVehicle() -> wref<VehicleObject> {
    let now = this.Now();
    if this.m_vehicleRefreshAt < 0.00 || (now - this.m_vehicleRefreshAt) >= this.m_refreshInterval {
      let previous = this.m_mountedVehicle;
      let player = this.GetPlayer();
      this.m_mountedVehicle = IsDefined(player) ? player.GetMountedVehicle() : null;
      this.m_vehicleRefreshAt = now;

      if NotEquals(previous, this.m_mountedVehicle) && IsDefined(this.m_dirty) {
        this.m_dirty.Mark(n"VEHICLE");
      }
    }
    return this.m_mountedVehicle;
  }

  public func IsInCombat() -> Bool {
    let now = this.Now();
    if !this.m_combatKnown || this.m_combatRefreshAt < 0.00 || (now - this.m_combatRefreshAt) >= this.m_refreshInterval {
      let previous = this.m_inCombat;
      let player = this.GetPlayer();
      this.m_inCombat = IsDefined(player) && player.IsInCombat();
      this.m_combatRefreshAt = now;

      if this.m_combatKnown && NotEquals(previous, this.m_inCombat) && IsDefined(this.m_dirty) {
        this.m_dirty.Mark(n"COMBAT");
      }
      this.m_combatKnown = true;
    }
    return this.m_inCombat;
  }

  private func Now() -> Float {
    if !IsDefined(this.m_state) {
      return 0.00;
    }
    return EngineTime.ToFloat(GameInstance.GetEngineTime(this.m_state.GetGame()));
  }
}
