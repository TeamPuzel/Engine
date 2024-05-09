
public class Entity {
    public final unowned var plane: Plane!
    
    public final var position: Position
    
    public init(x: Int = 0, y: Int = 0, z: Int = 0) {
        self.position = .init(x: x, y: y, z: z)
    }
    
    public struct Position: Hashable, AdditiveArithmetic {
        public var x, y, z: Int
        
        public init(x: Int, y: Int, z: Int) {
            self.x = x
            self.y = y
            self.z = z
        }
        
        public init() { self = .zero }
        
        public static var zero: Self { .init(x: 0, y: 0, z: 0) }
        
        public static func + (lhs: Self, rhs: Self) -> Self {
            .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
        }
        
        public static func - (lhs: Self, rhs: Self) -> Self {
            .init(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
        }
    }
}

extension Entity: Hashable {
    public static func == (lhs: Entity, rhs: Entity) -> Bool { lhs === rhs }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}

extension Entity {
    public class Human: Entity {
        
    }
}
