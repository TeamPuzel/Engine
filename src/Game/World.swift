
final class World {
    private(set) var floors: [Floor] = []
    private var player: Entity!
    private var log: [String] = []
    
    init() {
        for level in 0...5 {
            floors.append(Floor(world: self, level: level))
        }
        
        let firstFloor = self.floors.first!
        let ((x, y), _) = firstFloor.blocks.first { (_, block) in
            (block as? Stairs)?.direction == .up
        }!
        
        let player = Human(firstFloor, x: x, y: y, name: "Lua")
        self.player = player
        self.floors.first!.addEntity(player)
        
        log.append(contentsOf: """
        You are \(player.name ?? "an anonymous adventurer"), a \(type(of: player)) Rogue \
        who set out
        to retrieve a spell of immortality rumored to be
        hidden deep within this dungeon. After sacrificing
        everything you had to get here there is no going back,
        you either succeed or never see the sun again.
        """.split(separator: "\n").map { String($0) })
    }
    
    func tick(input: Input) {
        self.player.process(input: input)
        
        for entity in player.floor!.entities {
            _ = entity
        }
    }
    
    func draw(to renderer: Renderer) {
        self.player.floor!.draw(to: renderer)
        
        renderer.put("\(player.name ?? "Anonymous"), \(type(of: player!))", x: 0, y: 32)
        renderer.put("Floor: \(-1 - self.player.floor!.level)", x: 0, y: 33)
        
        for (index, message) in log[max(0, log.count - 32)...].enumerated() {
            renderer.put(message, x: 33, y: index)
        }
    }
    
    func useStairs(on entity: Entity, direction: Stairs.Direction) {
        let level = entity.floor!.level
        let newLevel = direction == .up ? level - 1 : level + 1
        guard newLevel >= 0 else { log.append("You may not leave empty handed."); return }
        
        log.append("You take the staircase \(direction == .up ? "up" : "down") to floor \(-newLevel - 1).")
        
        entity.floor!.removeEntity(entity)
        
        let newFloor = self.floors[newLevel]
        let ((x, y), _) = newFloor.blocks.first { (_, block) in
            (block as? Stairs)?.direction == direction.opposite
        }!
        entity.position = .init(x: x, y: y)
        newFloor.addEntity(entity)
    }
}
