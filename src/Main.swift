
import Assets

fileprivate let interface = UnsafeTGAPointer(UI_TGA).grid(itemWidth: 16, itemHeight: 16)
fileprivate let cursor = interface[0, 0]
fileprivate let cursorPressed = interface[1, 0]
fileprivate let terrain = UnsafeTGAPointer(TERRAIN_TGA)

@main @MainActor
public final class Game {
    public init() {}
    
    private var timer = Timer()
    
    public func frame(input: Input, renderer: inout Image) {
        let elapsed = timer.lap()
        
        renderer.clear(with: .init(luminosity: 35))
        renderer.text("Frame: \(elapsed)", x: 2, y: 8)
        renderer.draw(input.mouse.left ? cursorPressed : cursor, x: input.mouse.x - 1, y: input.mouse.y - 1)
    }
    
    static func main() async throws {
        let window = try Window(name: "Minecraft")
//        let terrainTexture = try Texture(window)
//        let terrainShader = try Shader(window, vertex: String(cString: TERRAIN_VS), fragment: String(cString: TERRAIN_FS))
//        let terrainObject = try DrawObject<BlockVertex>(window, texture: terrainTexture, shader: terrainShader, mesh: [])
        
        let interfaceTexture = try Texture(window)
        let interfaceShader = try Shader(
            window, vertex: String(cString: PASSTHROUGH_VS), fragment: String(cString: PASSTHROUGH_FS)
        )
        let interfaceObject = try DrawObject<InterfaceVertex>(
            window, texture: interfaceTexture, shader: interfaceShader, mesh: [
                // Triangle 1: bottom-left to top-right diagonal
                .init(x: -1.0, y: -1.0, u: 0.0, v: 0.0), // Bottom-left
                .init(x:  1.0, y: -1.0, u: 1.0, v: 0.0), // Bottom-right
                .init(x: -1.0, y:  1.0, u: 0.0, v: 1.0), // Top-left

                // Triangle 2: top-left to bottom-right diagonal
                .init(x: -1.0, y:  1.0, u: 0.0, v: 1.0), // Top-left
                .init(x:  1.0, y: -1.0, u: 1.0, v: 0.0), // Bottom-right
                .init(x:  1.0, y:  1.0, u: 1.0, v: 1.0)  // Top-right
            ]
        )
        
        var image = Image(width: window.width, height: window.height)
        let instance = Self()
        
        loop:
        while true {
            while let event = window.poll() {
                switch event {
                    case .quit: break loop
                    case _: break
                }
            }
            
            window.clear()
            image.resize(width: window.width, height: window.height)
            instance.frame(input: window.input, renderer: &image)
            
            interfaceObject.texture.write(image: image)
            interfaceObject.sync()
            window.draw(interfaceObject)
            
            window.swap()
        }
    }
}

import GLAD

public struct InterfaceVertex: Vertex {
    public let x, y, z, u, v: Float
    
    public init(x: Float, y: Float, z: Float = 0, u: Float, v: Float) {
        self.x = x
        self.y = y
        self.z = z
        self.u = u
        self.v = v
    }
    
    public static func bindLayout() {
        glad_glVertexAttribPointer(
            0,
            3,
            GLenum(GL_FLOAT),
            GLboolean(GL_FALSE),
            GLsizei(MemoryLayout<BlockVertex>.stride),
            UnsafeRawPointer(bitPattern: 0)
        )
        glad_glEnableVertexAttribArray(0)
        
        glad_glVertexAttribPointer(
            1,
            2,
            GLenum(GL_FLOAT),
            GLboolean(GL_FALSE),
            GLsizei(MemoryLayout<BlockVertex>.stride),
            UnsafeRawPointer(bitPattern: MemoryLayout<BlockVertex>.offset(of: \.u)!)
        )
        glad_glEnableVertexAttribArray(1)
    }
}

// SAFETY: This is unsafe.
public struct BlockVertex: Vertex {
    public let x, y, z, u, v: Float
    public let color: VertexColor
    
    public init(x: Float, y: Float, z: Float, u: Float, v: Float, color: VertexColor) {
        self.x = x
        self.y = y
        self.z = z
        self.u = u
        self.v = v
        self.color = color
    }
    
    public static func bindLayout() {
        glad_glVertexAttribPointer(
            0,
            3,
            GLenum(GL_FLOAT),
            GLboolean(GL_FALSE),
            GLsizei(MemoryLayout<BlockVertex>.stride),
            UnsafeRawPointer(bitPattern: 0)
        )
        glad_glEnableVertexAttribArray(0)
        
        glad_glVertexAttribPointer(
            1,
            2,
            GLenum(GL_FLOAT),
            GLboolean(GL_FALSE),
            GLsizei(MemoryLayout<BlockVertex>.stride),
            UnsafeRawPointer(bitPattern: MemoryLayout<BlockVertex>.offset(of: \.u)!)
        )
        glad_glEnableVertexAttribArray(1)
        
        glad_glVertexAttribPointer(
            2,
            4,
            GLenum(GL_FLOAT),
            GLboolean(GL_FALSE),
            GLsizei(MemoryLayout<BlockVertex>.stride),
            UnsafeRawPointer(bitPattern: MemoryLayout<BlockVertex>.offset(of: \.color)!)
        )
        glad_glEnableVertexAttribArray(2)
    }
}

public extension Block {
    func mesh(into existing: inout [BlockVertex]) {
        
    }
}
