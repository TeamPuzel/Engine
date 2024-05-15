
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

extension Vector3: Equatable where T: Equatable {}
extension Vector3: Hashable where T: Hashable {}
extension Vector3: Encodable where T: Encodable {}
extension Vector3: Decodable where T: Decodable {}

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
