
public class Entity {
    public var position: Position
    public var orientation: Orientation
    
    public init(x: Float, y: Float, z: Float, orientation: Orientation = .init()) {
        self.position = .init(x: x, y: y, z: z)
        self.orientation = orientation
    }
    
    public func primaryUpdate(input: Input) {
        self.orientation.yaw += 0.1
    }
    
    public typealias Position = Vector3<Float>
    
    /// A specialized vector of floats with wrapping behavior.
    public struct Orientation: Hashable {
        public var pitch, yaw, roll: Float
        
        public static var zero: Self { .init(pitch: 0, yaw: 0, roll: 0) }
        
        public init(pitch: Float = 0, yaw: Float = 0, roll: Float = 0) {
            self.pitch = pitch; self.yaw = yaw; self.roll = roll
        }
    }
    
    public class Human: Entity {
        
    }
}

extension Entity: Hashable {
    public static func == (lhs: Entity, rhs: Entity) -> Bool { lhs === rhs }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}
