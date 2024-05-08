
import Assets

public class Entity {
    public final unowned var floor: Floor
    
    public static let sheet = UnsafeTGAPointer(SHEET_TGA_PTR)
        .flatten()
        .grid(itemWidth: 16, itemHeight: 16)
    
    public class var baseHealth: Int { 1 }
    public class var isFlammable: Bool { false }
    public class var isMovable: Bool { false }
    public var isMovable: Bool { Self.isMovable }
    public var isFlammable: Bool { Self.isFlammable }
    
    public final var maxHealth: Int
    public final var health: Int
    
    public final var position: Position
    public final var name: String?
    
    public var sprite: any Drawable { EmptyDrawable<RGBA>() }
    
    public final var x: Int { position.x }
    public final var y: Int { position.y }
    
    public init(_ floor: Floor, x: Int = 0, y: Int = 0, name: String? = nil) {
        self.name = name
        self.floor = floor
        self.position = .init(x: x, y: y)
        self.maxHealth = Self.baseHealth
        self.health = Self.baseHealth
    }
    
    private func log(_ string: String) {
        if self === floor.world.player { floor.world.log(string) }
    }
    
    public func move(_ direction: Direction) {
        guard Self.isMovable else { log("You are immovable and don't even budge."); return }
        
        let newPosition = position + direction.relativePosition
        
        guard
            newPosition.x >= 0 &&
            newPosition.y >= 0 &&
            newPosition.x < Floor.size &&
            newPosition.y < Floor.size
        else { log("You can't move there."); return }
        
        let destinationBlock = floor[newPosition.x, newPosition.y]
        
        guard !destinationBlock.isSolid else {
            log("The \(String(describing: type(of: destinationBlock)).lowercased()) doesn't budge.")
            return
        }
        
        position = newPosition
    }
    
    public func useStairs(_ direction: Block.Stairs.Direction) {
        floor.world.useStairs(on: self, direction: direction)
    }
    
    public func process(input: Input) {
//        switch input {
//            case : self.move(.north)
//            case .down: self.move(.south)
//            case .left: self.move(.west)
//            case .right: self.move(.east)
//                
//            case .other("<") where (floor[x, y] as? Block.Stairs)?.direction == .up: useStairs(.up)
//            case .other(">") where (floor[x, y] as? Block.Stairs)?.direction == .down: useStairs(.down)
//            
//            case _: break
//        }
    }
    
    public struct Position: Hashable, AdditiveArithmetic {
        public var x, y: Int
        
        public init(x: Int, y: Int) {
            self.x = x
            self.y = y
        }
        
        public init() { self = .zero }
        
        public static var zero: Self { .init(x: 0, y: 0) }
        
        public static func + (lhs: Self, rhs: Self) -> Self {
            .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
        }
        
        public static func - (lhs: Self, rhs: Self) -> Self {
            .init(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
        }
    }
    
    public enum Direction {
        case north, south, east, west, northEast, northWest, southEast, southWest
        
        public var relativePosition: Position {
            switch self {
                case .north:     .init(x: 0, y: -1)
                case .south:     .init(x: 0, y: 1)
                case .east:      .init(x: 1, y: 0)
                case .west:      .init(x: -1, y: 0)
                case .northEast: .init(x: 1, y: -1)
                case .northWest: .init(x: -1, y: -1)
                case .southEast: .init(x: 1, y: 1)
                case .southWest: .init(x: -1, y: 1)
            }
        }
    }
}

extension Entity: Hashable {
    public static func == (lhs: Entity, rhs: Entity) -> Bool { lhs === rhs }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}

extension Entity {
    public class Human: Entity {
        public class override var baseHealth: Int { 4 }
        public class override var isMovable: Bool { true }
        public class override var isFlammable: Bool { true }
        
        public override var sprite: any Drawable { Self.sheet[0, 1] }
    }
}
