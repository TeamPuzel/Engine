
public protocol Drawable: Equatable {
    var width: Int { get }
    var height: Int { get }
    subscript(x: Int, y: Int) -> Color { get }
}

/// A `Drawable` which forwards its implementation to an inner `Drawable`.
public protocol WrapperDrawable: Drawable {
    associatedtype Wrapped: Drawable
    var wrapping: KeyPath<Self, Wrapped> { get }
}

public extension WrapperDrawable {
    var width: Int { self[keyPath: wrapping].width }
    var height: Int { self[keyPath: wrapping].height }
    subscript(x: Int, y: Int) -> Color { self[keyPath: wrapping][x, y] }
}

public extension Drawable {
    func slice(x: Int, y: Int, width: Int, height: Int) -> DrawableSlice<Self> {
        .init(self, x: x, y: y, width: width, height: height)
    }
    
    func grid(itemWidth: Int, itemHeight: Int) -> DrawableGrid<Self> {
        .init(self, itemWidth: itemWidth, itemHeight: itemHeight)
    }
    
    func colorMap(_ transform: @escaping (Color) -> Color) -> ColorMap<Self> { .init(self, transform) }
    
    func colorMap(_ existing: Color, to new: Color) -> ColorMap<Self> {
        self.colorMap { $0 == existing ? new : $0 }
    }
    
    /// Shorthand for flattening a nested structure of lazy drawables into a trivial image, for
    /// cases where using memory and losing information is preferable to repeatedly recomputing all layers.
    func flatten() -> Image { .init(self) }
}

public extension Drawable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.width == rhs.width && lhs.height == rhs.height else { return false }
        for x in 0..<lhs.width {
            for y in 0..<lhs.width {
                guard lhs[x, y] == rhs[x, y] else { return false }
            }
        }
        return true
    }
    
    static func == (lhs: Self, rhs: some Drawable) -> Bool {
        guard lhs.width == rhs.width && lhs.height == rhs.height else { return false }
        for x in 0..<lhs.width {
            for y in 0..<lhs.width {
                guard lhs[x, y] == .init(rhs[x, y]) else { return false }
            }
        }
        return true
    }
}

public struct EmptyDrawable: Drawable {
    public init() {}
    public var width: Int { 0 }
    public var height: Int { 0 }
    public subscript(x: Int, y: Int) -> Color { fatalError() }
}

/// A lazy 2d slice of another abstract `Drawable`, and a `Drawable` in itself.
/// Useful for example for slicing sprites from a sprite sheet.
public struct DrawableSlice<Inner: Drawable>: Drawable {
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
    
    public subscript(x: Int, y: Int) -> Color { inner[x + self.x, y + self.y] }
}

/// A lazy grid of equal size `Drawable` slices, for example a sprite sheet, tile map or tile font.
public struct DrawableGrid<Inner: Drawable>: Drawable {
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
    
    @_disfavoredOverload
    public subscript(x: Int, y: Int) -> Color { inner[x, y] }
    public subscript(x: Int, y: Int) -> DrawableSlice<Inner> {
        inner.slice(x: x * itemWidth, y: y * itemHeight, width: itemWidth, height: itemHeight)
    }
}

/// A lazy wrapper around a drawable, applies a map function to every color it yields.
public struct ColorMap<Inner: Drawable>: Drawable {
    public let inner: Inner
    private let transform: (Color) -> Color
    public var width: Int { inner.width }
    public var height: Int { inner.height }
    
    init(_ inner: Inner, _ transform: @escaping (Color) -> Color) {
        self.inner = inner
        self.transform = transform
    }
    
    public subscript(x: Int, y: Int) -> Color { transform(inner[x, y]) }
}

// TODO(!): This should be a `TileFont`. Use `Font` for a generic font protocol describing only
//          the mapping of characters to abstract drawables.
public struct TileFont<Source: Drawable> {
    public let inner: DrawableGrid<Source>
    public let map: (Character) -> (x: Int, y: Int)?
    public let spacing: Int
    
    public init(
        source: Source,
        charWidth: Int,
        charHeight: Int,
        spacing: Int = 1,
        map: @escaping (Character) -> (x: Int, y: Int)?
    ) {
        self.inner = source.grid(itemWidth: charWidth, itemHeight: charHeight)
        self.spacing = spacing
        self.map = map
    }
    
    public subscript(char: Character) -> DrawableSlice<Source>? {
        if let symbol = map(char) {
            return inner[symbol.x, symbol.y]
        } else {
            return nil
        }
    }
}

public struct Text: Drawable {
    public let image: Image
    public var width: Int { image.width }
    public var height: Int { image.height }
    
    public init<D: Drawable>(_ string: String, color: Color = .white, font: TileFont<D> = Fonts.pico) {
        var image = Image(width: string.count * (font.inner.itemWidth + font.spacing), height: font.inner.itemHeight)
        image.text(string, x: 0, y: 0, color: color, font: font)
        self.image = image
    }
    
    public subscript(x: Int, y: Int) -> Color { image[x, y] }
}

@resultBuilder
public struct DrawableBuilder {
    public static func buildBlock<each D: Drawable>(_ drawables: repeat each D) -> (repeat each D) {
        (repeat each drawables)
    }
}
