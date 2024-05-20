
/// A work in progress representation of input.
// TODO(!): This needs to be properly abstract to work across platforms.
public struct Input: Sendable {
    public var mouse: Mouse? = nil
    public var keys: Set<Key> = []
    public var modifiers: Set<Modifier> = []
    
    public init() {}
    
    public struct Mouse: Sendable, BitwiseCopyable {
        public var x, y: Int
        public var left, right: Bool
        
        public init() {
            self.x = 0
            self.y = 0
            self.left = false
            self.right = false
        }
        
        public init(x: Int, y: Int, left: Bool, right: Bool) {
            self.x = x
            self.y = y
            self.left = left
            self.right = right
        }
    }
    
    public struct Key: Hashable, Sendable, BitwiseCopyable {
        public var tag: Tag
        public var isRepeated: Bool
        
        public func hash(into hasher: inout Hasher) { tag.hash(into: &hasher) }
        
        public init(tag: Tag, isRepeated: Bool) {
            self.tag = tag
            self.isRepeated = isRepeated
        }
        
        public enum Tag: Hashable, Sendable, BitwiseCopyable {
            case a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z
            case function(UInt8), modifier
            
            public init?(_ character: Character) {
                switch character {
                    case "a": self = .a
                    case "b": self = .b
                    case "c": self = .c
                    case "d": self = .d
                    case "e": self = .e
                    case "f": self = .f
                    case "g": self = .g
                    case "h": self = .h
                    case "i": self = .i
                    case "j": self = .j
                    case "k": self = .k
                    case "l": self = .l
                    case "m": self = .m
                    case "n": self = .n
                    case "o": self = .o
                    case "p": self = .p
                    case "q": self = .q
                    case "r": self = .r
                    case "s": self = .s
                    case "t": self = .t
                    case "u": self = .u
                    case "v": self = .v
                    case "w": self = .w
                    case "x": self = .x
                    case "y": self = .y
                    case "z": self = .z
                    case _: return nil
                }
            }
        }
    }
    
    public struct Modifier: Hashable, Sendable, BitwiseCopyable {
        public var tag: Tag
        public var isRepeated: Bool
        
        public func hash(into hasher: inout Hasher) { tag.hash(into: &hasher) }
        
        public init(tag: Tag, isRepeated: Bool) {
            self.tag = tag
            self.isRepeated = isRepeated
        }
        
        public enum Tag: Hashable, Sendable, BitwiseCopyable {
            case a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z
            case A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z
        }
    }
}
