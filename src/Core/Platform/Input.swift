
/// A work in progress representation of input.
// TODO(!): This needs to be properly abstract to work across platforms.
public struct Input: Sendable, BitwiseCopyable {
    public var mouse: Mouse
    
    public init(mouse: Mouse) {
        self.mouse = mouse
    }
    
//    private let keys: UnsafeBufferPointer<UInt8>
//    
//    public var tab: Bool { keys[Int(SDL_SCANCODE_TAB.rawValue)] == 1 }
//    public var enter: Bool { keys[Int(SDL_SCANCODE_RETURN.rawValue)] == 1 }
//    
//    public var leftShift: Bool { keys[Int(SDL_SCANCODE_LSHIFT.rawValue)] == 1 }
//    public var rightShift: Bool { keys[Int(SDL_SCANCODE_RSHIFT.rawValue)] == 1 }
//    public var leftAlt: Bool { keys[Int(SDL_SCANCODE_LALT.rawValue)] == 1 }
//    public var rightAlt: Bool { keys[Int(SDL_SCANCODE_RALT.rawValue)] == 1 }
//    public var leftControl: Bool { keys[Int(SDL_SCANCODE_LCTRL.rawValue)] == 1 }
//    public var rightControl: Bool { keys[Int(SDL_SCANCODE_RALT.rawValue)] == 1 }
//    
//    public var arrowUp: Bool { keys[Int(SDL_SCANCODE_UP.rawValue)] == 1 }
//    public var arrowDown: Bool { keys[Int(SDL_SCANCODE_DOWN.rawValue)] == 1 }
//    public var arrowLeft: Bool { keys[Int(SDL_SCANCODE_LEFT.rawValue)] == 1 }
//    public var arrorRight: Bool { keys[Int(SDL_SCANCODE_RIGHT.rawValue)] == 1 }
//    
//    public subscript(for name: String) -> Bool {
//        keys[Int(SDL_GetScancodeFromName(name).rawValue)] == 1
//    }
//    
//    fileprivate init(window: OpaquePointer) {
//        var (wx, wy): (Int32, Int32) = (0, 0)
//        SDL_GetWindowPosition(window, &wx, &wy)
//        
//        var (x, y): (Int32, Int32) = (0, 0)
//        let buttons = SDL_GetMouseState(&x, &y)
//        SDL_GetGlobalMouseState(&x, &y)
//        
//        x -= wx; y -= wy
//        x /= Int32(pixelScale); y /= Int32(pixelScale)
//        
//        let left = buttons & 1 == 1
//        let right = buttons & 3 == 3
//        
//        self.mouse = .init(x: Int(x), y: Int(y), left: left, right: right)
//        
//        var count: Int32 = 0
//        let rawKeys = SDL_GetKeyboardState(&count)!
//        self.keys = UnsafeBufferPointer(start: rawKeys, count: Int(count))
//    }
    
    public struct Mouse: Sendable, BitwiseCopyable {
        public var x, y: Int
        public var left, right: Bool
        
        public init(x: Int, y: Int, left: Bool, right: Bool) {
            self.x = x
            self.y = y
            self.left = left
            self.right = right
        }
    }
}
