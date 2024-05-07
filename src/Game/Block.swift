
public class Block {
    public class var isSolid: Bool { false }
    public var isSolid: Bool { Self.isSolid }
    
    public var symbol: Character? { nil }
    
    public class Air: Block {
        
    }
    
    public class Ground: Block {
        public override var symbol: Character? { "." }
    }
    
    public class Stairs: Block {
        public let direction: Direction
        
        public override var symbol: Character? {
            switch direction {
                case .up: "<"
                case .down: ">"
            }
        }
        
        public init(_ direction: Direction) {
            self.direction = direction
        }
        
        public enum Direction {
            case up, down
            public var opposite: Self { switch self { case .up: .down case .down: .up } }
        }
    }
    
    public class Wall: Block {
        public override class var isSolid: Bool { true }
        
        public override var symbol: Character? { "#" }
    }
}
