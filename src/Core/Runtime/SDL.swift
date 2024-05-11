
import SDL

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
//        SDL_SetTextureScaleMode(texture, SDL_ScaleModeNearest)
        
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
    
    public func _renderer() -> SDLRenderer {
        fatalError()
    }
    
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
