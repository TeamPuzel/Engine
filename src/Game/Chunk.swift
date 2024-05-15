
public actor Chunk {
    public unowned var world: World
    public let x, y: Int
    private var blocks: [Block]
    public private(set) var isGenerated = false
    
    public static let side = 32
    public static let height = 256
    public static var blocksPerChunk: Int { side * side * height }
    
    public init(_ world: World, x: Int, y: Int) async {
        self.world = world
        self.x = x
        self.y = y
        
        self.blocks = .init(unsafeUninitializedCapacity: Self.blocksPerChunk) { buffer, initializedCount in
            for i in 0..<Self.blocksPerChunk { buffer[i] = Block.Air() }
            initializedCount = Self.blocksPerChunk
        }
    }
    
    public func generate() async {
        for x in 0..<Self.side {
            for z in 0..<Self.side {
                for y in 0..<Self.height {
                    if y < 128 { self[x, y, z] = Block.Stone() }
                }
            }
        }
        
        self.isGenerated = true
    }
    
    public subscript(x: Int, y: Int, z: Int) -> Block {
        get { fatalError() }
        set { fatalError() }
    }
    
    public struct Position: Hashable {
        public var x, y: Int
        
        public init(x: Int, y: Int) {
            self.x = x
            self.y = y
        }
    }
}
