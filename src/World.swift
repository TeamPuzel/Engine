
import Assets

let interface = UnsafeTGAPointer(UI_TGA).grid(itemWidth: 16, itemHeight: 16)
let cursor = interface[0, 0]
let cursorPressed = interface[1, 0]

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
        image.clear()
        image.draw(interface, x: 2, y: 2)
        image.draw(mouse.left ? cursorPressed : cursor, x: mouse.x - 1, y: mouse.y - 1)
    }
    
    private var interface: some Drawable {
        VStack(alignment: .leading, spacing: 2) {
            Text("Count: \(1 + mouse.x / 3)")
            HStack {
                for i in 0...max(0, mouse.x / 3) {
                    Text("\(i)")
                }
            }
            if mouse.x > 100 {
                Text("Wow")
            }
        }
    }
}
