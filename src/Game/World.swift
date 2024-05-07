
public final class World {
    public private(set) var floors: [Floor] = []
    public private(set) var player: Entity!
    public private(set) var turn: Int = 0
    private var log: Log = .init()
    
    public init() {
        for level in 0...14 {
            switch level {
                case 0...14: floors.append(Floor.Empty(world: self, level: level))
                case _: fatalError()
            }
        }
        
        let firstFloor = floors.first!
        let ((x, y), _) = firstFloor.blocks.first { (_, block) in
            (block as? Block.Stairs)?.direction == .up
        }!
        
        let player = Entity.Human(firstFloor, x: x, y: y, name: "Lua")
        self.player = player
        floors.first!.addEntity(player)
    }
    
    public func log(_ string: String) { log.write(turn: turn, string) }
    
    public func tick(input: Input) {
        player.process(input: input)
        
        for entity in player.floor.entities {
            _ = entity
        }
        
        turn += 1
    }
    
    public func draw(to renderer: Renderer) {
        player.floor.draw(to: renderer)
        
        renderer.put("\(player.name ?? "Anonymous"), \(type(of: player!))", x: 0, y: 32)
        renderer.put("Floor: \(-1 - player.floor.level) Health: \(player.health)/\(player.maxHealth)", x: 0, y: 33)
        
        for (index, entry) in log.entries[max(0, log.entries.count - 32)...].enumerated() {
            renderer.put(entry.message, x: 33, y: index)
        }
    }
    
    public func useStairs(on entity: Entity, direction: Block.Stairs.Direction) {
        let level = entity.floor.level
        let newLevel = direction == .up ? level - 1 : level + 1
        guard newLevel >= 0 else { log("You may not leave empty handed."); return }
        
        log("You take the stairs \(direction == .up ? "up" : "down") to floor \(-newLevel - 1).")
        
        entity.floor.removeEntity(entity)
        
        let newFloor = floors[newLevel]
        let ((x, y), _) = newFloor.blocks.first { (_, block) in
            (block as? Block.Stairs)?.direction == direction.opposite
        }!
        entity.position = .init(x: x, y: y)
        newFloor.addEntity(entity)
    }
}

public struct Log {
    public private(set) var entries: [Entry] = []
    public init() {}
    
    public mutating func write(turn: Int, _ message: String) {
        entries.append(.init(turn: turn, message: message))
    }
    
    public struct Entry: CustomStringConvertible {
        public let turn: Int
        public let message: String
        public var description: String { "Turn \(turn): \(message)" }
    }
}
