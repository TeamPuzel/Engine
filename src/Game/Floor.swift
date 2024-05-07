
public class Floor {
    public final unowned let world: World
    
    public static var size: Int = 32
    
    private final var blockStorage: [Block]
    
    public private(set) var entities: Set<Entity> = []
    public final let level: Int

    public init(world: World, level: Int) {
        self.world = world
        self.level = level
        self.blockStorage = .init(repeating: Block.Air(), count: Self.size * Self.size)
    }
    
    private final func addStairs(_ direction: Block.Stairs.Direction) throws(GenerationError) {
        let blocks = self.blocks.filter { (_, block) in block is Block.Ground }
        guard let ((x, y), _) = blocks.randomElement() else {
            throw GenerationError.noSpaceFor(block: Block.Stairs(direction))
        }
        self[x, y] = Block.Stairs(direction)
    }
    
    private enum GenerationError: Error {
        case noSpaceFor(block: Block)
    }
    
    public final subscript(x: Int, y: Int) -> Block {
        get { blockStorage[x + y * Self.size] }
        set { blockStorage[x + y * Self.size] = newValue }
    }
    
    public final var blocks: Zip2Sequence<[(x: Int, y: Int)], [Block]> {
        var indices: [(x: Int, y: Int)] = []
        indices.reserveCapacity(Self.size * Self.size)
        
        for x in 0..<Self.size {
            for y in 0..<Self.size {
                indices.append((y, x))
            }
        }
        
        return zip(indices, blockStorage)
    }
    
    public final func addEntity(_ entity: Entity) {
        entity.floor = self
        self.entities.insert(entity)
    }
    
    public final func removeEntity(_ entity: Entity) {
        guard entities.remove(entity) != nil else { return }
    }
    
    public final func draw(to renderer: Renderer) {
        for x in 0..<Self.size {
            for y in 0..<Self.size {
                if let symbol = self[x, y].symbol { renderer.put(symbol, x: x, y: y) }
            }
        }
        
        for entity in self.entities {
            if let symbol = entity.symbol { renderer.put(symbol, x: entity.x, y: entity.y) }
        }
    }
    
    public final class Empty: Floor {
        public override init(world: World, level: Int) {
            super.init(world: world, level: level)
            self.blockStorage = .init(repeating: Block.Ground(), count: Self.size * Self.size)
            
            self[3, 3] = Block.Wall()
            
            while true {
                if (try? self.addStairs(.up)) != nil { break }
            }
            
            while true {
                if (try? self.addStairs(.down)) != nil { break }
            }
        }
    }
}
