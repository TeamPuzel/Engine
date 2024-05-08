
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

public extension State {
    static func main() throws {
        guard SDL_Init(SDL_INIT_VIDEO) == 0 else { throw GameError.initializingSDL }
        defer { SDL_Quit() }
        
        guard let sdlWindow = SDL_CreateWindow(
            String(describing: Self.self),
            Int32(SDL_WINDOWPOS_CENTERED_MASK),
            Int32(SDL_WINDOWPOS_CENTERED_MASK),
            800, 600,
            SDL_WINDOW_ALLOW_HIGHDPI.rawValue |
            SDL_WINDOW_RESIZABLE.rawValue
        ) else { throw GameError.creatingWindow }
        SDL_SetWindowMinimumSize(sdlWindow, 800, 600)
        defer { SDL_DestroyWindow(sdlWindow) }
        
        guard let sdlRenderer = SDL_CreateRenderer(
            sdlWindow, -1, SDL_RENDERER_ACCELERATED.rawValue | SDL_RENDERER_PRESENTVSYNC.rawValue
        ) else { throw GameError.creatingRenderer }
        defer { SDL_DestroyRenderer(sdlRenderer) }
        
        var instance = try Self()
        var renderer = Renderer(width: 800 / 2, height: 600 / 2)
        
        var event = SDL_Event()
        
        loop: while true {
            while (SDL_PollEvent(&event) > 0) {
                switch event.type {
                    case SDL_QUIT.rawValue: break loop
                    case _: break
                }
            }
            
            try instance.update(input: Input())
            try instance.draw(into: &renderer)
            
            
        }
    }
}

private enum GameError: Error {
    case initializingSDL
    case creatingWindow
    case creatingRenderer
}
