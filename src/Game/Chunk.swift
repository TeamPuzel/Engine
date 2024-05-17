
public final class Chunk {
    public unowned var world: World
    public let x, y: Int
    private var blocks: [Block]
    public private(set) var isGenerated = false
    public private(set) var mesh: [BlockVertex] = []
    
    public private(set) var meshTask: Task<Void, Never>?
    public private(set) var sortTask: Task<Void, Never>?
    
    public static let side = 16
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
    
    /// Recalculates the mesh of the chunk in the background.
    ///
    /// It does this by spawning a task which on completion will call back into the actor and
    /// submit the new mesh. It needs to copy the blocks in to avoid locking the actor.
    public func remesh() {
        // Write to a new buffer concurrently to allow drawing the old one
        var buffer: [BlockVertex] = []
        buffer.reserveCapacity(Self.blocksPerChunk * 36 / 2)
        
        for x in 0..<Self.side {
            for z in 0..<Self.side {
                for y in 0..<Self.height {
                    self[x, y, z].mesh(faces: .all, x: Float(x), y: Float(y), z: Float(z), into: &buffer)
                }
            }
        }
        
        self.mesh = buffer
    }
    
    /// Sorts the vertices in the background.
    ///
    /// It is intended to re-sort already mostly sorted vertices, must not take too long.
    public func resort() {
//        sortTask = Task.detached {
//            
//        }
    }
    
    public subscript(x: Int, y: Int, z: Int) -> Block {
        get { blocks[(x * Self.side * Self.side) + (z * Self.side) + y] }
        set { blocks[(x * Self.side * Self.side) + (z * Self.side) + y] = newValue }
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
