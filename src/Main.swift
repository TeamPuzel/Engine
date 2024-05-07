
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
        
        let renderer = Renderer(window: window)
        let world = World()
        
        do {
            clear()
            world.tick(input: Input("."))
            world.draw(to: renderer)
            refresh()
        }
        
        while true {
            let input = wgetch(window)
            clear()
            world.tick(input: Input(input))
            world.draw(to: renderer)
            refresh()
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

public final class _Renderer {
    private let window: OpaquePointer
    
    public init(window: OpaquePointer) { self.window = window }
    
    public func put(_ string: String, x: Int, y: Int) {
        guard x >= 0 && y >= 0 else { return }
        
        move(Int32(y), Int32(x))
        withVaList([]) { args in
            _ = vw_printw(window, string, args)
        }
    }
    
    public func put(_ character: Character, x: Int, y: Int) { put(String(character), x: x, y: y) }
}
