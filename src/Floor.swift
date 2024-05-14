
public class Floor {
    public unowned let world: World
    public private(set) var entities: Set<Entity> = []
    
    public init(world: World) {
        self.world = world
    }
    
    public subscript(x: Int, y: Int, z: Int) -> Block {
        get { fatalError() }
        set { fatalError() }
    }
    
    public final func add(entity: Entity) {
        entity.floor = self
        entities.insert(entity)
    }
    
    public final func remove(entity: Entity) {
        entity.floor = nil
        guard entities.remove(entity) != nil else { return }
    }
    
    public class Empty: Floor {
        
    }
}
