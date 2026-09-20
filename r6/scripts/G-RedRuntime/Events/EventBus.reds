module GRedRuntime

public class RuntimeEvent extends IScriptable {
  public let topic: CName;
  public let name: CName;
  public let boolValue: Bool;
  public let intValue: Int32;
  public let floatValue: Float;
  public let nameValue: CName;
  public let entityID: EntityID;

  public static func Create(topic: CName, name: CName) -> ref<RuntimeEvent> {
    let evt = new RuntimeEvent();
    evt.topic = topic;
    evt.name = name;
    return evt;
  }
}

public class EventListener extends IScriptable {
  public func OnGRedEvent(evt: ref<RuntimeEvent>) -> Void {}
}

public class EventSubscription extends IScriptable {
  public let id: Int32;
  public let topic: CName;
  public let listener: ref<EventListener>;
  public let active: Bool;
}

public class EventBus extends IScriptable {
  private let m_subscriptions: array<ref<EventSubscription>>;
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

  public func Subscribe(topic: CName, listener: ref<EventListener>) -> Int32 {
    if !IsDefined(listener) {
      return 0;
    }

    let sub = new EventSubscription();
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

  public func HasSubscribers() -> Bool {
    return this.m_activeCount > 0;
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

  public func Publish(evt: ref<RuntimeEvent>) -> Void {
    if !IsDefined(evt) || this.m_activeCount <= 0 {
      return;
    }

    if IsDefined(this.m_diagnostics) {
      this.m_diagnostics.EventPublish();
    }

    let i: Int32 = 0;
    let count = ArraySize(this.m_subscriptions);
    while i < count {
      let sub = this.m_subscriptions[i];
      if sub.active && IsDefined(sub.listener) && (Equals(sub.topic, evt.topic) || Equals(sub.topic, n"*")) {
        sub.listener.OnGRedEvent(evt);
        if IsDefined(this.m_diagnostics) {
          this.m_diagnostics.EventDelivery();
        }
      }
      i += 1;
    }
  }
}
