
#if canImport(GLAD) && canImport(SDL)
import GLAD
import SDL

/// An OpenGL window backed by SDL for relative platform independence.
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
//        SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, Int32(SDL_GL_CONTEXT_DEBUG_FLAG.rawValue))
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
        let window = self.window
        let context = self.context
        SDL_GL_DeleteContext(context)
        SDL_DestroyWindow(window)
        SDL_Quit()
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
    
    public func draw<V>(_ object: DrawObject<V>, matrix: Matrix<Float> = .identity) {
        precondition(object.window === self)
        object.bind()
        
        let sampler = object.shader.uniformLocation(name: "texture_id")
        let transform = object.shader.uniformLocation(name: "transform")
        glad_glUniform1i(sampler, 0)
        
        // What the heck
        withUnsafePointer(to: matrix.data) { ptr in
            let raw = UnsafeRawBufferPointer(start: ptr, count: 4 * 4)
            raw.withMemoryRebound(to: Float.self) { ptr in
                glad_glUniformMatrix4fv(
                    transform,
                    1, GLboolean(GL_TRUE),
                    ptr.baseAddress
                )
            }
        }
        
        glad_glDrawArrays(GLenum(GL_TRIANGLES), 0, object.syncedCount)
        object.unbind()
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
    fileprivate let window: Window
    fileprivate let handle: UInt32
    
    public init(_ window: Window) throws(InitError) {
        self.window = window
        
        var handle: UInt32 = 0
        glad_glGenTextures(1, &handle)
        guard handle != 0 else { throw .creatingTexture }
        self.handle = handle
    }
    
    public convenience init(_ window: Window, image: borrowing Image) throws(InitError) {
        try self.init(window)
        self.write(image: image)
    }
    
    deinit {
        var handle = self.handle
        glad_glDeleteTextures(1, &handle)
    }
    
    public func bind() { glad_glBindTexture(GLenum(GL_TEXTURE_2D), handle) }
    public func unbind() { glad_glBindTexture(GLenum(GL_TEXTURE_2D), 0) }
    
    public func write(image: borrowing Image) {
        self.bind()
        
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

@MainActor
public final class Shader {
    fileprivate let window: Window
    fileprivate let handle: UInt32
    
    public init(_ window: Window, vertex: String, fragment: String) throws(CompileError) {
        self.window = window
        
        let handle = glad_glCreateProgram()
        
        let v = try Self.compile(vertex, as: .vertex)
        let f = try Self.compile(fragment, as: .fragment)
        
        glad_glAttachShader(handle, v)
        glad_glAttachShader(handle, f)
        glad_glLinkProgram(handle)
        glad_glValidateProgram(handle)
        
        glad_glDeleteShader(v)
        glad_glDeleteShader(f)
        
        self.handle = handle
    }
    
    deinit {
        let handle = handle
        glad_glDeleteProgram(handle)
    }
    
    public func bind() {
        glad_glUseProgram(handle)
    }
    
    public func unbind() {
        glad_glUseProgram(0)
    }
    
    public func uniformLocation(name: String) -> Int32 {
        self.bind()
        return glad_glGetUniformLocation(handle, name)
    }
    
    private static func compile(_ source: String, as kind: Kind) throws(CompileError) -> UInt32 {
        let id = glad_glCreateShader(GLenum(kind == .vertex ? GL_VERTEX_SHADER : GL_FRAGMENT_SHADER))
        source.withCString { ptr in
            withUnsafePointer(to: ptr) { ptrPtr in // I swear OpenGL is something else
                glad_glShaderSource(id, 1, ptrPtr, nil)
            }
        }
        glad_glCompileShader(id)
        
        var result: Int32 = 0
        glad_glGetShaderiv(id, GLenum(GL_COMPILE_STATUS), &result)
        guard result != 0 else {
            var count: Int32 = 0
            glad_glGetShaderiv(id, GLenum(GL_INFO_LOG_LENGTH), &count)
            let message = withUnsafeTemporaryAllocation(of: CChar.self, capacity: Int(count + 1)) { ptr in
                glad_glGetShaderInfoLog(id, count, &count, ptr.baseAddress)
                return String(cString: ptr.baseAddress!)
            }
            throw kind == .vertex ? .vertex(message) : .fragment(message)
        }
        
        return id
    }
    
    private enum Kind { case vertex, fragment }
    
    public enum CompileError: Error {
        case vertex(String)
        case fragment(String)
    }
}

public struct VertexColor: BitwiseCopyable {
    public var r, g, b, a: Float
    
    public init(r: Float, g: Float, b: Float, a: Float) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
    
    public init(luminosity: Float, a: Float = 1) {
        self.r = luminosity
        self.g = luminosity
        self.b = luminosity
        self.a = a
    }
}

/// An *unsafe* protocol for vertex types.
///
/// # Safety
/// A vertex must be a trivial type as it will be memory copied onto the GPU.
/// Since memory representation of Swift structs is technically not guaranteed it is inherently
/// unsafe to implement, unless it is for a C struct (declared in a header file).
///
/// I don't want to have to split my code up into multiple languages so I will ignore that,
/// however it is important to note as it may eventually cause issues.
public protocol Vertex: BitwiseCopyable {
    static func bindLayout()
}

@MainActor
public final class DrawObject<V: Vertex> {
    fileprivate let window: Window
    fileprivate let handle: UInt32
    public let texture: Texture
    public let shader: Shader
    public var mesh: [V]
    fileprivate var syncedCount: Int32 = 0
    
    public init(_ window: Window, texture: Texture, shader: Shader, mesh: [V]) throws(DrawObjectInitError) {
        precondition(window === texture.window && window === shader.window)
        self.window = window
        self.texture = texture
        self.mesh = mesh
        self.shader = shader
        
        var handle: UInt32 = 0
        glad_glGenBuffers(1, &handle)
        guard handle != 0 else { throw .creatingBuffer }
        self.handle = handle
    }
    
    deinit {
        var handle = self.handle
        glad_glDeleteBuffers(1, &handle)
    }
    
    public func sync() {
        self.bind()
        mesh.withUnsafeBytes { ptr in
            glad_glBufferData(
                GLenum(GL_ARRAY_BUFFER),
                MemoryLayout<V>.stride * mesh.count,
                ptr.baseAddress,
                GLenum(GL_DYNAMIC_DRAW)
            )
        }
        syncedCount = Int32(mesh.count)
    }
    
    public func bind() {
        glad_glBindBuffer(GLenum(GL_ARRAY_BUFFER), handle)
        V.bindLayout()
        texture.bind()
        shader.bind()
    }
    
    public func unbind() {
        glad_glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
        texture.unbind()
        shader.unbind()
    }
}

public enum DrawObjectInitError: Error {
    case creatingBuffer
}

#endif
