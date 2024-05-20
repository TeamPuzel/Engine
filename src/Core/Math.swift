
import Builtin

// MARK: - Trigonometry

public protocol FloatingPointMath: FloatingPoint, Fractional, ExpressibleByFloatLiteral {
    var sin: Self { get }
    var cos: Self { get }
    var tan: Self { get }
    var sqrt: Self { get }
}

public extension FloatingPointMath {
    func clamped(to range: ClosedRange<Self>) -> Self { max(range.lowerBound, min(self, range.upperBound)) }
    mutating func clamp(to range: ClosedRange<Self>) { self = self.clamped(to: range) }
}

extension Float32: FloatingPointMath {
    @_transparent
    public var sin: Self { Self(Builtin.int_sin_FPIEEE32(self._value)) }
    @_transparent
    public var cos: Self { Self(Builtin.int_cos_FPIEEE32(self._value)) }
    @_transparent
    public var sqrt: Self { Self(Builtin.int_sqrt_FPIEEE32(self._value)) }
    
    #if arch(x86_64)
    @_transparent
    public var tan: Self { Self(Builtin.int_tan_FPIEEE32(self._value)) }
    #else
    @_transparent
    public var tan: Self { self.sin / self.cos }
    #endif
}

extension Float64: FloatingPointMath {
    @_transparent
    public var sin: Self { Self(Builtin.int_sin_FPIEEE64(self._value)) }
    @_transparent
    public var cos: Self { Self(Builtin.int_cos_FPIEEE64(self._value)) }
    @_transparent
    public var sqrt: Self { Self(Builtin.int_sqrt_FPIEEE64(self._value)) }
    
    #if arch(x86_64)
    @_transparent
    public var tan: Self { Self(Builtin.int_tan_FPIEEE64(self._value)) }
    #else
    @_transparent
    public var tan: Self { self.sin / self.cos }
    #endif
}

// MARK: - Normalization

public extension BinaryInteger {
    // NOTE: Had to split up into subexpressions, these compiled in 0.5s each...
    func normalized(from: ClosedRange<Self>, to: ClosedRange<Self>) -> Self {
        let step1 = (to.upperBound - to.lowerBound) / (from.upperBound - from.lowerBound)
        let step2 = step1 * (self - from.upperBound)
        return step2 + to.upperBound
    }
}

public extension FloatingPoint {
    func normalized(from: ClosedRange<Self>, to: ClosedRange<Self>) -> Self {
        (to.upperBound - to.lowerBound) / (from.upperBound - from.lowerBound) * (self - from.upperBound) + to.upperBound
    }
}

// MARK: - Division

/// A type which supports division arithmetic but not necessarily able to represent fractional values.
///
/// For a numeric type which can express division see `Fractional`.
public protocol DivisionArithmetic {
    static func / (lhs: Self, rhs: Self) -> Self
}

/// A numeric type which can represent fractional values and supports division arithmetic.
public protocol Fractional: DivisionArithmetic, Numeric {}

extension Float16: Fractional {}
extension Float32: Fractional {}
extension Float64: Fractional {}

extension Int8: DivisionArithmetic {}
extension Int16: DivisionArithmetic {}
extension Int32: DivisionArithmetic {}
extension Int64: DivisionArithmetic {}

extension UInt8: DivisionArithmetic {}
extension UInt16: DivisionArithmetic {}
extension UInt32: DivisionArithmetic {}
extension UInt64: DivisionArithmetic {}

// MARK: - Collection

public extension Sequence {
    func reduce<Result>(into initial: Result, using operation: (Element, Result) throws -> Result) rethrows -> Result {
        var accumulator = initial
        try self.forEach { element in accumulator = try operation(element, accumulator) }
        return accumulator
    }
}

public extension Sequence where Element: FloatingPointMath {
    /// Returns the average of all the numbers in the sequence.
    func average() -> Element {
        var count = 0
        let sum = self.reduce(into: Element.zero) { acc, el in acc += el; count += 1 }
        return sum / Element(count)
    }
}

public extension Sequence where Element: AdditiveArithmetic {
    /// Returns the sum of elements in the sequence.
    func sum() -> Element { self.reduce(into: Element.zero) { acc, el in acc += el } }
}

public extension Collection where Element: FloatingPointMath {
    /// Returns the average of all the numbers in the collection.
    func average() -> Element { self.sum() / Element(self.count) }
}

// MARK: - Vector

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

// MARK: - Tris

public typealias Tri<T: FloatingPointMath> = (Vector3<T>, Vector3<T>, Vector3<T>)

public func triCompare<T: FloatingPointMath>(_ lhs: Tri<T>, _ rhs: Tri<T>, to position: Vector3<T>) -> Bool {
    triDistance(of: lhs, to: position) > triDistance(of: rhs, to: position)
}

public func triDistance<T: FloatingPointMath>(of tri: Tri<T>, to position: Vector3<T>) -> T {
    let average = (tri.0 + tri.1 + tri.2) / .init(x: 3, y: 3, z: 3)
    return (average - position).reduce(+).sqrt
}

// MARK: - Matrices

public struct Matrix4x4<T: FloatingPointMath> {
    public typealias Storage = ((T, T, T, T), (T, T, T, T), (T, T, T, T), (T, T, T, T))
    public let data: Storage
    
    public init(_ tuple: Storage) { self.data = tuple }
    
    public static func * (lhs: Self, rhs: Self) -> Self {
        let l1 = Vector4(x: lhs.data.0.0, y: lhs.data.0.1, z: lhs.data.0.2, w: lhs.data.0.3)
        let l2 = Vector4(x: lhs.data.1.0, y: lhs.data.1.1, z: lhs.data.1.2, w: lhs.data.1.3)
        let l3 = Vector4(x: lhs.data.2.0, y: lhs.data.2.1, z: lhs.data.2.2, w: lhs.data.2.3)
        let l4 = Vector4(x: lhs.data.3.0, y: lhs.data.3.1, z: lhs.data.3.2, w: lhs.data.3.3)
        
        let r1 = Vector4(x: rhs.data.0.0, y: rhs.data.1.0, z: rhs.data.2.0, w: rhs.data.3.0)
        let r2 = Vector4(x: rhs.data.0.1, y: rhs.data.1.1, z: rhs.data.2.1, w: rhs.data.3.1)
        let r3 = Vector4(x: rhs.data.0.2, y: rhs.data.1.2, z: rhs.data.2.2, w: rhs.data.3.2)
        let r4 = Vector4(x: rhs.data.0.3, y: rhs.data.1.3, z: rhs.data.2.3, w: rhs.data.3.3)
        
        return .init((
            (l1 ** r1, l1 ** r2, l1 ** r3, l1 ** r4),
            (l2 ** r1, l2 ** r2, l2 ** r3, l2 ** r4),
            (l3 ** r1, l3 ** r2, l3 ** r3, l3 ** r4),
            (l4 ** r1, l4 ** r2, l4 ** r3, l4 ** r4)
        ))
    }
    
    public static var identity: Self {
        .init((
            (1, 0, 0, 0),
            (0, 1, 0, 0),
            (0, 0, 1, 0),
            (0, 0, 0, 1)
        ))
    }
    
    public static func translation(x: T, y: T, z: T) -> Self {
        .init((
            (1, 0, 0, 0),
            (0, 1, 0, 0),
            (0, 0, 1, 0),
            (x, y, z, 1)
        ))
    }
    
    public static func scaling(x: T, y: T, z: T) -> Self {
        .init((
            (x, 0, 0, 0),
            (0, y, 0, 0),
            (0, 0, z, 0),
            (0, 0, 0, 1)
        ))
    }
    
    public static func rotation(axis: MatrixRotationAxis, angle: T) -> Self {
        let a = degreesToRadians(angle)
        return switch axis {
            case .pitch:
                .init((
                    (1, 0, 0, 0),
                    (0, a.cos, -a.sin, 0),
                    (0, a.sin, a.cos, 0),
                    (0, 0, 0, 1)
                ))
            case .yaw:
                .init((
                    (a.cos, 0, a.sin, 0),
                    (0, 1, 0, 0),
                    (-a.sin, 0, a.cos, 0),
                    (0, 0, 0, 1)
                ))
            case .roll:
                .init((
                    (a.cos, -a.sin, 0, 0),
                    (a.sin, a.cos, 0, 0),
                    (0, 0, 1, 0),
                    (0, 0, 0, 1)
                ))
        }
    }
    
    public static func projection(width: T, height: T, fov: T, near: T, far: T) -> Self {
        let aspect = height / width
        let q = far / (far - near)
        let f = 1 / (degreesToRadians(fov) / 2).tan
        return .init((
            (aspect * f, 0, 0, 0),
            (0, f, 0, 0),
            (0, 0, q, 1),
            (0, 0, -near * q, 0)
        ))
    }
    
    public func translated(x: T, y: T, z: T) -> Self { self * .translation(x: x, y: y, z: z) }
    
    public func scaled(x: T, y: T, z: T) -> Self { self * .scaling(x: x, y: y, z: z) }
    
    public func rotated(axis: MatrixRotationAxis, angle: T) -> Self {
        self * .rotation(axis: axis, angle: angle)
    }
    
    public func projected(width: T, height: T, fov: T, near: T, far: T) -> Self {
        self * .projection(width: width, height: height, fov: fov, near: near, far: far)
    }
}

public enum MatrixRotationAxis { case pitch, yaw, roll }

extension Matrix4x4: Sendable where T: Sendable {}

extension Matrix4x4: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        withUnsafeBytes(of: lhs.data) { lhsPtr in
            withUnsafeBytes(of: rhs.data) { rhsPtr in
                for offset in 0..<(4 * 4) {
                    if lhsPtr[offset] != rhsPtr[offset] { return false }
                }
                return true
            }
        }
    }
}

public func degreesToRadians<T: FloatingPoint>(_ value: T) -> T { value * T.pi / 180 }

// MARK: - Noise

public struct PerlinNoise: InfiniteDrawable {
    public subscript(x: Int, y: Int) -> Color {
        fatalError()
    }
}
