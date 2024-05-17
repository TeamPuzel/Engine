
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
    
    func mesh(faces: MeshFaces, into existing: inout [BlockVertex]) {
        
    }
    
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
