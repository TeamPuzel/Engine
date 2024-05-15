
public class Block {
    public class var isSolid: Bool { false }
    public var isSolid: Bool { Self.isSolid }
    
    public class Air: Block {
        
    }
    
    public class Stone: Block {
        public override class var isSolid: Bool { true }
    }
}

// SAFETY: This is unsafe.
public struct BlockVertex: Vertex {
    public let x, y, z, u, v: Float
    public let color: Color
}

public extension Block {
    func mesh(into existing: inout Mesh<BlockVertex>) {
        
    }
}
