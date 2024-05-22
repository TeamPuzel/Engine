
// MARK: - Input

/// A work in progress representation of input.
// TODO(!): This needs to be properly abstract to work across platforms.
public struct Input: Sendable {
    public var mouse: Mouse? = nil { willSet { previousMouse = mouse } }
    private var previousMouse: Mouse? = nil
    public var relativeMouse: Mouse {
        return if case let (.some(mouse), .some(previousMouse)) = (mouse, previousMouse) {
            .init(x: mouse.x - previousMouse.x, y: mouse.y - previousMouse.y, left: mouse.left, right: mouse.right)
        } else {
            mouse ?? .init()
        }
    }
    
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

// MARK: - Time

#if canImport(Darwin)
import Darwin

fileprivate func getTime() -> Double {
    var timespec = timespec()
    clock_gettime(CLOCK_UPTIME_RAW, &timespec)
    return Double(timespec.tv_sec) * 1_000_000_000 + Double(timespec.tv_nsec)
}

#elseif canImport(Glibc)
import Glibc

fileprivate func getTime() -> Double {
    var timespec = timespec()
    clock_gettime(CLOCK_BOOTTIME, &timespec)
    return timespec.tv_nsec
}

#endif

public struct Timer: ~Copyable {
    private var prevTime: Double = getTime()
    public init() {}
    
    public var elapsed: Double {
        (getTime() - prevTime) / 1000000 // Converting nano to milliseconds
    }
    
    @discardableResult
    public mutating func lap() -> Double {
        let elapsed = elapsed
        prevTime = getTime()
        return elapsed
    }
}

public struct BufferedTimer: ~Copyable {
    public private(set) var inner: Timer = .init()
    private var buffer: [Double] = .init(repeating: 0, count: 360)
    public init() {}
    
    public var elapsed: Double { buffer.average() }
    
    @discardableResult
    public mutating func lap() -> Double {
        buffer.removeFirst()
        buffer.append(inner.lap())
        return elapsed
    }
}
