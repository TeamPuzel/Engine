
public struct TextRenderer {
    public private(set) var target: Image<Character>
    
    public init(width: Int, height: Int) {
        self.target = .init(width: width, height: height, repeating: " ")
    }
    
    public mutating func resize(width: Int, height: Int) {
        guard (target.width, target.height) != (width, height) else { return }
        let old = target
        target = .init(width: width, height: height, repeating: " ")
        draw(old, x: 0, y: 0)
    }
    
    public mutating func clear(with character: Character) {
        for x in 0..<target.width {
            for y in 0..<target.height {
                self.put(character, x: x, y: y)
            }
        }
    }
    
    public mutating func put(_ character: Character, x: Int, y: Int) {
        if x >= 0 && y >= 0 && x < target.width && y < target.height { target[x, y] = character }
    }
    
    public mutating func draw(_ drawable: some TextDrawable, x: Int, y: Int) {
        for ix in 0..<drawable.width {
            for iy in 0..<drawable.height {
                put(drawable[ix, iy], x: ix + x, y: iy + y)
            }
        }
    }
}

extension TextRenderer: TextDrawable {
    public var width: Int { target.width }
    public var height: Int { target.height }
    public subscript(x: Int, y: Int) -> Character { target[x, y] }
}

public struct Image<T> {
    public private(set) var data: [T]
    public let width, height: Int
    
    public init(width: Int, height: Int, repeating value: T) {
        self.width = width
        self.height = height
        self.data = .init(repeating: value, count: width * height)
    }
    
    public subscript(x: Int, y: Int) -> T {
        get { data[x + y * width] }
        set { data[x + y * width] = newValue }
    }
}

extension Image: TextDrawable where T == Character {
    public init(_ drawable: some TextDrawable) where T == Character {
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
}

public protocol TextDrawable {
    var width: Int { get }
    var height: Int { get }
    subscript(x: Int, y: Int) -> Character { get }
}

public extension TextDrawable {
    func slice(x: Int, y: Int, width: Int, height: Int) -> TextDrawableSlice<Self> {
        .init(self, x: x, y: y, width: width, height: height)
    }
    
    func grid(itemWidth: Int, itemHeight: Int) -> DrawableGrid<Self> {
        .init(self, itemWidth: itemWidth, itemHeight: itemHeight)
    }
    
    /// Shorthand for flattening a nested structure of lazy drawables into a trivial image, for
    /// cases where using memory and losing information is preferable to repeatedly recomputing all layers.
    func flatten() -> Image<Character> { .init(self) }
}

public struct EmptyTextDrawable: TextDrawable {
    public var width: Int { 0 }
    public var height: Int { 0 }
    public subscript(x: Int, y: Int) -> Character { fatalError() }
}

public struct TextDrawableSlice<Inner: TextDrawable>: TextDrawable {
    public let inner: Inner
    private let x: Int
    private let y: Int
    public let width: Int
    public let height: Int
    
    public init(_ inner: Inner, x: Int, y: Int, width: Int, height: Int) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.inner = inner
    }
    
    public subscript(x: Int, y: Int) -> Character { inner[x + self.x, y + self.y] }
}

public struct DrawableGrid<Inner: TextDrawable>: TextDrawable {
    public let inner: Inner
    public var width: Int { inner.width }
    public var height: Int { inner.height }
    public let itemWidth: Int
    public let itemHeight: Int
    
    public init(_ inner: Inner, itemWidth: Int, itemHeight: Int) {
        self.inner = inner
        self.itemWidth = itemWidth
        self.itemHeight = itemHeight
    }
    
    public subscript(x: Int, y: Int) -> Character { inner[x, y] }
    public subscript(x: Int, y: Int) -> TextDrawableSlice<Inner> {
        inner.slice(x: x * itemWidth, y: y * itemHeight, width: itemWidth, height: itemHeight)
    }
}

extension Character: TextDrawable {
    public var width: Int { 1 }
    public var height: Int { 1 }
    public subscript(x: Int, y: Int) -> Character {
        assert(x == 0 && y == 0)
        return self
    }
}

extension String: TextDrawable {
    public var width: Int { count }
    public var height: Int { 1 }
    public subscript(x: Int, y: Int) -> Character {
        assert(y == 0)
        return Character(Unicode.Scalar(UInt8(self.utf8CString[x])))
    }
}
