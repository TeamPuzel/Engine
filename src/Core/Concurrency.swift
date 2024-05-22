
import Builtin

// MARK: - Atomic

public struct Atomic<T: AtomicValue> {
    private var inner: T
    public init(_ inner: T) { self.inner = inner }
    
    public var value: T {
        get { inner.atomicLoad() }
        set { inner.atomicStore(newValue) }
    }
}

public protocol AtomicValue {
    func atomicLoad() -> Self
    mutating func atomicStore(_ newValue: Self)
}

extension Bool: AtomicValue {
    public func atomicLoad() -> Bool {
        fatalError()
//        Builtin.atomicrmw_xchg_seqcst_Int1
    }
    public mutating func atomicStore(_ newValue: Bool) {
        fatalError()
    }
}
