
class Block {
    var symbol: Character? { nil }
}

class Air: Block {
    
}

class Ground: Block {
    override var symbol: Character? { "." }
}

class Stairs: Block {
    let direction: Direction
    
    override var symbol: Character? {
        switch direction {
            case .up: "<"
            case .down: ">"
        }
    }
    
    init(_ direction: Direction) {
        self.direction = direction
    }
    
    enum Direction {
        case up, down
        var opposite: Self { switch self { case .up: .down case .down: .up } }
    }
}

class Wall: Block {
    override var symbol: Character? { "#" }
}
