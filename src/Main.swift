
import Darwin.ncurses

@main
enum Main {
    static func main() {
        let window = initscr()!
        defer { endwin() }
        
        noecho()
        defer { echo() }
        cbreak()
        defer { nocbreak() }
        keypad(window, true)
        defer { keypad(window, false) }
        
        let renderer = Renderer(window: window)
        let world = World()
        
        clear()
        world.tick(input: .none)
        world.draw(to: renderer)
        refresh()
        
        while true {
            let input = wgetch(window)
            clear()
            world.tick(input: Input(from: input))
            world.draw(to: renderer)
            refresh()
        }
    }
}

enum Input {
    case up, down, left, right
    case other(Character)
    case none
    
    init(from raw: Int32) {
        self = switch raw {
            case KEY_UP: .up
            case KEY_DOWN: .down
            case KEY_LEFT: .left
            case KEY_RIGHT: .right
            case _: .other(Character(Unicode.Scalar(UInt32(bitPattern: raw))!))
        }
    }
}

final class Renderer {
    private let window: OpaquePointer
    
    init(window: OpaquePointer) {
        self.window = window
    }
    
    func put(_ string: String, x: Int, y: Int) {
        guard x >= 0 && y >= 0 else { return }
        
        move(Int32(y), Int32(x))
        withVaList([]) { args in
            _ = vw_printw(window, string, args)
        }
    }
    
    func put(_ character: Character, x: Int, y: Int) {
        self.put(String(character), x: x, y: y)
    }
}
