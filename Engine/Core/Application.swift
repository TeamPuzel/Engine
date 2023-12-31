
import SDL

public protocol Application {
    @SceneBuilder var scene: Scene { get }
    
    init()
}

enum GameError: Error {
    case createWindow
}

internal extension Application {
    static var display: (w: Int, h: Int) { (128, 128) }
    static var windowWidth: Int { display.w * pixelSize / 2 + windowMargin * pixelSize }
    static var windowHeight: Int { display.h * pixelSize / 2 + windowMargin * pixelSize }
    static var pixelSize: Int { 8 }
    static var windowMargin: Int { 2 }
    
    mutating func frame(renderer: inout Renderer, input: Input) {
        
    }
}

public extension Application {
    static func main() throws {
        SDL_Init(SDL_INIT_VIDEO)
        defer { SDL_Quit() }
        
        var instance = Self()
        let mirror = Mirror(reflecting: instance)
        let windowName = String(mirror.description.split(separator: " ").last!)
        
        guard let window = SDL_CreateWindow(
            windowName,
            Int32(SDL_WINDOWPOS_CENTERED_MASK),
            Int32(SDL_WINDOWPOS_CENTERED_MASK),
            Int32(windowWidth), Int32(windowHeight),
            SDL_WINDOW_ALLOW_HIGHDPI.rawValue
        ) else {
            throw GameError.createWindow
        }
        defer { SDL_DestroyWindow(window) }
        
        let renderer = SDL_CreateRenderer(
            window, -1,
            SDL_RENDERER_ACCELERATED.rawValue |
            SDL_RENDERER_PRESENTVSYNC.rawValue
        )
        defer { SDL_DestroyRenderer(renderer) }
        
        SDL_ShowCursor(SDL_DISABLE)
        
        var api = Renderer(width: Self.display.w, height: Self.display.h)
        var event = SDL_Event()
        
        let texture = SDL_CreateTexture(
            renderer,
            SDL_PIXELFORMAT_RGBA32.rawValue,
            Int32(SDL_TEXTUREACCESS_STREAMING.rawValue),
            Int32(api.display.width), Int32(api.display.height)
        )
        defer { SDL_DestroyTexture(texture) }
        
        SDL_UpdateTexture(texture, nil, api.display.data, Int32(api.display.width * MemoryLayout<Color>.stride))
        
        var displayRect = SDL_Rect(
            x: Int32(windowMargin * pixelSize),
            y: Int32(windowMargin * pixelSize),
            w: Int32((windowWidth - windowMargin * pixelSize) * 2),
            h: Int32((windowHeight - windowMargin * pixelSize) * 2)
        )
        
        loop:
        while true {
            while SDL_PollEvent(&event) != 0 {
                switch event.type {
                    case SDL_QUIT.rawValue: break loop
                    default: break
                }
            }
            
            SDL_RenderClear(renderer)
            instance.frame(renderer: &api, input: Input(
                window: window, width: display.w, height: display.h, pixel: pixelSize, margin: windowMargin)
            )
            
            SDL_UpdateTexture(texture, nil, api.display.data, Int32(api.display.width * MemoryLayout<Color>.stride))
            SDL_RenderCopy(renderer, texture, nil, &displayRect)
            
            SDL_RenderPresent(renderer)
        }
        
    }
}

public struct Input {
    public let up, down, left, right, a, b: Bool
    public let mouse: (x: Int, y: Int, left: Bool, right: Bool)
    
    internal init(window: OpaquePointer, width w: Int, height h: Int, pixel: Int, margin: Int) {
        var numKeys: Int32 = 0
        let keys = UnsafeBufferPointer(start: SDL_GetKeyboardState(&numKeys), count: Int(numKeys))
            .lazy.map { $0 == 1 }
        
        self.up    = keys[Int(SDL_SCANCODE_W.rawValue)] || keys[Int(SDL_SCANCODE_UP.rawValue)]
        self.down  = keys[Int(SDL_SCANCODE_S.rawValue)] || keys[Int(SDL_SCANCODE_DOWN.rawValue)]
        self.left  = keys[Int(SDL_SCANCODE_A.rawValue)] || keys[Int(SDL_SCANCODE_LEFT.rawValue)]
        self.right = keys[Int(SDL_SCANCODE_D.rawValue)] || keys[Int(SDL_SCANCODE_RIGHT.rawValue)]
        self.a     = keys[Int(SDL_SCANCODE_COMMA.rawValue)]
        self.b     = keys[Int(SDL_SCANCODE_PERIOD.rawValue)]
        
        var wx: Int32 = 0
        var wy: Int32 = 0
        SDL_GetWindowPosition(window, &wx, &wy)
        
        var x: Int32 = 0
        var y: Int32 = 0
        let btns = SDL_GetGlobalMouseState(&x, &y)
        
        // Correct by window position
        x -= wx
        y -= wy
        
        let left = btns & 1 != 0
        let right = btns & 3 != 0
        
        x /= Int32(pixel) / 2
        y /= Int32(pixel) / 2
        x -= Int32(margin)
        y -= Int32(margin)
        
//        if x < 0 { x = 0 }
//        if x > w { x = Int32(w) }
//        if y < 0 { y = 0 }
//        if y > h { y = Int32(h) }
        
        self.mouse = (Int(x), Int(y), left, right)
    }
}

extension SDL_bool: ExpressibleByBooleanLiteral {
    public typealias BooleanLiteralType = Bool
    public init(booleanLiteral value: Bool) {
        self = .init(value ? 1 : 0)
    }
    
    public init(from value: Bool) {
        self = .init(value ? 1 : 0)
    }
}
