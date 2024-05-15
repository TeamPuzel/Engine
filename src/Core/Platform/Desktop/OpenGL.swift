
#if canImport(GLAD) && canImport(SDL)
import GLAD
import SDL

@MainActor
public final class Window {
    private let window: OpaquePointer
    private let context: SDL_GLContext
    
    private static unowned var shared: Window!
    
    public init(name: String? = nil, width: Int = 800, height: Int = 600) throws(InitError) {
        guard Self.shared == nil else { throw .alreadyInitialized }
        guard SDL_Init(SDL_INIT_VIDEO) == 0 else { throw .initializingSDL }
        
        guard let window = SDL_CreateWindow(
            name,
            Int32(SDL_WINDOWPOS_CENTERED_MASK),
            Int32(SDL_WINDOWPOS_CENTERED_MASK),
            Int32(width), Int32(height),
            SDL_WINDOW_ALLOW_HIGHDPI.rawValue |
            SDL_WINDOW_RESIZABLE.rawValue |
            SDL_WINDOW_OPENGL.rawValue
        ) else { throw .creatingSDLWindow }
        self.window = window
        SDL_SetWindowMinimumSize(
            window, Int32(width), Int32(height)
        )
        SDL_ShowCursor(SDL_DISABLE)
        
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4)
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1)
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, Int32(SDL_GL_CONTEXT_PROFILE_CORE.rawValue))
        SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1)
        SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24)
        SDL_GL_SetSwapInterval(1)
        
        guard let context = SDL_GL_CreateContext(window) else {
            throw .creatingOpenGLContext
        }
        self.context = context
        
        gladLoadGLLoader(SDL_GL_GetProcAddress)
        
        print("""
        OpenGL initialized.
        Vendor: \(String(cString: glad_glGetString(GLenum(GL_VENDOR))!))
        Version: \(String(cString: glad_glGetString(GLenum(GL_VERSION))!))
        Renderer: \(String(cString: glad_glGetString(GLenum(GL_RENDERER))!))
        GLSL: \(String(cString: glad_glGetString(GLenum(GL_SHADING_LANGUAGE_VERSION))!))
        """)
        
        var boilerplate: UInt32 = 0
        glad_glGenVertexArrays(1, &boilerplate)
        glad_glBindVertexArray(boilerplate)
        glad_glEnableVertexAttribArray(boilerplate)
        
        glad_glClearColor(0, 0, 0, 1)
        glad_glEnable(GLenum(GL_DEPTH_TEST))
        glad_glEnable(GLenum(GL_CULL_FACE))
        glad_glEnable(GLenum(GL_BLEND))
        glad_glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))
    }
    
    deinit {
        // SAFETY: Copy values into the task, it will run past the deinit and cause UB otherwise.
        let task = Task.detached { @MainActor in
            let window = self.window
            let context = self.context
            SDL_GL_DeleteContext(context)
            SDL_DestroyWindow(window)
            SDL_Quit()
        }
    }
    
    public var width: Int {
        var (width, height): (Int32, Int32) = (0, 0)
        SDL_GL_GetDrawableSize(window, &width, &height)
        return Int(width)
    }
    
    public var height: Int {
        var (width, height): (Int32, Int32) = (0, 0)
        SDL_GL_GetDrawableSize(window, &width, &height)
        return Int(height)
    }
    
    public var isCursorLocked: Bool {
        get { SDL_GetRelativeMouseMode() == SDL_TRUE }
        set { SDL_SetRelativeMouseMode(newValue ? SDL_TRUE : SDL_FALSE) }
    }
    
    public var input: Input {
        var (x, y): (Int32, Int32) = (0, 0)
        let buttons = SDL_GetMouseState(&x, &y)
        
        let left = buttons & 1 << 0 == 1 << 0
        let right = buttons & 1 << 2 == 1 << 2
        
        return .init(mouse: .init(x: Int(x), y: Int(y), left: left, right: right))
    }
    
    public func swap() { SDL_GL_SwapWindow(window) }
    public func clear() { glad_glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)) }
    
    private var event = SDL_Event()
    
    public func poll() -> Event? {
        if SDL_PollEvent(&event) > 0 { Self.eventMap(event.type) } else { nil }
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
        case alreadyInitialized
        case initializingSDL
        case creatingSDLWindow
        case creatingOpenGLContext
    }
}

@MainActor
public final class Texture {
    // SAFETY: This has to be a strong reference, if the window is deinitialized first
    // it will take SDL and OpenGL with it, potentially preventing correct deinit of the texture.
    private let window: Window
    fileprivate let handle: UInt32
    
    init(_ window: Window, image: borrowing Image) throws(InitError) {
        self.window = window
        
        var handle: UInt32 = 0
        glad_glGenTextures(1, &handle)
        guard handle != 0 else { throw .creatingTexture }
        self.handle = handle
        
        self.write(image: image)
    }
    
    deinit {
        // SAFETY: Copy values into the task, it will run past the deinit and cause UB otherwise.
        Task.detached { @MainActor in
            var handle = self.handle
            glad_glDeleteTextures(1, &handle)
        }
    }
    
    public func bind() { glad_glBindTexture(GLenum(GL_TEXTURE_2D), handle) }
    public func unbind() { glad_glBindTexture(GLenum(GL_TEXTURE_2D), 0) }
    
    public func write(image: borrowing Image) {
        self.bind()
        defer { self.unbind() }
        
        glad_glTexImage2D(
            GLenum(GL_TEXTURE_2D),
            0,
            GL_RGBA,
            GLsizei(image.width),
            GLsizei(image.height),
            0,
            GLenum(GL_RGBA),
            GLenum(GL_UNSIGNED_BYTE),
            image.data
        )
        
        glad_glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_NEAREST)
        glad_glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_NEAREST)
        glad_glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_REPEAT)
        glad_glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_REPEAT)
    }
    
    public enum InitError: Error {
        case creatingTexture
    }
}

#endif
