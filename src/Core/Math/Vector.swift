
infix operator **: MultiplicationPrecedence

// MARK: - Vector2

public struct Vector2<T: Numeric> {
    public var x, y: T
    public init(x: T, y: T) { self.x = x; self.y = y }
}

public extension Vector2 {
    static func + (lhs: Self, rhs: Self) -> Self {
        .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func - (lhs: Self, rhs: Self) -> Self {
        .init(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    static func * (lhs: Self, rhs: Self) -> Self {
        .init(x: lhs.x * rhs.x, y: lhs.y * rhs.y)
    }
    
    static func ** (lhs: Self, rhs: Self) -> T {
        (lhs.x * rhs.x) + (lhs.y * rhs.y)
    }
}

public extension Vector2 where T: Fractional {
    static func / (lhs: Self, rhs: Self) -> Self {
        .init(x: lhs.x / rhs.x, y: lhs.y / rhs.y)
    }
}

public extension Vector2 where T: AdditiveArithmetic {
    static var zero: Self { .init(x: .zero, y: .zero) }
}

extension Vector2: Equatable where T: Equatable {}
extension Vector2: Hashable where T: Hashable {}
extension Vector2: Encodable where T: Encodable {}
extension Vector2: Decodable where T: Decodable {}
extension Vector2: Sendable where T: Sendable {}

// MARK: - Vector3

public struct Vector3<T: Numeric> {
    public var x, y, z: T
    public init(x: T, y: T, z: T) { self.x = x; self.y = y; self.z = z }
}

public extension Vector3 {
    static func + (lhs: Self, rhs: Self) -> Self {
        .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }
    
    static func - (lhs: Self, rhs: Self) -> Self {
        .init(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }
    
    static func * (lhs: Self, rhs: Self) -> Self {
        .init(x: lhs.x * rhs.x, y: lhs.y * rhs.y, z: lhs.z * rhs.z)
    }
    
    static func ** (lhs: Self, rhs: Self) -> T {
        (lhs.x * rhs.x) + (lhs.y * rhs.y) + (lhs.z * rhs.z)
    }
}

public extension Vector3 where T: Fractional {
    static func / (lhs: Self, rhs: Self) -> Self {
        .init(x: lhs.x / rhs.x, y: lhs.y / rhs.y, z: lhs.z / rhs.z)
    }
}

public extension Vector3 where T: AdditiveArithmetic {
    static var zero: Self { .init(x: .zero, y: .zero, z: .zero) }
}

public extension Vector3 {
    func reduce(_ op: (T, T) -> T) -> T { op(op(x, y), z) }
    
//    func distance(to other: Self) -> T {
//
//    }
}

extension Vector3: Equatable where T: Equatable {}
extension Vector3: Hashable where T: Hashable {}
extension Vector3: Encodable where T: Encodable {}
extension Vector3: Decodable where T: Decodable {}
extension Vector3: Sendable where T: Sendable {}

// MARK: - Vector4

public struct Vector4<T: Numeric> {
    public var x, y, z, w: T
    public init(x: T, y: T, z: T, w: T) { self.x = x; self.y = y; self.z = z; self.w = w }
}

public extension Vector4 {
    static func + (lhs: Self, rhs: Self) -> Self {
        .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z, w: lhs.w + rhs.w)
    }
    
    static func - (lhs: Self, rhs: Self) -> Self {
        .init(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z, w: lhs.w - rhs.w)
    }
    
    static func * (lhs: Self, rhs: Self) -> Self {
        .init(x: lhs.x * rhs.x, y: lhs.y * rhs.y, z: lhs.z * rhs.z, w: lhs.w * rhs.w)
    }
    
    static func ** (lhs: Self, rhs: Self) -> T {
        (lhs.x * rhs.x) + (lhs.y * rhs.y) + (lhs.z * rhs.z) + (lhs.w * rhs.w)
    }
}

public extension Vector4 where T: Fractional {
    static func / (lhs: Self, rhs: Self) -> Self {
        .init(x: lhs.x / rhs.x, y: lhs.y / rhs.y, z: lhs.z / rhs.z, w: lhs.w / rhs.w)
    }
}

public extension Vector4 where T: AdditiveArithmetic {
    static var zero: Self { .init(x: .zero, y: .zero, z: .zero, w: .zero) }
}

extension Vector4: Equatable where T: Equatable {}
extension Vector4: Hashable where T: Hashable {}
extension Vector4: Encodable where T: Encodable {}
extension Vector4: Decodable where T: Decodable {}
extension Vector4: Sendable where T: Sendable {}

// MARK: - Vertices

public typealias Tri<T: FloatingPointMath> = (Vector3<T>, Vector3<T>, Vector3<T>)

public func triCompare<T: FloatingPointMath>(_ lhs: Tri<T>, _ rhs: Tri<T>, to position: Vector3<T>) -> Bool {
    triDistance(of: lhs, to: position) > triDistance(of: rhs, to: position)
}

public func triDistance<T: FloatingPointMath>(of tri: Tri<T>, to position: Vector3<T>) -> T {
    let average = (tri.0 + tri.1 + tri.2) / .init(x: 3, y: 3, z: 3)
    return (average - position).reduce(+).sqrt
}
