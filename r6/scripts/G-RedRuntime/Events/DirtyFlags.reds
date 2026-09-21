module GRedRuntime

public class DirtyFlagEntry extends IScriptable {
  public let name: CName;
  public let dirty: Bool;
  public let version: Uint32;
}

public class DirtyFlags extends IScriptable {
  private let m_flags: array<ref<DirtyFlagEntry>>;

  public func Mark(name: CName) -> Uint32 {
    let i: Int32 = 0;
    let count = ArraySize(this.m_flags);

    while i < count {
      if Equals(this.m_flags[i].name, name) {
        this.m_flags[i].dirty = true;
        this.m_flags[i].version += 1u;
        return this.m_flags[i].version;
      }
      i += 1;
    }

    let entry = new DirtyFlagEntry();
    entry.name = name;
    entry.dirty = true;
    entry.version = 1u;
    ArrayPush(this.m_flags, entry);
    return entry.version;
  }

  public func IsDirty(name: CName) -> Bool {
    let i: Int32 = 0;
    let count = ArraySize(this.m_flags);

    while i < count {
      if Equals(this.m_flags[i].name, name) {
        return this.m_flags[i].dirty;
      }
      i += 1;
    }

    return false;
  }

  public func Consume(name: CName) -> Bool {
    let i: Int32 = 0;
    let count = ArraySize(this.m_flags);

    while i < count {
      if Equals(this.m_flags[i].name, name) {
        if this.m_flags[i].dirty {
          this.m_flags[i].dirty = false;
          return true;
        }
        return false;
      }
      i += 1;
    }

    return false;
  }

  public func ChangedSince(name: CName, lastSeenVersion: Uint32) -> Bool {
    return this.Version(name) != lastSeenVersion;
  }

  public func Version(name: CName) -> Uint32 {
    let i: Int32 = 0;
    let count = ArraySize(this.m_flags);

    while i < count {
      if Equals(this.m_flags[i].name, name) {
        return this.m_flags[i].version;
      }
      i += 1;
    }

    return 0u;
  }

  public func ClearAll() -> Void {
    let i: Int32 = 0;
    let count = ArraySize(this.m_flags);
    while i < count {
      this.m_flags[i].dirty = false;
      i += 1;
    }
  }
}
