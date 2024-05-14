
public struct Matrix<T: FloatingPoint> {
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
}
