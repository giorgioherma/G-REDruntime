module GRedRuntime

public class HookContext extends IScriptable {
  public let topic: CName;
  public let source: CName;
  public let entityID: EntityID;
  public let boolValue: Bool;
  public let intValue: Int32;
  public let floatValue: Float;
  public let nameValue: CName;

  public static func Create(topic: CName, source: CName) -> ref<HookContext> {
    let ctx = new HookContext();
    ctx.topic = topic;
    ctx.source = source;
    return ctx;
  }
}

public class HookListener extends IScriptable {
  public func OnGRedHook(ctx: ref<HookContext>) -> Void {}
}

public class HookSubscription extends IScriptable {
  public let id: Int32;
  public let topic: CName;
  public let listener: ref<HookListener>;
  public let active: Bool;
}

public class HookBus extends IScriptable {
  private let m_subscriptions: array<ref<HookSubscription>>;
  private let m_nextID: Int32;
  private let m_activeCount: Int32;
  private let m_diagnostics: wref<Diagnostics>;

  public func Initialize(diagnostics: ref<Diagnostics>) -> Void {
    this.m_diagnostics = diagnostics;
    this.m_nextID = 1;
  }

  public func Shutdown() -> Void {
    let i: Int32 = 0;
    let count = ArraySize(this.m_subscriptions);
    while i < count {
      this.m_subscriptions[i].active = false;
      this.m_subscriptions[i].listener = null;
      i += 1;
    }
    this.m_activeCount = 0;
  }

  public func Subscribe(topic: CName, listener: ref<HookListener>) -> Int32 {
    if !IsDefined(listener) {
      return 0;
    }

    let sub = new HookSubscription();
    sub.id = this.m_nextID;
    sub.topic = topic;
    sub.listener = listener;
    sub.active = true;
    this.m_nextID += 1;
    this.m_activeCount += 1;
    ArrayPush(this.m_subscriptions, sub);
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
        return true;
      }
      i += 1;
    }
    return false;
  }

  public func HasSubscribersFor(topic: CName) -> Bool {
    if this.m_activeCount <= 0 {
      return false;
    }

    let i: Int32 = 0;
    let count = ArraySize(this.m_subscriptions);
    while i < count {
      let sub = this.m_subscriptions[i];
      if sub.active && (Equals(sub.topic, topic) || Equals(sub.topic, n"*")) {
        return true;
      }
      i += 1;
    }
    return false;
  }

  public func Dispatch(ctx: ref<HookContext>) -> Void {
    if !IsDefined(ctx) || this.m_activeCount <= 0 {
      return;
    }

    if IsDefined(this.m_diagnostics) {
      this.m_diagnostics.HookDispatch();
    }

    let i: Int32 = 0;
    let count = ArraySize(this.m_subscriptions);
    while i < count {
      let sub = this.m_subscriptions[i];
      if sub.active && IsDefined(sub.listener) && (Equals(sub.topic, ctx.topic) || Equals(sub.topic, n"*")) {
        sub.listener.OnGRedHook(ctx);
        if IsDefined(this.m_diagnostics) {
          this.m_diagnostics.HookDelivery();
        }
      }
      i += 1;
    }
  }
}
