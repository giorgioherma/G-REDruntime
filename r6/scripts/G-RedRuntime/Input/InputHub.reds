module GRedRuntime

public class InputEvent extends IScriptable {
  public let actionName: CName;
  public let actionType: gameinputActionType;
}

public class InputListener extends IScriptable {
  public func OnGRedInput(evt: ref<InputEvent>) -> Void {}
}

public class InputSubscription extends IScriptable {
  public let id: Int32;
  public let actionName: CName;
  public let listener: ref<InputListener>;
  public let active: Bool;
}

public class InputBridge extends IScriptable {
  private let m_hub: wref<InputHub>;

  public func Initialize(hub: ref<InputHub>) -> Void {
    this.m_hub = hub;
  }

  protected cb func OnAction(action: ListenerAction, consumer: ListenerActionConsumer) -> Bool {
    if IsDefined(this.m_hub) {
      this.m_hub.Publish(action);
    }
    return false;
  }
}

public class InputHub extends IScriptable {
  private let m_subscriptions: array<ref<InputSubscription>>;
  private let m_nextID: Int32;
  private let m_activeCount: Int32;
  private let m_diagnostics: wref<Diagnostics>;
  private let m_state: wref<StateCache>;
  private let m_bridge: ref<InputBridge>;
  private let m_registeredPlayer: wref<PlayerPuppet>;
  private let m_registered: Bool;

  public func Initialize(state: ref<StateCache>, diagnostics: ref<Diagnostics>) -> Void {
    this.m_state = state;
    this.m_diagnostics = diagnostics;
    this.m_nextID = 1;
    this.m_bridge = new InputBridge();
    this.m_bridge.Initialize(this);
  }

  public func Shutdown() -> Void {
    this.UnregisterBridge();

    let i: Int32 = 0;
    let count = ArraySize(this.m_subscriptions);
    while i < count {
      this.m_subscriptions[i].active = false;
      this.m_subscriptions[i].listener = null;
      i += 1;
    }
    this.m_activeCount = 0;
  }

  public func OnPlayerAvailable(player: wref<PlayerPuppet>) -> Void {
    if this.m_registered && NotEquals(this.m_registeredPlayer, player) {
      this.UnregisterBridge();
    }
    this.m_registeredPlayer = player;
    this.EnsureRegistered();
  }

  public func Subscribe(actionName: CName, listener: ref<InputListener>) -> Int32 {
    if !IsDefined(listener) {
      return 0;
    }

    let sub = new InputSubscription();
    sub.id = this.m_nextID;
    sub.actionName = actionName;
    sub.listener = listener;
    sub.active = true;

    this.m_nextID += 1;
    this.m_activeCount += 1;
    ArrayPush(this.m_subscriptions, sub);
    this.EnsureRegistered();
    return sub.id;
  }

  public func Unsubscribe(id: Int32) -> Bool {
    let i: Int32 = 0;
    let count = ArraySize(this.m_subscriptions);
    while i < count {
      if this.m_subscriptions[i].id == id && this.m_subscriptions[i].active {
        this.m_subscriptions[i].active = false;
        this.m_subscriptions[i].listener = null;
        this.m_activeCount -= 1;
        if this.m_activeCount <= 0 {
          this.UnregisterBridge();
        }
        return true;
      }
      i += 1;
    }
    return false;
  }

  public func HasSubscribers() -> Bool {
    return this.m_activeCount > 0;
  }

  public func Publish(action: ListenerAction) -> Void {
    if this.m_activeCount <= 0 {
      return;
    }

    if IsDefined(this.m_diagnostics) {
      this.m_diagnostics.InputSeen();
    }

    let evt = new InputEvent();
    evt.actionName = ListenerAction.GetName(action);
    evt.actionType = ListenerAction.GetType(action);

    let i: Int32 = 0;
    let count = ArraySize(this.m_subscriptions);
    while i < count {
      let sub = this.m_subscriptions[i];
      if sub.active && IsDefined(sub.listener) && (Equals(sub.actionName, n"") || Equals(sub.actionName, evt.actionName)) {
        sub.listener.OnGRedInput(evt);
        if IsDefined(this.m_diagnostics) {
          this.m_diagnostics.InputDelivery();
        }
      }
      i += 1;
    }
  }

  private func EnsureRegistered() -> Void {
    if this.m_registered || this.m_activeCount <= 0 || !IsDefined(this.m_bridge) {
      return;
    }

    let player = this.m_registeredPlayer;
    if !IsDefined(player) && IsDefined(this.m_state) {
      player = this.m_state.GetPlayer();
    }

    if !IsDefined(player) {
      return;
    }

    player.RegisterInputListener(this.m_bridge);
    this.m_registeredPlayer = player;
    this.m_registered = true;
  }

  private func UnregisterBridge() -> Void {
    if this.m_registered && IsDefined(this.m_registeredPlayer) && IsDefined(this.m_bridge) {
      this.m_registeredPlayer.UnregisterInputListener(this.m_bridge);
    }
    this.m_registered = false;
    this.m_registeredPlayer = null;
  }
}
