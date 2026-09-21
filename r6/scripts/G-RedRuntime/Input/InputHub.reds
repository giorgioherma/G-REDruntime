module GRedRuntime

public class InputEvent extends IScriptable {
  public let actionName: CName;
  public let actionType: gameinputActionType;
  public let consumed: Bool;
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
      return this.m_hub.Publish(action);
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
  private let m_registeredActions: array<CName>;
  private let m_registered: Bool;
  private let m_registeredGlobal: Bool;

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
    this.RefreshRegistration();
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
    this.RefreshRegistration();
    return sub.id;
  }

  public func SubscribeAll(listener: ref<InputListener>) -> Int32 {
    return this.Subscribe(n"*", listener);
  }

  public func Unsubscribe(id: Int32) -> Bool {
    let i: Int32 = 0;
    let count = ArraySize(this.m_subscriptions);
    while i < count {
      if this.m_subscriptions[i].id == id && this.m_subscriptions[i].active {
        this.m_subscriptions[i].active = false;
        this.m_subscriptions[i].listener = null;
        this.m_activeCount -= 1;
        this.RefreshRegistration();
        return true;
      }
      i += 1;
    }
    return false;
  }

  public func HasSubscribers() -> Bool {
    return this.m_activeCount > 0;
  }

  public func HasSubscribersFor(actionName: CName) -> Bool {
    if this.m_activeCount <= 0 {
      return false;
    }

    let i: Int32 = 0;
    let count = ArraySize(this.m_subscriptions);
    while i < count {
      let sub = this.m_subscriptions[i];
      if sub.active && (this.IsWildcard(sub.actionName) || Equals(sub.actionName, actionName)) {
        return true;
      }
      i += 1;
    }
    return false;
  }

  public func Publish(action: ListenerAction) -> Bool {
    if this.m_activeCount <= 0 {
      return false;
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
      if sub.active && IsDefined(sub.listener) && (this.IsWildcard(sub.actionName) || Equals(sub.actionName, evt.actionName)) {
        sub.listener.OnGRedInput(evt);
        if IsDefined(this.m_diagnostics) {
          this.m_diagnostics.InputDelivery();
        }
      }
      i += 1;
    }

    return evt.consumed;
  }

  private func RefreshRegistration() -> Void {
    let player = this.m_registeredPlayer;
    if !IsDefined(player) && IsDefined(this.m_state) {
      player = this.m_state.GetPlayer();
    }

    if !IsDefined(player) || this.m_activeCount <= 0 || !IsDefined(this.m_bridge) {
      this.UnregisterBridge();
      return;
    }

    if this.m_registered && this.m_registeredGlobal && Equals(this.m_registeredPlayer, player) && this.HasWildcardSubscriber() {
      return;
    }

    this.UnregisterBridge();
    this.m_registeredPlayer = player;

    if this.HasWildcardSubscriber() {
      player.RegisterInputListener(this.m_bridge);
      this.m_registered = true;
      this.m_registeredGlobal = true;
      return;
    }

    let i: Int32 = 0;
    let count = ArraySize(this.m_subscriptions);
    while i < count {
      let sub = this.m_subscriptions[i];
      if sub.active && !this.IsWildcard(sub.actionName) && !this.IsRegisteredAction(sub.actionName) {
        player.RegisterInputListener(this.m_bridge, sub.actionName);
        ArrayPush(this.m_registeredActions, sub.actionName);
      }
      i += 1;
    }

    this.m_registered = ArraySize(this.m_registeredActions) > 0;
    this.m_registeredGlobal = false;
  }

  private func HasWildcardSubscriber() -> Bool {
    let i: Int32 = 0;
    let count = ArraySize(this.m_subscriptions);
    while i < count {
      let sub = this.m_subscriptions[i];
      if sub.active && this.IsWildcard(sub.actionName) {
        return true;
      }
      i += 1;
    }
    return false;
  }

  private func IsRegisteredAction(actionName: CName) -> Bool {
    let i: Int32 = 0;
    let count = ArraySize(this.m_registeredActions);
    while i < count {
      if Equals(this.m_registeredActions[i], actionName) {
        return true;
      }
      i += 1;
    }
    return false;
  }

  private func IsWildcard(actionName: CName) -> Bool {
    return Equals(actionName, n"") || Equals(actionName, n"*");
  }

  private func UnregisterBridge() -> Void {
    if this.m_registered && IsDefined(this.m_registeredPlayer) && IsDefined(this.m_bridge) {
      if this.m_registeredGlobal {
        this.m_registeredPlayer.UnregisterInputListener(this.m_bridge);
      } else {
        let i: Int32 = 0;
        let count = ArraySize(this.m_registeredActions);
        while i < count {
          this.m_registeredPlayer.UnregisterInputListener(this.m_bridge, this.m_registeredActions[i]);
          i += 1;
        }
      }
    }

    this.m_registered = false;
    this.m_registeredGlobal = false;
    ArrayClear(this.m_registeredActions);
    this.m_registeredPlayer = null;
  }
}
