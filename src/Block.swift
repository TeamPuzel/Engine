
import Assets

public class Block {
    public static let sheet = UnsafeTGAPointer(SHEET_TGA_PTR)
        .grid(itemWidth: 16, itemHeight: 16)
    
    public class var isSolid: Bool { false }
    public var isSolid: Bool { Self.isSolid }
    
    public var sprite: any Drawable { EmptyDrawable() }
    
    public class Air: Block {
        
    }
    
    public class Ground: Block {
        public override var sprite: any Drawable { Self.sheet[1, 0] }
    }
    
    public class Stairs: Block {
        public let direction: Direction
        
        public override var sprite: any Drawable {
            switch direction {
                case .up: Self.sheet[3, 0]
                case .down: Self.sheet[2, 0]
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
        
        public override var sprite: any Drawable { Self.sheet[0, 0] }
    }
}
