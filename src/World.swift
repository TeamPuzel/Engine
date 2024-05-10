
import Assets

let interface = UnsafeTGAPointer(UI_TGA).grid(itemWidth: 16, itemHeight: 16)
let cursor = interface[0, 0]
let cursorPressed = interface[1, 0]

let hotbarSlot = UnsafeTGAPointer(UI_TGA).grid(itemWidth: 32, itemHeight: 32)[0, 1]
let heart = UnsafeTGAPointer(UI_TGA).slice(x: 0, y: 16, width: 13, height: 12)

@main
public final class World: Game {
    public private(set) var plane: Plane!
    public private(set) var player: Entity!
    
    private var mouse: Input.Mouse! = nil
    
    public init() {
        self.plane = Plane.Material(world: self)
        self.player = Entity.Human()
        self.plane.add(entity: self.player)
    }
    
    public func update(input: borrowing Input) {
        mouse = input.mouse
    }
    
    public func draw(into image: inout Image) {
        image.clear(with: .init(luminosity: 35))
        image.text("\(mouse!)", x: 2, y: 2)
        image.draw(hotbar, x: (image.width - hotbar.width) / 2, y: image.height - hotbar.height - 4)
        image.draw(mouse.left ? cursorPressed : cursor, x: mouse.x - 1, y: mouse.y - 1)
    }
    
    private var hotbar: some Drawable {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 2) {
                for _ in 1...max(1, mouse.x) { heart }
            }
            HStack {
                for i in 1...9 {
                    ZStack {
                        hotbarSlot
                        Text("\(i)")
                    }
                }
            }
        }
    }
}
