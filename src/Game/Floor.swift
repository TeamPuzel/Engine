
final class Floor {
    final weak var world: World?
    
    static var side: Int = 32
    
    private var blockStorage: [Block]
    private(set) var entities: Set<Entity> = []
    final let level: Int

    init(world: World, level: Int) {
        self.world = world
        self.level = level
        
        let roomCount = 6...9
        
        while true {
            do throws(GenerationError) {
                self.blockStorage = .init(repeating: Ground(), count: Self.side * Self.side)
                
                do {
                    let floorBlocks = self.blocks.filter { (_, block) in block is Ground }
                    guard let ((x, y), _) = floorBlocks.randomElement() else {
                        throw GenerationError.noSpaceFor(block: Stairs(.up))
                    }
                    self[x, y] = Stairs(.up)
                }
                
                do {
                    let floorBlocks = self.blocks.filter { (_, block) in block is Ground }
                    guard let ((x, y), _) = floorBlocks.randomElement() else {
                        throw GenerationError.noSpaceFor(block: Stairs(.down))
                    }
                    self[x, y] = Stairs(.down)
                }
            } catch {
                // TODO(!): Log this somewhere
                continue
            }
            
            break
        }
    }
    
    enum GenerationError: Error {
        case noSpaceFor(block: Block)
    }
    
    subscript(x: Int, y: Int) -> Block {
        get { self.blockStorage[x + y * Self.side] }
        set { self.blockStorage[x + y * Self.side] = newValue }
    }
    
    var blocks: Zip2Sequence<[(x: Int, y: Int)], [Block]> {
        var indices: [(x: Int, y: Int)] = []
        indices.reserveCapacity(Self.side * Self.side)
        
        for x in 0..<Self.side {
            for y in 0..<Self.side {
                indices.append((y, x))
            }
        }
        
        return zip(indices, self.blockStorage)
    }
    
    func addEntity(_ entity: Entity) {
        entity.floor = self
        self.entities.insert(entity)
    }
    
    func removeEntity(_ entity: Entity) {
        guard self.entities.remove(entity) != nil else { return }
        entity.floor = nil
    }
    
    func draw(to renderer: Renderer) {
        for x in 0..<Self.side {
            for y in 0..<Self.side {
                if let symbol = self[x, y].symbol { renderer.put(symbol, x: x, y: y) }
            }
        }
        
        for entity in self.entities {
            if let symbol = entity.symbol { renderer.put(symbol, x: entity.x, y: entity.y) }
        }
    }
}
