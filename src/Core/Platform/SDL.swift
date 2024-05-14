
#if canImport(SDL)
import SDL

/// A hardcoded and temporary implementation of an SDL backend.
public final class SDL {
    private let window: OpaquePointer
    private let renderer: OpaquePointer
    private var texture: OpaquePointer
    private let scale: Int
    
    private static unowned var shared: SDL!
    
    public init(name: String? = nil, width: Int = 600, height: Int = 400, scale: Int = 2) throws(Error) {
        guard Self.shared == nil else { throw .alreadyInitialized }
        guard SDL_Init(SDL_INIT_VIDEO) == 0 else { throw .initializingSDL }
        
        self.scale = scale
        
        guard let window = SDL_CreateWindow(
            name,
            Int32(SDL_WINDOWPOS_CENTERED_MASK),
            Int32(SDL_WINDOWPOS_CENTERED_MASK),
            Int32(width * scale), Int32(height * scale),
            SDL_WINDOW_ALLOW_HIGHDPI.rawValue |
            SDL_WINDOW_RESIZABLE.rawValue
        ) else { throw .creatingWindow }
        self.window = window
        SDL_SetWindowMinimumSize(
            window, Int32(width * scale), Int32(height * scale)
        )
        SDL_ShowCursor(SDL_DISABLE)
        
        guard let renderer = SDL_CreateRenderer(
            window, -1, SDL_RENDERER_ACCELERATED.rawValue | SDL_RENDERER_PRESENTVSYNC.rawValue
        ) else { throw .creatingRenderer }
        self.renderer = renderer
        
        guard let texture = SDL_CreateTexture(
            renderer,
            SDL_PIXELFORMAT_RGBA32.rawValue, Int32(SDL_TEXTUREACCESS_STREAMING.rawValue),
            Int32(width), Int32(height)
        ) else { throw .creatingTexture }
        self.texture = texture
        
        Self.shared = self
    }
    
    deinit {
        SDL_DestroyTexture(texture)
        SDL_DestroyRenderer(renderer)
        SDL_DestroyWindow(window)
        SDL_Quit()
        Self.shared = nil
    }
    
    public var width: Int {
        var (width, height): (Int32, Int32) = (0, 0)
        SDL_GetWindowSize(window, &width, &height)
        return Int(width) / scale
    }
    public var height: Int {
        var (width, height): (Int32, Int32) = (0, 0)
        SDL_GetWindowSize(window, &width, &height)
        return Int(height) / scale
    }
    
    public var input: Input {
        var (wx, wy): (Int32, Int32) = (0, 0)
        SDL_GetWindowPosition(window, &wx, &wy)
        
        var (x, y): (Int32, Int32) = (0, 0)
        let buttons = SDL_GetMouseState(&x, &y)
        SDL_GetGlobalMouseState(&x, &y)
        
        x -= wx; y -= wy
        x /= Int32(scale); y /= Int32(scale)
        
        let left = buttons & 1 << 0 == 1 << 0
        let right = buttons & 1 << 2 == 1 << 2
        
        return .init(mouse: .init(x: Int(x), y: Int(y), left: left, right: right))
        
//        var count: Int32 = 0
//        let rawKeys = SDL_GetKeyboardState(&count)!
//        self.keys = UnsafeBufferPointer(start: rawKeys, count: Int(count))
    }
    
//    public func _renderer() -> SDLRenderer {
//        fatalError()
//    }
    
    public func blit(_ image: borrowing Image) throws(Error) {
        SDL_RenderClear(renderer)
        
        SDL_DestroyTexture(texture)
        guard let texture = SDL_CreateTexture(
            renderer,
            SDL_PIXELFORMAT_RGBA32.rawValue, Int32(SDL_TEXTUREACCESS_STREAMING.rawValue),
            Int32(image.width), Int32(image.height)
        ) else { throw .creatingTexture }
        self.texture = texture
        
        SDL_UpdateTexture(
            texture, nil, image.data,
            Int32(MemoryLayout<Color>.stride * image.width)
        )
        
        var (rw, rh): (Int32, Int32) = (0, 0)
        SDL_GetWindowSizeInPixels(window, &rw, &rh)
        var screenRect = SDL_Rect(x: 0, y: 0, w: rw, h: rh)
        SDL_RenderCopy(renderer, texture, nil, &screenRect)
        
        SDL_RenderPresent(renderer)
    }
    
    private static var event = SDL_Event()
    
    // TODO(!): Concurrent event stream.
    public func poll() -> Event? {
        if SDL_PollEvent(&Self.event) > 0 { Self.eventMap(Self.event.type) } else { nil }
    }
    
    private static func eventMap(_ raw: UInt32) -> Event {
        switch raw {
            case SDL_QUIT.rawValue: .quit
            case _: .unknown(raw)
        }
    }
    
    public enum Event {
        case quit
        case unknown(UInt32)
    }
    
    public enum Error: Swift.Error {
        case alreadyInitialized
        case initializingSDL
        case creatingWindow
        case creatingRenderer
        case creatingTexture
    }
}

public final class SDLWindow {
    fileprivate let handle: OpaquePointer
    
    public var width: Int {
        var (width, height): (Int32, Int32) = (0, 0)
        SDL_GetWindowSize(handle, &width, &height)
        return Int(width)
    }
    public var height: Int {
        var (width, height): (Int32, Int32) = (0, 0)
        SDL_GetWindowSize(handle, &width, &height)
        return Int(height)
    }
    
    public init(_ name: String? = nil, width: Int = 600, height: Int = 400) throws(InitError) {
        if Self.windowCount == 0 {
            guard SDL_Init(SDL_INIT_VIDEO) == 0 else { throw .initializingSDL }
        }
        
        guard let handle = SDL_CreateWindow(
            name,
            Int32(SDL_WINDOWPOS_CENTERED_MASK),
            Int32(SDL_WINDOWPOS_CENTERED_MASK),
            Int32(width), Int32(height),
            SDL_WINDOW_RESIZABLE.rawValue |
            SDL_WINDOW_ALLOW_HIGHDPI.rawValue
        ) else { throw .creatingWindow }
        self.handle = handle
        SDL_SetWindowMinimumSize(handle, Int32(width), Int32(height))
        
        Self.windowCount += 1
    }
    
    deinit {
        SDL_DestroyWindow(handle)
        Self.windowCount -= 1
        if Self.windowCount == 0 { SDL_Quit() }
    }
    
    public func createRenderer() throws(SDLRenderer.InitError) -> SDLRenderer {
        try .init(window: self)
    }
    
    public var input: Input {
        var (x, y): (Int32, Int32) = (0, 0)
        let buttons = SDL_GetMouseState(&x, &y)
        
        let left = buttons & 1 << 0 == 1 << 0
        let right = buttons & 1 << 2 == 1 << 2
        
        return .init(mouse: .init(x: Int(x), y: Int(y), left: left, right: right))
    }
    
    private static var windowCount = 0
    private static var event = SDL_Event()
    
    public static func poll() -> Event? {
        assert(windowCount > 0)
        return if SDL_PollEvent(&Self.event) > 0 { Self.eventMap(Self.event.type) } else { nil }
    }
    
    private static func eventMap(_ raw: UInt32) -> Event {
        switch raw {
            case SDL_QUIT.rawValue: .quit
            case _: .unknown(raw)
        }
    }
    
    public enum Event {
        case quit
        case unknown(UInt32)
    }
    
    public enum InitError: Error {
        case initializingSDL
        case creatingWindow
    }
}

public final class SDLTexture {
    
}

/// An SDL based hardware renderer which provides an efficient way of drawing rectangles.
public final class SDLRenderer {
    public private(set) weak var window: SDLWindow?
    fileprivate let handle: OpaquePointer
    
    public init(window: SDLWindow) throws(InitError) {
        guard let handle = SDL_CreateRenderer(
            window.handle, -1, SDL_RENDERER_ACCELERATED.rawValue | SDL_RENDERER_PRESENTVSYNC.rawValue
        ) else { throw .creating }
        self.handle = handle
        self.window = window
    }
    
    deinit { SDL_DestroyRenderer(handle) }
    
    public func clear(with color: Color = .black) {
        SDL_SetRenderDrawColor(handle, color.r, color.g, color.b, color.a)
        SDL_RenderClear(handle)
    }
    
    public func present() {
        SDL_RenderPresent(handle)
    }
    
    public func draw(_ drawable: some SDLDrawable, x: Int, y: Int) throws(RenderError) {
        guard window != nil else { throw .windowDoesNotExist }
        unowned var temp = self
        drawable.draw(into: &temp, x: x, y: y)
    }
    
    public enum InitError: Error {
        case creating
    }
    
    public enum RenderError: Error {
        case windowDoesNotExist
    }
}

/// A `Drawable` which can be efficiently rendered by the SDL hardware renderer.
public protocol SDLDrawable {
    func draw(into renderer: inout SDLRenderer, x: Int, y: Int)
}

extension Rectangle: SDLDrawable {
    public func draw(into renderer: inout SDLRenderer, x: Int, y: Int) {
        var rect = SDL_Rect(x: Int32(x), y: Int32(y), w: Int32(self.width), h: Int32(self.height))
        SDL_SetRenderDrawColor(renderer.handle, self.color.r, self.color.g, self.color.b, self.color.r)
        SDL_RenderFillRect(renderer.handle, &rect)
    }
}

#endif
