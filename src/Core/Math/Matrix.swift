
import Builtin

public struct Matrix<T: FloatingPointMath> {
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
}

public enum MatrixRotationAxis { case pitch, yaw, roll }

extension Matrix: Sendable where T: Sendable {}

extension Matrix: Equatable {
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

public protocol FloatingPointMath: FloatingPoint {
    var sin: Self { get }
    var cos: Self { get }
    var tan: Self { get }
}

extension Float32: FloatingPointMath {
    @_transparent
    public var sin: Self { Self(Builtin.int_sin_FPIEEE32(self._value)) }
    @_transparent
    public var cos: Self { Self(Builtin.int_cos_FPIEEE32(self._value)) }
    
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
    #if arch(x86_64)
    @_transparent
    public var tan: Self { Self(Builtin.int_tan_FPIEEE64(self._value)) }
    #else
    @_transparent
    public var tan: Self { self.sin / self.cos }
    #endif
}
