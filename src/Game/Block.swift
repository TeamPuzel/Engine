
public class Block {
    public class var isSolid: Bool { false }
    public var isSolid: Bool { Self.isSolid }
    
    public class Air: Block {
        
    }
    
    public class Dirt: Block {
        public override class var isSolid: Bool { true }
    }
}
