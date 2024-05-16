
import Cocoa
import MetalKit
import Assets

fileprivate let interface = UnsafeTGAPointer(UI_TGA).grid(itemWidth: 16, itemHeight: 16)
fileprivate let cursor = interface[0, 0]
fileprivate let cursorPressed = interface[1, 0]
fileprivate let terrain = UnsafeTGAPointer(TERRAIN_TGA)

@main
public final class Game {
    public let world: World
    private var timer = Timer()
    
    public init() async {
        self.world = await World(name: "Test")
    }
    
    public func frame(input: Input, renderer: inout Image) {
        let elapsed = timer.lap()
        
        renderer.clear()
        renderer.text("Frame: \(elapsed)", x: 2, y: 2)
        renderer.draw(input.mouse.left ? cursorPressed : cursor, x: input.mouse.x - 1, y: input.mouse.y - 1)
    }
    
    static func main() async {
        let instance = await Self()
        
        let delegate = AppDelegate(game: instance)
        let app = NSApplication.shared
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.activate()
        app.run()
    }
}

public struct PassthroughVertex: BitwiseCopyable {
    public let x, y, z, u, v: Float
    
    public init(x: Float, y: Float, z: Float, u: Float, v: Float) {
        self.x = x
        self.y = y
        self.z = z
        self.u = u
        self.v = v
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    public var game: Game
    public var interface: Image!
    
    public var window: NSWindow!
    private var metalView: MTKView!
    private var renderer: Renderer!
    
    public init(game: Game) { self.game = game }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        self.interface = .init(width: 400, height: 300)
        self.window = .init(
            contentRect: .init(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.minSize = .init(width: 800, height: 600)
        window.title = "Minecraft"
        
        let menu = NSMenu()
        let main = NSMenuItem()
        main.submenu = NSMenu()
        main.submenu!.items = [
            NSMenuItem(title: "Quit Minecraft", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        ]
        menu.addItem(main)
        NSApplication.shared.mainMenu = menu
        
        self.metalView = MTKView(frame: window.contentView!.bounds, device: MTLCreateSystemDefaultDevice())
        metalView.autoresizingMask = [.width, .height]
        metalView.preferredFramesPerSecond = .max
        window.contentView = metalView
        
        self.renderer = Renderer(self, device: metalView.device!)
        metalView.delegate = renderer
        
        window.makeKeyAndOrderFront(nil)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

final class Renderer: NSObject, MTKViewDelegate {
    private let parent: AppDelegate
    private var commandQueue: (any MTLCommandQueue)!
    private var pipelineState: (any MTLRenderPipelineState)!
    private var vertexBuffer: (any MTLBuffer)!
    private var texture: (any MTLTexture)!
    private var sampler: (any MTLSamplerState)!
    
    init(_ parent: AppDelegate, device: any MTLDevice) {
        self.parent = parent
        super.init()
        commandQueue = device.makeCommandQueue()
        createPipelineState(device: device)
        createVertexBuffer(device: device)
        createTextureState(device: device)
        createSamplerState(device: device)
    }
    
    func createTextureState(device: any MTLDevice) {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .rgba8Unorm
        textureDescriptor.width = parent.interface.width
        textureDescriptor.height = parent.interface.height
        textureDescriptor.usage = [.shaderRead]
        textureDescriptor.storageMode = .shared
        
        let texture = device.makeTexture(descriptor: textureDescriptor)!
        self.texture = texture
        
        let bytesPerPixel = MemoryLayout<Color>.stride
        let bytesPerRow = bytesPerPixel * parent.interface.width
        
        texture.replace(
            region: MTLRegionMake2D(0, 0, parent.interface.width, parent.interface.height),
            mipmapLevel: 0,
            withBytes: parent.interface.data,
            bytesPerRow: bytesPerRow
        )
    }
    
    func updateTexture() {
        let bytesPerPixel = MemoryLayout<Color>.stride
        let bytesPerRow = bytesPerPixel * parent.interface.width
        
        texture.replace(
            region: MTLRegionMake2D(0, 0, parent.interface.width, parent.interface.height),
            mipmapLevel: 0,
            withBytes: parent.interface.data,
            bytesPerRow: bytesPerRow
        )
    }
    
    func createSamplerState(device: any MTLDevice) {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .nearest
        samplerDescriptor.magFilter = .nearest
        samplerDescriptor.mipFilter = .notMipmapped
        samplerDescriptor.maxAnisotropy = 1
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .repeat
        samplerDescriptor.normalizedCoordinates = true
        self.sampler = device.makeSamplerState(descriptor: samplerDescriptor)
    }
    
    func createPipelineState(device: any MTLDevice) {
        let compileOptions = MTLCompileOptions()
        compileOptions.fastMathEnabled = true
        let library = try! device.makeLibrary(source: String(cString: SHADERS_METAL), options: compileOptions)
        let vertexFunction = library.makeFunction(name: "vertex_passthrough")
        let fragmentFunction = library.makeFunction(name: "fragment_passthrough")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true;
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add;
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add;
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha;
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha;
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha;
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha;
        
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    func createVertexBuffer(device: any MTLDevice) {
        let vertices: [PassthroughVertex] = [
            .init(x: -1, y: 1, z: 0, u: 0, v: 0),
            .init(x: -1, y: -1, z: 0, u: 0, v: 1),
            .init(x: 1, y: 1, z: 0, u: 1, v: 0),
            
            .init(x: 1, y: 1, z: 0, u: 1, v: 0),
            .init(x: -1, y: -1, z: 0, u: 0, v: 1),
            .init(x: 1, y: -1, z: 0, u: 1, v: 1)
        ]
        
        vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<PassthroughVertex>.stride * vertices.count,
            options: []
        )
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let scale = parent.window.backingScaleFactor
        parent.interface.resize(width: Int(size.width / 2 / scale), height: Int(size.height / 2 / scale))
        createTextureState(device: view.device!)
    }
    
    var isMouseHidden = false
    
    func draw(in view: MTKView) {
        let upsideMouse = parent.window.mouseLocationOutsideOfEventStream
        if parent.window.contentView!.frame.contains(upsideMouse) {
            if !isMouseHidden { NSCursor.hide() }
            isMouseHidden = true
        } else {
            if isMouseHidden { NSCursor.unhide() }
            isMouseHidden = false
        }
        
        let mouse = NSPoint(x: upsideMouse.x, y: parent.window.contentView!.frame.height - upsideMouse.y)
        let btn = NSEvent.pressedMouseButtons
        let left = btn & 1 << 0 == 1 << 0
        parent.game.frame(
            input: .init(mouse: .init(x: Int(mouse.x / 2), y: Int(mouse.y / 2), left: left, right: false)),
            renderer: &parent.interface
        )
        updateTexture()
        
        guard let drawable = view.currentDrawable else { return }
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.setFragmentSamplerState(sampler, index: 0)
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
