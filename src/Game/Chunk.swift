
public final class Chunk {
    public unowned var world: World
    public let x, y: Int
    private var blocks: [Block]
    public private(set) var isGenerated = false
    public private(set) var mesh: [BlockVertex] = []
    
    public static let side = 32
    public static let height = 256
    public static var blocksPerChunk: Int { side * side * height }
    
    public init(_ world: World, x: Int, y: Int) {
        self.world = world
        self.x = x
        self.y = y
        self.blocks = .init(repeating: .air, count: Self.blocksPerChunk)
    }
    
    public func generate() {
        guard !isGenerated else { return }
        
        for x in 0..<Self.side {
            for z in 0..<Self.side {
                for y in 0..<Self.height {
                    if y < 128 { self[x, y, z] = .stone }
                }
            }
        }
        
        self.remesh()
        self.isGenerated = true
    }
    
    // TODO(!!): Concurrency, spawn a task which will call back to submit
    public func remesh() {
        // Write to a new buffer concurrently to allow drawing the old one
        var buffer: [BlockVertex] = []
        for block in blocks { block.mesh(faces: .all, into: &buffer) }
        self.mesh = buffer
    }
    
    public subscript(x: Int, y: Int, z: Int) -> Block {
        get { fatalError() }
        set { fatalError() }
    }
    
    @_disfavoredOverload
    public subscript(x: Int, y: Int, z: Int) -> Result<Block, AccessError> {
        get { fatalError() }
        set { fatalError() }
    }
    
    public enum AccessError: Error, Hashable, BitwiseCopyable {
        case notGenerated
        case outOfBounds(Direction)
    }
    
    public struct Position: Hashable, Sendable, BitwiseCopyable {
        public var x, y: Int
        
        public init(x: Int, y: Int) {
            self.x = x
            self.y = y
        }
    }
    
    public enum Direction: Hashable, Sendable, BitwiseCopyable {
        case north, south, east, west
    }
}
