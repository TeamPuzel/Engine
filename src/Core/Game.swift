
import SDL

/// A target independent game which can be run by a runtime for any platform.
public protocol Game {
    init() throws
    // TODO(!!): Not actually called reliably. Make this framerate independent.
    /// Called reliably every tick.
    mutating func update(input: borrowing Input) throws
    /// Called every frame, does not guarantee timing and can even be skipped.
    mutating func draw(into renderer: inout some MutableDrawable) throws
}

fileprivate let minimumWidth = 600
fileprivate let minimumHeight = 400
fileprivate let pixelScale = 2

// TODO(!!): Optimize the SDL implementation, it's quite inefficient.
public extension Game {
    static func main() throws {
        guard SDL_Init(SDL_INIT_VIDEO) == 0 else { throw GameError.initializingSDL }
        defer { SDL_Quit() }
        
        guard let sdlWindow = SDL_CreateWindow(
            String(describing: Self.self),
            Int32(SDL_WINDOWPOS_CENTERED_MASK),
            Int32(SDL_WINDOWPOS_CENTERED_MASK),
            Int32(minimumWidth * pixelScale), Int32(minimumHeight * pixelScale),
            SDL_WINDOW_ALLOW_HIGHDPI.rawValue |
            SDL_WINDOW_RESIZABLE.rawValue
        ) else { throw GameError.creatingWindow }
        SDL_SetWindowMinimumSize(
            sdlWindow, Int32(minimumWidth * pixelScale), Int32(minimumHeight * pixelScale)
        )
        SDL_ShowCursor(0)
        defer { SDL_DestroyWindow(sdlWindow) }
        
        guard let sdlRenderer = SDL_CreateRenderer(
            sdlWindow, -1, SDL_RENDERER_ACCELERATED.rawValue | SDL_RENDERER_PRESENTVSYNC.rawValue
        ) else { throw GameError.creatingRenderer }
        defer { SDL_DestroyRenderer(sdlRenderer) }
        
        guard var sdlTexture = SDL_CreateTexture(
            sdlRenderer,
            SDL_PIXELFORMAT_RGBA32.rawValue, Int32(SDL_TEXTUREACCESS_STREAMING.rawValue),
            Int32(minimumWidth), Int32(minimumHeight)
        ) else { throw GameError.creatingTexture }
        SDL_SetTextureScaleMode(sdlTexture, SDL_ScaleModeNearest)
        defer { SDL_DestroyTexture(sdlTexture) }
        
        var instance = try Self()
        var renderer = Image(width: minimumWidth, height: minimumHeight)
        
        var event = SDL_Event()
        
        loop: while true {
            while (SDL_PollEvent(&event) > 0) {
                switch event.type {
                    case SDL_QUIT.rawValue: break loop
                    case _: break
                }
            }
            SDL_RenderClear(sdlRenderer)
            
            var (w, h): (Int32, Int32) = (0, 0)
            SDL_GetWindowSize(sdlWindow, &w, &h)
            
            var (pw, ph): (Int32, Int32) = (0, 0)
            SDL_GetWindowSizeInPixels(sdlWindow, &pw, &ph)
            
            if renderer.resize(width: Int(w) / pixelScale, height: Int(h) / pixelScale) {
                SDL_DestroyTexture(sdlTexture)
                guard let newTexture = SDL_CreateTexture(
                    sdlRenderer,
                    SDL_PIXELFORMAT_RGBA32.rawValue, Int32(SDL_TEXTUREACCESS_STREAMING.rawValue),
                    Int32(renderer.width), Int32(renderer.height)
                ) else { throw GameError.creatingTexture }
                sdlTexture = newTexture
            }
            
            try instance.update(input: Input(window: sdlWindow))
            try instance.draw(into: &renderer)
            
            SDL_UpdateTexture(
                sdlTexture, nil, renderer.data,
                Int32(MemoryLayout<Color>.stride * renderer.width)
            )
            
            var screenRect = SDL_Rect(x: 0, y: 0, w: pw, h: ph)
            SDL_RenderCopy(sdlRenderer, sdlTexture, nil, &screenRect)
            SDL_RenderPresent(sdlRenderer)
        }
    }
}

private enum GameError: Error {
    case initializingSDL
    case creatingWindow
    case creatingRenderer
    case creatingTexture
}

// TODO(!!): Consider changing how this is constructed to drop the copyability restriction.
//           It is shared mutable state in a very unobvious way and `Input` should be
//           `Sendable` when the engine starts to implement more concurrency features.
public struct Input: ~Copyable {
    public let mouse: Mouse
    
    private let keys: UnsafeBufferPointer<UInt8>
    
    public var tab: Bool { keys[Int(SDL_SCANCODE_TAB.rawValue)] == 1 }
    public var enter: Bool { keys[Int(SDL_SCANCODE_RETURN.rawValue)] == 1 }
    
    public var leftShift: Bool { keys[Int(SDL_SCANCODE_LSHIFT.rawValue)] == 1 }
    public var rightShift: Bool { keys[Int(SDL_SCANCODE_RSHIFT.rawValue)] == 1 }
    public var leftAlt: Bool { keys[Int(SDL_SCANCODE_LALT.rawValue)] == 1 }
    public var rightAlt: Bool { keys[Int(SDL_SCANCODE_RALT.rawValue)] == 1 }
    public var leftControl: Bool { keys[Int(SDL_SCANCODE_LCTRL.rawValue)] == 1 }
    public var rightControl: Bool { keys[Int(SDL_SCANCODE_RALT.rawValue)] == 1 }
    
    public var arrowUp: Bool { keys[Int(SDL_SCANCODE_UP.rawValue)] == 1 }
    public var arrowDown: Bool { keys[Int(SDL_SCANCODE_DOWN.rawValue)] == 1 }
    public var arrowLeft: Bool { keys[Int(SDL_SCANCODE_LEFT.rawValue)] == 1 }
    public var arrorRight: Bool { keys[Int(SDL_SCANCODE_RIGHT.rawValue)] == 1 }
    
    public subscript(for name: String) -> Bool {
        keys[Int(SDL_GetScancodeFromName(name).rawValue)] == 1
    }
    
    fileprivate init(window: OpaquePointer) {
        var (wx, wy): (Int32, Int32) = (0, 0)
        SDL_GetWindowPosition(window, &wx, &wy)
        
        var (x, y): (Int32, Int32) = (0, 0)
        let buttons = SDL_GetMouseState(&x, &y)
        SDL_GetGlobalMouseState(&x, &y)
        
        x -= wx; y -= wy
        x /= Int32(pixelScale); y /= Int32(pixelScale)
        
        let left = buttons & 1 == 1
        let right = buttons & 3 == 3
        
        self.mouse = .init(x: Int(x), y: Int(y), left: left, right: right)
        
        var count: Int32 = 0
        let rawKeys = SDL_GetKeyboardState(&count)!
        self.keys = UnsafeBufferPointer(start: rawKeys, count: Int(count))
    }
    
    public struct Mouse {
        public var x, y: Int
        public var left, right: Bool
        
        fileprivate init(x: Int, y: Int, left: Bool, right: Bool) {
            self.x = x
            self.y = y
            self.left = left
            self.right = right
        }
    }
}

public struct SDLRenderer: MutableDrawable {
    private let renderer: OpaquePointer
    
    public var width: Int {
        var (width, height): (Int32, Int32) = (0, 0)
        SDL_GetRendererOutputSize(renderer, &width, &height)
        return Int(width)
    }
    public var height: Int {
        var (width, height): (Int32, Int32) = (0, 0)
        SDL_GetRendererOutputSize(renderer, &width, &height)
        return Int(height)
    }
    
    fileprivate init(_ renderer: OpaquePointer) { self.renderer = renderer }
    
    public mutating func clear(with color: Color = .black) {
        SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a)
        SDL_RenderClear(renderer)
    }
    
    public mutating func draw(_ drawable: Rectangle, x: Int, y: Int) {
        SDL_SetRenderDrawColor(renderer, drawable.color.r, drawable.color.g, drawable.color.b, drawable.color.a)
        var rect = SDL_Rect(x: Int32(x), y: Int32(y), w: Int32(drawable.width), h: Int32(drawable.height))
        SDL_RenderFillRect(renderer, &rect)
    }
    
    public subscript(x: Int, y: Int) -> Color {
        get {
            var rect = SDL_Rect(x: Int32(x), y: Int32(y), w: 1, h: 1)
            var pixel: Color = .clear
            SDL_RenderReadPixels(
                renderer, &rect,
                SDL_PIXELFORMAT_RGBA32.rawValue,
                &pixel, Int32(MemoryLayout<Color>.stride)
            )
            return pixel
        }
        set {
            // TODO(!): Combined hardware/software rendering. Draw in software until a hardware command,
            //          at that point submit the buffer.
            fatalError()
            //var rect = SDL_Rect(x: Int32(x), y: Int32(y), w: 1, h: 1)
        }
    }
}
