
public struct Image<Layout: Color>: Drawable {
    public private(set) var data: [Layout]
    public let width, height: Int
    
    public init(width: Int, height: Int, color: Layout = RGBA.clear) {
        self.width = width
        self.height = height
        self.data = .init(repeating: color, count: width * height)
    }
    
    public init(_ drawable: some Drawable<Layout>) {
        self.width = drawable.width
        self.height = drawable.height
        self.data = .init()
        self.data.reserveCapacity(self.width * self.height)
        for x in 0..<self.width {
            for y in 0..<self.height {
                self[x, y] = drawable[x, y]
            }
        }
    }
    
    public subscript(x: Int, y: Int) -> Layout {
        get { data[x + y * width] }
        set { data[x + y * width] = newValue }
    }
}

extension Image: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = [Layout]
    
    public init(arrayLiteral elements: [Layout]...) {
        self.width = elements[0].count
        self.height = elements.count
        self.data = .init(elements.joined())
    }
}

public enum Images {
    public enum UI {
        public static let cursor: Image<RGBA> = [
            [.clear, .black, .clear, .clear, .clear, .clear],
            [.black, .white, .black, .clear, .clear, .clear],
            [.black, .white, .white, .black, .clear, .clear],
            [.black, .white, .white, .white, .black, .clear],
            [.black, .white, .white, .white, .white, .black],
            [.black, .white, .white, .black, .black, .clear],
            [.clear, .black, .black, .white, .black, .clear]
        ]
    }
}
