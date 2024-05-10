
/// The core of the engine, `Drawable` is an abstract representation of basically anything
/// that can be drawn, and with `MutableDrawable` anything that can also be drawn into.
///
/// `Drawable` implements a significant amount of functionality for lazily transforming drawables
/// into other drawables, building UI layouts and much more.
///
/// # Equality
/// Equality comparison works by comparing individual pixels, unless the proportions are not
/// equal themselves which of course makes drawables not equal.
public protocol Drawable: Equatable {
    var width: Int { get }
    var height: Int { get }
    subscript(x: Int, y: Int) -> Color { get }
}

/// A convenience `Drawable` which derives its implementation from an inner `Drawable`.
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

/// A `Drawable` with no size which will panic on any subscript use.
public struct EmptyDrawable: Drawable {
    public var width: Int { 0 }
    public var height: Int { 0 }
    public init() {}
    public subscript(x: Int, y: Int) -> Color { fatalError() }
}

/// A uniform `Drawable` of `Int.max` proportions.
///
/// Due to its effectively infinite size this drawable should never be drawn directly.
// TODO(!): Is this useful? Will keep it for now and see.
public struct InfiniteDrawable: Drawable {
    public let color: Color
    public var width: Int { Int.max }
    public var height: Int { Int.max }
    public init(_ color: Color = .clear) { self.color = color }
    public subscript(x: Int, y: Int) -> Color { color }
}

public extension Drawable {
    func unbounded(_ backup: Color) -> UnboundedDrawable<Self> { .init(self, backup: backup) }
    func unbounded(_ backup: Color) -> ThinUnboundedDrawable<Self> { .init(self) }
}

/// A safe wrapper around a drawable which catches out of bounds access, instead of
/// potentially fatally accessing the inner drawable it returns a default value.
public struct UnboundedDrawable<Inner: Drawable>: Drawable {
    public let inner: Inner
    public let backup: Color
    public var width: Int { inner.width }
    public var height: Int { inner.height }
    
    public init(_ inner: Inner, backup: Color) {
        self.inner = inner
        self.backup = backup
    }
    
    public subscript(x: Int, y: Int) -> Color {
        guard x >= 0 && y >= 0 && x < width && y < height else { return backup }
        return inner[x, y]
    }
}

/// A safe wrapper around a drawable which catches out of bounds access, instead of
/// potentially fatally accessing the inner drawable it returns a transparent color.
public struct ThinUnboundedDrawable<Inner: Drawable>: Drawable {
    public let inner: Inner
    public var width: Int { inner.width }
    public var height: Int { inner.height }
    
    public init(_ inner: Inner) {
        self.inner = inner
    }
    
    public subscript(x: Int, y: Int) -> Color {
        guard x >= 0 && y >= 0 && x < width && y < height else { return .clear }
        return inner[x, y]
    }
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
        assert(x >= 0 && y >= 0 && width >= x && height >= y)
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

/// A lazy wrapper around a drawable, applies a transform function to every color it yields.
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

public extension Drawable {
    func scaled(x: Int = 1, y: Int = 1) -> ScaledDrawable<Self> { .init(self, x: x, y: y) }
    func scaled(by scale: Int) -> ScaledDrawable<Self> { .init(self, scale: scale) }
}

// TODO(!): Calculate width and height at init time and use integers correctly instead of doubles.
// TODO(?): Maybe this could be overloaded to support fractional scaling with doubles?
public struct ScaledDrawable<Inner: Drawable>: Drawable {
    public let inner: Inner
    public let scaleX: Int
    public let scaleY: Int
    public var width: Int { Int((Double(inner.width) * Double(scaleX)).rounded(.down)) }
    public var height: Int { Int((Double(inner.height) * Double(scaleY)).rounded(.down))  }
    
    public init(_ inner: Inner, x: Int = 1, y: Int = 1) {
        assert(x >= 1 && y >= 1)
        self.inner = inner
        self.scaleX = x
        self.scaleY = y
    }
    
    public init(_ inner: Inner, scale: Int) {
        assert(scale >= 1)
        self.inner = inner
        self.scaleX = scale
        self.scaleY = scale
    }
    
    public subscript(x: Int, y: Int) -> Color { inner[x / scaleX, y / scaleY] }
}

/// A basic tile font, wraps a `DrawableGrid` and provides a mapping of characters
/// to grid coordinates with little to no configuration capabilities.
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
