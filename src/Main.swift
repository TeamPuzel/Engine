
import Cocoa
import MetalKit
import Assets

fileprivate let interface = UnsafeTGAPointer(UI_TGA).grid(itemSide: 16)
fileprivate let cursor = interface[0, 0]
fileprivate let cursorPressed = interface[1, 0]
fileprivate let terrain = UnsafeTGAPointer(TERRAIN_TGA)

@main
public final class Game {
    public let world: World
    
    private var timer = Timer()
    
    public init() {
        self.world = World(name: "Test")
    }
    
    public func frame(input: Input, renderer: inout Image) {
        let elapsed = timer.lap()
        
        renderer.clear()
        world.frame(input: input, renderer: &renderer)
        
        renderer.text("Frame: \(elapsed)", x: 2, y: 2)
        renderer.text("Position: \(world.primaryPosition)", x: 2, y: 2 + 6)
        renderer.text("Rotation: \(world.primaryOrientation)", x: 2, y: 2 + 6 * 2)
        renderer.draw(input.mouse.left ? cursorPressed : cursor, x: input.mouse.x - 1, y: input.mouse.y - 1)
    }
    
    static func main() {
        let instance = Self()
        let delegate = AppDelegate(game: instance)
        let app = NSApplication.shared
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }
}

// MARK: - Vertices

public struct PassthroughVertex: Hashable, Sendable, BitwiseCopyable {
    public let x, y, z, u, v: Float
    
    public var position: Vector3<Float> { .init(x: x, y: y, z: z) }
}

public struct BlockVertex: Hashable, Sendable, BitwiseCopyable {
    public let x, y, z, u, v, r, g, b, a: Float
    
    public var position: Vector3<Float> { .init(x: x, y: y, z: z) }
}

// MARK: - Application

final class AppDelegate: NSObject, NSApplicationDelegate {
    public var game: Game
    public var interface: Image!
    
    public var window: NSWindow!
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
        
        let metalView = MTKView(frame: window.contentView!.bounds, device: MTLCreateSystemDefaultDevice())
        metalView.autoresizingMask = [.width, .height]
        metalView.preferredFramesPerSecond = .max
        metalView.depthStencilPixelFormat = .depth32Float
        window.contentView = metalView
        
        self.renderer = Renderer(self, device: metalView.device!)
        metalView.delegate = renderer
        
        NSApplication.shared.activate()
        window.makeKeyAndOrderFront(nil)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

// MARK: - Metal Renderer

@MainActor
final class Renderer: NSObject, MTKViewDelegate {
    private unowned let parent: AppDelegate
    private var commandQueue: (any MTLCommandQueue)!
    
    private var shaderLibrary: (any MTLLibrary)!
    
    private var depthStencilState: (any MTLDepthStencilState)!
    
    private var interfacePipelineState: (any MTLRenderPipelineState)!
    private var interfaceVertexBuffer: (any MTLBuffer)!
    private var interfaceTexture: (any MTLTexture)!
    
    private var terrainPipelineState: (any MTLRenderPipelineState)!
    private var terrainVertexCount = 0
    private var terrainVertexBuffer: (any MTLBuffer)!
    private var terrainTexture: (any MTLTexture)!
    
    private var sampler: (any MTLSamplerState)!
    
    private var terrainUniformBuffer: (any MTLBuffer)!
    
    init(_ parent: AppDelegate, device: any MTLDevice) {
        self.parent = parent
        super.init()
        commandQueue = device.makeCommandQueue()
        createShaderLibrary(device: device)
        
        createDepthStencilState(device: device)
        
        createInterfacePipelineState(device: device)
        createTerrainPipelineState(device: device)

        createInterfaceVertexBuffer(device: device)
        createInterfaceTextureState(device: device)
        
        createTerrainVertexBuffer(device: device)
        createTerrainTextureState(device: device)
        
        createSamplerState(device: device)
        
        self.terrainUniformBuffer = device.makeBuffer(
            length: MemoryLayout<Matrix<Float>>.stride,
            options: []
        )
    }
    
    func createDepthStencilState(device: any MTLDevice) {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilDescriptor.depthCompareFunction = .less
        self.depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
    }
    
    func createTerrainTextureState(device: any MTLDevice) {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .rgba8Unorm
        textureDescriptor.width = Block.atlas.width
        textureDescriptor.height = Block.atlas.height
        textureDescriptor.usage = [.shaderRead]
        textureDescriptor.storageMode = .shared
        textureDescriptor.mipmapLevelCount = 9
        
        let texture = device.makeTexture(descriptor: textureDescriptor)!
        self.terrainTexture = texture
        
        let bytesPerPixel = MemoryLayout<Color>.stride
        let bytesPerRow = bytesPerPixel * Block.atlas.width
        
        texture.replace(
            region: MTLRegionMake2D(0, 0, Block.atlas.width, Block.atlas.height),
            mipmapLevel: 0,
            withBytes: Block.atlas.flatten().data,
            bytesPerRow: bytesPerRow
        )
        
        // Generate mipmaps
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder()!
        blitCommandEncoder.generateMipmaps(for: texture)
        blitCommandEncoder.endEncoding()
        commandBuffer.commit()
    }
    
    func createInterfaceTextureState(device: any MTLDevice) {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .rgba8Unorm
        textureDescriptor.width = parent.interface.width
        textureDescriptor.height = parent.interface.height
        textureDescriptor.usage = [.shaderRead]
        textureDescriptor.storageMode = .shared
        
        let texture = device.makeTexture(descriptor: textureDescriptor)!
        self.interfaceTexture = texture
        
        let bytesPerPixel = MemoryLayout<Color>.stride
        let bytesPerRow = bytesPerPixel * parent.interface.width
        
        texture.replace(
            region: MTLRegionMake2D(0, 0, parent.interface.width, parent.interface.height),
            mipmapLevel: 0,
            withBytes: parent.interface.data,
            bytesPerRow: bytesPerRow
        )
    }
    
    func updateInterfaceTexture() {
        let bytesPerPixel = MemoryLayout<Color>.stride
        let bytesPerRow = bytesPerPixel * parent.interface.width
        
        guard parent.interface.width == interfaceTexture.width &&
                parent.interface.height == interfaceTexture.height else { return }
        interfaceTexture.replace(
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
        samplerDescriptor.mipFilter = .linear // Maybe separate for 3d?
        samplerDescriptor.maxAnisotropy = 8
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .repeat
        samplerDescriptor.normalizedCoordinates = true
        self.sampler = device.makeSamplerState(descriptor: samplerDescriptor)
    }
    
    func createShaderLibrary(device: any MTLDevice) {
        let compileOptions = MTLCompileOptions()
        compileOptions.fastMathEnabled = true
        self.shaderLibrary = try! device.makeLibrary(source: String(cString: SHADERS_METAL), options: compileOptions)
    }
    
    func createInterfacePipelineState(device: any MTLDevice) {
        let vertexFunction = shaderLibrary.makeFunction(name: "vertex_passthrough")
        let fragmentFunction = shaderLibrary.makeFunction(name: "fragment_passthrough")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float // ???????????
        
        self.interfacePipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    func createTerrainPipelineState(device: any MTLDevice) {
        let vertexFunction = shaderLibrary.makeFunction(name: "vertex_terrain")
        let fragmentFunction = shaderLibrary.makeFunction(name: "fragment_terrain")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        self.terrainPipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    func createInterfaceVertexBuffer(device: any MTLDevice) {
        let vertices: [PassthroughVertex] = [
            .init(x: -1, y: 1, z: 0, u: 0, v: 0),
            .init(x: -1, y: -1, z: 0, u: 0, v: 1),
            .init(x: 1, y: 1, z: 0, u: 1, v: 0),
            
            .init(x: 1, y: 1, z: 0, u: 1, v: 0),
            .init(x: -1, y: -1, z: 0, u: 0, v: 1),
            .init(x: 1, y: -1, z: 0, u: 1, v: 1)
        ]
        
        self.interfaceVertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<PassthroughVertex>.stride * vertices.count,
            options: []
        )
    }
    
    func createTerrainVertexBuffer(device: any MTLDevice) {
        let vertices = parent.game.world.unifiedMesh
        self.terrainVertexCount = vertices.count
        guard terrainVertexCount > 0 else { return }
        
        self.terrainVertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<BlockVertex>.stride * vertices.count,
            options: []
        )
    }
    
    nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        MainActor.assumeIsolated {
            let scale = parent.window.backingScaleFactor
            parent.interface.resize(width: Int(size.width / 2 / scale), height: Int(size.height / 2 / scale))
            createInterfaceTextureState(device: view.device!)
        }
    }
    
    var isMouseHidden = false
    
    nonisolated func draw(in view: MTKView) {
        MainActor.assumeIsolated {
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
            let right = btn & 1 << 1 == 1 << 1
            parent.game.frame(
                input: .init(mouse: .init(x: Int(mouse.x / 2), y: Int(mouse.y / 2), left: left, right: right)),
                renderer: &parent.interface
            )
            updateInterfaceTexture()
            
            guard let drawable = view.currentDrawable else { return }
            guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
            
            renderPassDescriptor.depthAttachment.texture = view.depthStencilTexture
            renderPassDescriptor.depthAttachment.loadAction = .clear
            renderPassDescriptor.depthAttachment.storeAction = .store
            renderPassDescriptor.depthAttachment.clearDepth = 1.0
            
            let commandBuffer = commandQueue.makeCommandBuffer()!
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
            
            renderEncoder.setDepthStencilState(depthStencilState)
            
            // Matrix
            let size = parent.window.contentView!.frame
            let bufferPointer = terrainUniformBuffer.contents()
            var mat = parent.game.world.primaryMatrix(width: Float(size.width), height: Float(size.height))
            memcpy(bufferPointer, &mat, MemoryLayout<Matrix<Float>>.size)
            
            // Render terrain
            if terrainVertexCount > 0 {
                renderEncoder.setRenderPipelineState(terrainPipelineState)
                renderEncoder.setVertexBuffer(terrainVertexBuffer, offset: 0, index: 0)
                renderEncoder.setFragmentTexture(terrainTexture, index: 0)
                renderEncoder.setFragmentSamplerState(sampler, index: 0)
                renderEncoder.setVertexBuffer(terrainUniformBuffer, offset: 0, index: 1)
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: terrainVertexCount)
            }
            
            // Render interface
            renderEncoder.setRenderPipelineState(interfacePipelineState)
            renderEncoder.setVertexBuffer(interfaceVertexBuffer, offset: 0, index: 0)
            renderEncoder.setFragmentTexture(interfaceTexture, index: 0)
            renderEncoder.setFragmentSamplerState(sampler, index: 0)
            
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            renderEncoder.endEncoding()
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
