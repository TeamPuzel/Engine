
import Assets

let interface = UnsafeTGAPointer(UI_TGA).grid(itemWidth: 16, itemHeight: 16)
let cursor = interface[0, 0]
let cursorPressed = interface[1, 0]

let hotbarSlot = UnsafeTGAPointer(UI_TGA).grid(itemWidth: 32, itemHeight: 32)[0, 1]
let heart = UnsafeTGAPointer(UI_TGA).slice(x: 0, y: 16, width: 13, height: 12)

@main
public final class World {
    public private(set) var plane: Plane!
    public private(set) var player: Entity!
    
    public init() {
        self.plane = Plane.Material(world: self)
        self.player = Entity.Human()
        self.plane.add(entity: self.player)
    }
    
    public func frame(input: Input, renderer: inout Image) {
        hotbar.traverse(input: input, x: (renderer.width - hotbar.width) / 2, y: renderer.height - hotbar.height - 4)
        
        renderer.clear(with: .init(luminosity: 35))
        renderer.draw(hotbar, x: (renderer.width - hotbar.width) / 2, y: renderer.height - hotbar.height - 4)
        renderer.text("\(input.mouse)", x: 2, y: 2)
        renderer.draw(input.mouse.left ? cursorPressed : cursor, x: input.mouse.x - 1, y: input.mouse.y - 1)
    }
    
    var hearts: Int = 1
    
    private var hotbar: some RecursiveDrawable {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 2) {
                for _ in 1...hearts { heart }
            }
            HStack {
                for i in 1...9 {
                    ZStack {
                        hotbarSlot
                        Text("\(i)")
                    }
                }
            }
        }.onClick {
            self.hearts += 1
        }
    }
    
    static func main() throws {
        let sdl = try SDL()
        var image = Image(width: sdl.width, height: sdl.height)
        let instance = Self()
        
        loop: while true {
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
