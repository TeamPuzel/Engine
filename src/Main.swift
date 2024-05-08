
import Darwin.ncurses

@main
struct Main {
    static func main() {
        let window = initscr()!
        defer { endwin() }
        
        curs_set(0)
        noecho()
        cbreak()
        keypad(window, true)
        
        let (w, h) = (Int(getmaxx(window)), Int(getmaxy(window)))
        var renderer = TextRenderer(width: w, height: h)
        
        let world = World()
        
        do {
            world.tick(input: Input("."))
            world.draw(into: &renderer)
            cursesSubmit(renderer, to: window)
        }
        
        while true {
            let (w, h) = (Int(getmaxx(window)), Int(getmaxy(window)))
            renderer.resize(width: w, height: h)
            
            let input = wgetch(window)
            world.tick(input: Input(input))
            world.draw(into: &renderer)
            
            cursesSubmit(renderer, to: window)
        }
    }
}

public enum Input {
    case up, down, left, right, other(Character)
    
    public init(_ raw: Int32) {
        self = switch raw {
            case KEY_UP: .up
            case KEY_DOWN: .down
            case KEY_LEFT: .left
            case KEY_RIGHT: .right
            case _: .other(Character(Unicode.Scalar(UInt32(bitPattern: raw))!))
        }
    }
    
    public init(_ character: Character) {
        self = .other(character)
    }
}

fileprivate func cursesSubmit(_ renderer: borrowing TextRenderer, to window: OpaquePointer) {
    clear()
    for x in 0..<renderer.target.width {
        for y in 0..<renderer.target.height {
            move(Int32(y), Int32(x))
            withVaList([]) { args in
                _ = vw_printw(window, String(renderer.target[x, y]), args)
            }
        }
    }
    refresh()
}
