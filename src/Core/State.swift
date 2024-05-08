
import SDL

/// A target independent game that can be run by a runtime for any platform.
public protocol State {
    init() throws
    // TODO(!!): Not actually called reliably. Make this framerate independed like the Rust version.
    /// Called reliably every tick.
    mutating func update(input: borrowing Input) throws
    /// Called every frame, does not guarantee timing and can even be skipped.
    mutating func draw(into renderer: inout Renderer) throws
}

fileprivate let minimumWidth = 200
fileprivate let minimumHeight = 150
fileprivate let pixelScale = 2

public extension State {
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
        var renderer = Renderer(width: minimumWidth, height: minimumHeight)
        
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
                    Int32(renderer.display.width), Int32(renderer.display.height)
                ) else { throw GameError.creatingTexture }
                sdlTexture = newTexture
            }
            
            try instance.update(input: Input(window: sdlWindow))
            try instance.draw(into: &renderer)
            
            SDL_UpdateTexture(
                sdlTexture, nil, renderer.display.data,
                Int32(MemoryLayout<Color>.stride * renderer.display.width)
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

public struct Input {
    public let mouse: (x: Int, y: Int)
    
    fileprivate init(window: OpaquePointer) {
        var (wx, wy): (Int32, Int32) = (0, 0)
        SDL_GetWindowPosition(window, &wx, &wy)
        
        var (x, y): (Int32, Int32) = (0, 0)
        SDL_GetMouseState(&x, &y)
        SDL_GetGlobalMouseState(&x, &y)
        
        x -= wx; y -= wy
        
        x /= Int32(pixelScale); y /= Int32(pixelScale)
        
        self.mouse = (Int(x), Int(y))
    }
}
