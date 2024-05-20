
/// Represents the entire world.
///
/// # Distributed
/// This actor will potentially be distributed one day to support multiplayer. Plan accordingly,
/// as all messages will have to implement `Codable` or some other custom serialization system.
public final class World {
    public let name: String
    public let seed: UInt64
    private var chunks: [Chunk.Position: Chunk] = [:]
    private var entities: Set<Entity> = []
    /// The entity currently controlled by the player to which the camera is attached to.
    private var primaryEntity: Entity!
    /// The position relative to which vertices were last sorted. This is used to determine if the
    /// primary entity moved far enough to require sorting vertices again.
    private var sortedAt: Entity.Position = .zero
    
    public init(name: String, seed: UInt64 = .random(in: 1...UInt64.max)) {
        self.name = name
        self.seed = seed
        
        for x in -2...2 {
            for y in -2...2 {
                chunks[.init(x: x, y: y)] = Chunk(self, x: x, y: y)
            }
        }
        
        for (_, chunk) in chunks { chunk.generate() }
        
        let player = Entity.Human(x: 0, y: 130, z: 0)
        entities.insert(player)
        primaryEntity = player
        
        for (_, chunk) in chunks { chunk.remesh(); chunk.resort() }
    }
    
    public func frame(input: Input, renderer: inout Image) {
        primaryEntity!.primaryUpdate(input: input)
    }
    
    public var primaryPosition: Entity.Position { primaryEntity?.position ?? .zero }
    public var primaryOrientation: Entity.Orientation { primaryEntity?.orientation ?? .zero }
    
    public var unifiedMesh: [BlockVertex] {
        chunks.values.reduce(into: []) { acc, el in acc.append(contentsOf: el.mesh)  }
    }
    
    public func primaryMatrix(width: Float, height: Float) -> Matrix<Float> {
        .translation(x: -primaryEntity.position.x, y: -primaryEntity.position.y, z: -primaryEntity.position.z)
            .rotated(axis: .yaw, angle: primaryEntity.orientation.yaw)
            .rotated(axis: .pitch, angle: primaryEntity.orientation.pitch)
            .projected(width: width, height: height, fov: 80, near: 0.1, far: 1000)
    }
}
