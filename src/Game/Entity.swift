
class Entity {
    final weak var floor: Floor?
    final var position: Position
    final var name: String?
    var symbol: Character? { nil }
    
    final var x: Int { position.x }
    final var y: Int { position.y }
    
    init(_ floor: Floor, x: Int = 0, y: Int = 0, name: String? = nil) {
        self.name = name
        self.floor = floor
        self.position = .init(x: x, y: y)
    }
    
    func move(_ direction: Direction) {
        self.position += direction.relativePosition
    }
    
    func useStairs(_ direction: Stairs.Direction) {
        self.floor!.world!.useStairs(on: self, direction: direction)
    }
    
    func process(input string: Input) {
        switch string {
            case .up: self.move(.north)
            case .down: self.move(.south)
            case .left: self.move(.west)
            case .right: self.move(.east)
                
            case .other("<") where (floor![x, y] as? Stairs)?.direction == .up: self.useStairs(.up)
            case .other(">") where (floor![x, y] as? Stairs)?.direction == .down: self.useStairs(.down)
            
            case _: break
        }
    }
    
    struct Position: Hashable, AdditiveArithmetic {
        var x, y: Int
        
        init(x: Int, y: Int) {
            self.x = x
            self.y = y
        }
        
        init() { self = .zero }
        
        static var zero: Self { .init(x: 0, y: 0) }
        
        static func + (lhs: Self, rhs: Self) -> Self {
            .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
        }
        
        static func - (lhs: Self, rhs: Self) -> Self {
            .init(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
        }
    }
    
    enum Direction {
        case north, south, east, west, northEast, northWest, southEast, southWest
        
        var relativePosition: Position {
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
    static func == (lhs: Entity, rhs: Entity) -> Bool { lhs === rhs }
    func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}

class Human: Entity {
    override var symbol: Character? { "@" }
}
