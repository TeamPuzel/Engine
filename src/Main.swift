
struct Main: Game {
    let world = World()
    
    mutating func update(input: borrowing Input) throws {
        world.update(input: input)
    }
    
    mutating func draw(into image: inout Image) throws {
        world.draw(into: &image)
    }
}
