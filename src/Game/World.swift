
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
    private var primaryEntity: Entity!
    
    public init(name: String, seed: UInt64 = .random(in: 1...UInt64.max)) {
        self.name = name
        self.seed = seed
        
        for x in -16...16 {
            for y in -16...16 {
                chunks[.init(x: x, y: y)] = Chunk(self, x: x, y: y)
            }
        }
        
        for (_, chunk) in chunks { chunk.generate() }
        
        let player = Entity.Human(x: 0, y: 130, z: 0)
        entities.insert(player)
        primaryEntity = player
    }
}
