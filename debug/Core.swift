
import Assets

/// This main class is for testing of the 2d platform independent API.
public final class CoreTest {
    static let interface = UnsafeTGAPointer(UI_TGA).grid(itemWidth: 16, itemHeight: 16)
    static let cursor = interface[0, 0]
    static let cursorPressed = interface[1, 0]

    static let hotbarSlot = UnsafeTGAPointer(UI_TGA).grid(itemWidth: 32, itemHeight: 32)[0, 1]
    static let heart = UnsafeTGAPointer(UI_TGA).slice(x: 0, y: 16, width: 13, height: 12)
    
    public init() {}
    
    private var timer = Timer()
    
    public func frame(input: Input, renderer: inout Image) {
        let elapsed = timer.lap()
        
        renderer.clear(with: .init(luminosity: 35))
        
        hotbar.traverse(input: input, x: (renderer.width - hotbar.width) / 2, y: renderer.height - hotbar.height - 4)
        renderer.draw(hotbar, x: (renderer.width - hotbar.width) / 2, y: renderer.height - hotbar.height - 4)
        
        renderer.text("\(input.mouse)", x: 2, y: 2)
        renderer.text("Frame: \(elapsed)", x: 2, y: 8)
        renderer.draw(input.mouse.left ? Self.cursorPressed : Self.cursor, x: input.mouse.x - 1, y: input.mouse.y - 1)
    }
    
    private var hearts: Int = 1
    private var hover: Int = 0
    
    private var hotbar: some RecursiveDrawable {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 2) {
                for _ in 1...hearts { Self.heart }
            }
            HStack(spacing: 2) {
                for i in 1...9 {
                    ZStack {
                        Self.hotbarSlot
                            .onClick { self.hearts = i }
                            .onHover { self.hover = i }
                        if hover != i {
                            Text("\(i)")
                        } else {
                            Text("Hey!")
                        }
                    }
                }
            }
        }
    }
    
    static func main() throws {
        let sdl = try SDL()
        var image = Image(width: sdl.width, height: sdl.height)
        let instance = Self()
        
        loop:
        while true {
            while let event = sdl.poll() {
                switch event {
                    case .quit: break loop
                    case _: break
                }
            }
            
            image.resize(width: sdl.width, height: sdl.height)
            instance.frame(input: sdl.input, renderer: &image)
            try sdl.blit(image)
        }
    }
}
