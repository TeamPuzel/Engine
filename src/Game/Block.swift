
import Assets

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
    public static let atlas = UnsafeTGAPointer(TERRAIN_TGA).grid(itemSide: 16)
    
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
