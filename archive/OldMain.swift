
fileprivate let interface = UnsafeTGAPointer(UI_TGA).grid(itemWidth: 16, itemHeight: 16)
fileprivate let cursor = interface[0, 0]
fileprivate let cursorPressed = interface[1, 0]
fileprivate let terrain = UnsafeTGAPointer(TERRAIN_TGA)

public final class Game {
    public init() {}
    
    private var timer = Timer()
    
    public func frame(input: Input, renderer: inout Image) {
        let elapsed = timer.lap()
        
        renderer.clear(with: .init(luminosity: 35))
        renderer.text("Frame: \(elapsed)", x: 2, y: 8)
        renderer.draw(input.mouse.left ? cursorPressed : cursor, x: input.mouse.x - 1, y: input.mouse.y - 1)
    }
}
