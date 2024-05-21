
// MARK: - Assets

import Assets

fileprivate let interface = UnsafeTGAPointer(UI_TGA).grid(itemSide: 16)
fileprivate let cursor = interface[0, 0]
fileprivate let cursorPressed = interface[1, 0]
fileprivate let terrain = UnsafeTGAPointer(TERRAIN_TGA)

// MARK: - Minecraft

/// A platform independent game implementation, manages game state based on abstract input
/// and provides ways to query its encapsulated state, such as abstract mesh data. *It must not access platform state*.
///
/// # Entry point
/// The entry point is declared to be here but it is for platform code to implement it in an extension.
@main
public final class Minecraft {
    public var input: Input = .init()
    public var interface: Image = .init(width: 400, height: 300)
    public var world: World
    
    private var timer = BufferedTimer()
    private var debug = true
    
    public init() {
        self.world = World(name: "Test")
    }
    
    public func frame() {
        let elapsed = timer.lap()
        interface.clear()
        
        world.frame(input: input, renderer: &interface)
        
        if debug {
            // PLATFORM(!), TODO(!): Why is formatting depending on Foundation...
            interface.text("Frame: \(String(format: "%.5f", elapsed))", x: 2, y: 2)
            interface.text("Position: \(world.primaryPosition)", x: 2, y: 2 + 6)
            interface.text("Rotation: \(world.primaryOrientation)", x: 2, y: 2 + 6 * 2)
        }
        
        if let mouse = input.mouse {
            interface.draw(mouse.left ? cursorPressed : cursor, x: mouse.x - 1, y: mouse.y - 1)
        }
    }
}

// MARK: - World

/// Represents the entire world.
///
/// # Distributed
/// This actor will potentially (probably not) be distributed one day to support multiplayer. Plan accordingly,
/// as all messages will have to implement `Codable` or some other custom serialization system.
public final class World {
    public let name: String
    public let seed: UInt64
    private var chunks: [Chunk.Position: Chunk] = [:]
    private var entities: Set<Entity> = []
    /// The entity currently controlled by the player to which the camera is attached to.
    private var primaryEntity: Entity!
    /// The position relative to which vertices were last sorted. This is used to determine if the
    /// primary entity moved far enough to require sorting vertices again.
    private var sortedAt: Entity.Position = .zero
    
    public init(name: String, seed: UInt64 = .random(in: 1...UInt64.max)) {
        self.name = name
        self.seed = seed
        
        for x in -2...2 {
            for y in -2...2 {
                chunks[.init(x: x, y: y)] = Chunk(self, x: x, y: y)
            }
        }
        
        for (_, chunk) in chunks { chunk.generate() }
        
        let player = Entity.Human(x: 0, y: 130, z: 0)
        entities.insert(player)
        primaryEntity = player
        
        for (_, chunk) in chunks { chunk.remesh(); chunk.resort() }
    }
    
    public func frame(input: Input, renderer: inout Image) {
        primaryEntity!.primaryUpdate(input: input)
    }
    
    public var primaryPosition: Entity.Position { primaryEntity?.position ?? .zero }
    public var primaryOrientation: Entity.Orientation { primaryEntity?.orientation ?? .zero }
    
    public var unifiedMesh: [BlockVertex] {
        chunks.values.reduce(into: []) { acc, el in acc.append(contentsOf: el.mesh)  }
    }
    
    public func primaryMatrix(width: Float, height: Float) -> Matrix4x4<Float> {
        .translation(x: -primaryEntity.position.x, y: -primaryEntity.position.y, z: -primaryEntity.position.z)
            .rotated(axis: .yaw, angle: primaryEntity.orientation.yaw)
            .rotated(axis: .pitch, angle: primaryEntity.orientation.pitch)
            .projected(width: width, height: height, fov: 80, near: 0.1, far: 1000)
    }
}

// MARK: - Chunk

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
        
        let chunkOffsetX = Float(self.x * Self.side)
        let chunkOffsetZ = Float(self.y * Self.side)
        
        for x in 0..<Self.side {
            for z in 0..<Self.side {
                for y in 0..<Self.height {
                    self[x, y, z].mesh(
                        faces: .all,
                        x: Float(x) + chunkOffsetX,
                        y: Float(y),
                        z: Float(z) + chunkOffsetZ,
                        into: &buffer
                    )
                }
            }
        }
        
        self.mesh = buffer
    }
    
    /// Sorts the vertices in the background.
    ///
    /// It is intended to re-sort already mostly sorted vertices, must not take too long.
    public func resort() {
        typealias TriVertex = (BlockVertex, BlockVertex, BlockVertex)
//        guard blocks.count.isMultiple(of: 3) else { return }
        var buffer = mesh
        
        precondition(buffer.count.isMultiple(of: 3))
        buffer.withUnsafeMutableBufferPointer { buf in
            buf.baseAddress!.withMemoryRebound(to: TriVertex.self, capacity: buf.count / 3) { ptr in
                var triView = UnsafeMutableBufferPointer(start: ptr, count: buf.count / 3)
                triView.sort { lhs, rhs in
                    triCompare(
                        (lhs.0.position, lhs.1.position, lhs.2.position),
                        (rhs.0.position, rhs.1.position, rhs.2.position),
                        to: world.primaryPosition
                    )
                }
            }
        }
        
        mesh = buffer
    }
    
    public subscript(x: Int, y: Int, z: Int) -> Block {
        get { blocks[(x * Self.side * Self.height) + (y * Self.side) + z] }
        set { blocks[(x * Self.side * Self.height) + (y * Self.side) + z] = newValue }
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

// MARK: - Block

public enum Block: Hashable, Sendable, BitwiseCopyable {
    case air
    case stone
    
    public var offsets: AtlasOffsets? {
        switch self {
            case .air: nil
            case .stone:
                .init(
                    back:   .init(x: 1, y: 0),
                    front:  .init(x: 1, y: 0),
                    left:   .init(x: 1, y: 0),
                    right:  .init(x: 1, y: 0),
                    top:    .init(x: 1, y: 0),
                    bottom: .init(x: 1, y: 0)
                )
        }
    }
    
    public static let side: Float = 1.0
    /// The block texture atlas. While drawing is performed as offsets into the GPU loaded
    /// copy of `inner` it is still useful as a grid for easy UI rendering of blocks.
    public static let atlas = terrain.grid(itemSide: 16)
    
    /// The core meshing function which writes the visible vertices of a block into a buffer.
    func mesh(faces: MeshFaces, x: Float, y: Float, z: Float, into existing: inout [BlockVertex]) {
        guard let offsets else { return } // If we have none there is nothing to draw.
        guard !faces.isEmpty else { return } // If there's no faces to draw fast path out.
        
        let s = Self.side / 2 // Half side
        /// The coefficient for converting atlas offsets into UV coordinates.
        ///
        /// - Warning: Assumes the atlas is square. Only asserted in debug builds.
        let c = Float(Self.atlas.itemSide) / Float(Self.atlas.inner.height)
        assert(Self.atlas.inner.height == Self.atlas.inner.width)
        
        // Back
        if faces.contains(.north) {
            // TODO(!): This might not be getting optimized and allocate. Use a face sequence instead.
            existing.append(contentsOf: [
                .init(x: -s + x, y:  s + y, z:  s + z, u: c * offsets.back.x + c, v: c * offsets.back.y,     r: 1, g: 1, b: 1, a: 1), // TR
                .init(x:  s + x, y:  s + y, z:  s + z, u: c * offsets.back.x,     v: c * offsets.back.y,     r: 1, g: 1, b: 1, a: 1), // TL
                .init(x:  s + x, y: -s + y, z:  s + z, u: c * offsets.back.x,     v: c * offsets.back.y + c, r: 1, g: 1, b: 1, a: 1), // BL
                .init(x: -s + x, y:  s + y, z:  s + z, u: c * offsets.back.x + c, v: c * offsets.back.y,     r: 1, g: 1, b: 1, a: 1), // TR
                .init(x:  s + x, y: -s + y, z:  s + z, u: c * offsets.back.x,     v: c * offsets.back.y + c, r: 1, g: 1, b: 1, a: 1), // BL
                .init(x: -s + x, y: -s + y, z:  s + z, u: c * offsets.back.x + c, v: c * offsets.back.y + c, r: 1, g: 1, b: 1, a: 1)  // BR
            ])
        }
        
        // Front
        if faces.contains(.south) {
            existing.append(contentsOf: [
                .init(x:  s + x, y:  s + y, z: -s + z, u: c * offsets.front.x + c, v: c * offsets.front.y,     r: 1, g: 1, b: 1, a: 1), // TR
                .init(x: -s + x, y:  s + y, z: -s + z, u: c * offsets.front.x,     v: c * offsets.front.y,     r: 1, g: 1, b: 1, a: 1), // TL
                .init(x: -s + x, y: -s + y, z: -s + z, u: c * offsets.front.x,     v: c * offsets.front.y + c, r: 1, g: 1, b: 1, a: 1), // BL
                .init(x:  s + x, y:  s + y, z: -s + z, u: c * offsets.front.x + c, v: c * offsets.front.y,     r: 1, g: 1, b: 1, a: 1), // TR
                .init(x: -s + x, y: -s + y, z: -s + z, u: c * offsets.front.x,     v: c * offsets.front.y + c, r: 1, g: 1, b: 1, a: 1), // BL
                .init(x:  s + x, y: -s + y, z: -s + z, u: c * offsets.front.x + c, v: c * offsets.front.y + c, r: 1, g: 1, b: 1, a: 1)  // BR
            ])
        }
        
        // Right
        if faces.contains(.east) {
            existing.append(contentsOf: [
                .init(x:  s + x, y:  s + y, z:  s + z, u: c * offsets.right.x + c, v: c * offsets.right.y,     r: 1, g: 1, b: 1, a: 1), // TR
                .init(x:  s + x, y:  s + y, z: -s + z, u: c * offsets.right.x,     v: c * offsets.right.y,     r: 1, g: 1, b: 1, a: 1), // TL
                .init(x:  s + x, y: -s + y, z: -s + z, u: c * offsets.right.x,     v: c * offsets.right.y + c, r: 1, g: 1, b: 1, a: 1), // BL
                .init(x:  s + x, y:  s + y, z:  s + z, u: c * offsets.right.x + c, v: c * offsets.right.y,     r: 1, g: 1, b: 1, a: 1), // TR
                .init(x:  s + x, y: -s + y, z: -s + z, u: c * offsets.right.x,     v: c * offsets.right.y + c, r: 1, g: 1, b: 1, a: 1), // BL
                .init(x:  s + x, y: -s + y, z:  s + z, u: c * offsets.right.x + c, v: c * offsets.right.y + c, r: 1, g: 1, b: 1, a: 1)  // BR
            ])
        }
        
        // Left
        if faces.contains(.west) {
            existing.append(contentsOf: [
                .init(x: -s + x, y:  s + y, z: -s + z, u: c * offsets.left.x + c,  v: c * offsets.left.y,     r: 1, g: 1, b: 1, a: 1), // TR
                .init(x: -s + x, y:  s + y, z:  s + z, u: c * offsets.left.x,      v: c * offsets.left.y,     r: 1, g: 1, b: 1, a: 1), // TL
                .init(x: -s + x, y: -s + y, z:  s + z, u: c * offsets.left.x,      v: c * offsets.left.y + c, r: 1, g: 1, b: 1, a: 1), // BL
                .init(x: -s + x, y:  s + y, z: -s + z, u: c * offsets.left.x + c,  v: c * offsets.left.y,     r: 1, g: 1, b: 1, a: 1), // TR
                .init(x: -s + x, y: -s + y, z:  s + z, u: c * offsets.left.x,      v: c * offsets.left.y + c, r: 1, g: 1, b: 1, a: 1), // BL
                .init(x: -s + x, y: -s + y, z: -s + z, u: c * offsets.left.x + c,  v: c * offsets.left.y + c, r: 1, g: 1, b: 1, a: 1)  // BR
            ])
        }
        
        // Top
        if faces.contains(.up) {
            existing.append(contentsOf: [
                .init(x:  s + x, y:  s + y, z:  s + z, u: c * offsets.top.x + c, v: c * offsets.top.y,     r: 1, g: 1, b: 1, a: 1), // TR
                .init(x: -s + x, y:  s + y, z:  s + z, u: c * offsets.top.x,     v: c * offsets.top.y,     r: 1, g: 1, b: 1, a: 1), // TL
                .init(x: -s + x, y:  s + y, z: -s + z, u: c * offsets.top.x,     v: c * offsets.top.y + c, r: 1, g: 1, b: 1, a: 1), // BL
                .init(x:  s + x, y:  s + y, z:  s + z, u: c * offsets.top.x + c, v: c * offsets.top.y,     r: 1, g: 1, b: 1, a: 1), // TR
                .init(x: -s + x, y:  s + y, z: -s + z, u: c * offsets.top.x,     v: c * offsets.top.y + c, r: 1, g: 1, b: 1, a: 1), // BL
                .init(x:  s + x, y:  s + y, z: -s + z, u: c * offsets.top.x + c, v: c * offsets.top.y + c, r: 1, g: 1, b: 1, a: 1)  // BR
            ])
        }
        
        // Bottom
        if faces.contains(.down) {
            existing.append(contentsOf: [
                .init(x:  s + x, y: -s + y, z: -s + z, u: c * offsets.bottom.x + c, v: c * offsets.bottom.y,     r: 1, g: 1, b: 1, a: 1), // TR
                .init(x: -s + x, y: -s + y, z: -s + z, u: c * offsets.bottom.x,     v: c * offsets.bottom.y,     r: 1, g: 1, b: 1, a: 1), // TL
                .init(x: -s + x, y: -s + y, z:  s + z, u: c * offsets.bottom.x,     v: c * offsets.bottom.y + c, r: 1, g: 1, b: 1, a: 1), // BL
                .init(x:  s + x, y: -s + y, z: -s + z, u: c * offsets.bottom.x + c, v: c * offsets.bottom.y,     r: 1, g: 1, b: 1, a: 1), // TR
                .init(x: -s + x, y: -s + y, z:  s + z, u: c * offsets.bottom.x,     v: c * offsets.bottom.y + c, r: 1, g: 1, b: 1, a: 1), // BL
                .init(x:  s + x, y: -s + y, z:  s + z, u: c * offsets.bottom.x + c, v: c * offsets.bottom.y + c, r: 1, g: 1, b: 1, a: 1)  // BR
            ])
        }
    }
    
    /// A mask of faces to draw.
    public struct MeshFaces: OptionSet, Sendable {
        public let rawValue: UInt8
        
        public init(rawValue: UInt8) { self.rawValue = rawValue }
        
        public static let north = Self(rawValue: 1 << 0)
        public static let south = Self(rawValue: 1 << 1)
        public static let east  = Self(rawValue: 1 << 2)
        public static let west  = Self(rawValue: 1 << 3)
        public static let up    = Self(rawValue: 1 << 4)
        public static let down  = Self(rawValue: 1 << 5)
        
        public static let all: Self = [.north, south, .east, .west, .up, .down]
    }
    
    public struct AtlasOffsets: Hashable, Sendable, BitwiseCopyable {
        public let back: Offset
        public let front: Offset
        public let left: Offset
        public let right: Offset
        public let top: Offset
        public let bottom: Offset
        
        public struct Offset: Hashable, Sendable, BitwiseCopyable {
            public let x, y: Float
            public init(x: Float, y: Float) { self.x = x; self.y = y }
        }
    }
}

// MARK: - Entity

public class Entity {
    public var position: Position
    public var orientation: Orientation
    
    public init(x: Float, y: Float, z: Float, orientation: Orientation = .init()) {
        self.position = .init(x: x, y: y, z: z)
        self.orientation = orientation
    }
    
    public func primaryUpdate(input: Input) {
        self.orientation.yaw += 0.1
    }
    
    public typealias Position = Vector3<Float>
    
    /// A specialized vector of floats with wrapping behavior.
    public struct Orientation: Hashable {
        public var pitch, yaw, roll: Float
        
        public static var zero: Self { .init(pitch: 0, yaw: 0, roll: 0) }
        
        public init(pitch: Float = 0, yaw: Float = 0, roll: Float = 0) {
            self.pitch = pitch; self.yaw = yaw; self.roll = roll
        }
    }
    
    public class Human: Entity {
        
    }
}

extension Entity: Hashable {
    public static func == (lhs: Entity, rhs: Entity) -> Bool { lhs === rhs }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}
