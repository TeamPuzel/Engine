
/// A wrapper type for an `Image` target providing comprehensive software rendering functionality.
///
/// Renderer can't be a protocol as that would disallow default arguments.
/// To make it generic it would need to delegate the exact functionality to a generic
/// `RenderTarget` protocol. This would also allow correct handling of oob pixel writes,
/// since there is no way to guarantee that a `RenderTarget` handles this, short of a
/// Haskell style "law" - and I prefer to lean on the type system as much as possible.
///
/// # Copyability
/// Not sure if it should be move only, it's not required for correctness, but would prevent
/// misuse as copying this could be very expensive and cause large cyclic allocations.
/// There is time to figure it out as this is impossible without move only generics.
public struct Renderer/*: ~Copyable */{
    internal var display: Image<RGBA>
    
    public var width: Int { self.display.width }
    public var height: Int { self.display.height }
    
    internal init(width: Int, height: Int) {
        self.display = .init(width: width, height: height, color: .black)
    }
    
    public mutating func resize(width: Int, height: Int) {
        self.display = .init(width: width, height: height, color: .black)
    }
    
    public mutating func clear(with color: some Color = RGBA.black) {
        for x in 0..<self.display.width {
            for y in 0..<self.display.height {
                self.pixel(x: x, y: y, color: color)
            }
        }
    }
    
    public mutating func pixel(x: Int, y: Int, color: some Color = RGBA.white) {
        if x < 0 || y < 0 || x >= display.width || y >= display.height { return }
        self.display[x, y] = .init(color)
    }
    
    public mutating func draw(_ drawable: some Drawable, x: Int, y: Int) {
        for ix in 0..<drawable.width {
            for iy in 0..<drawable.height {
                // TODO(!) Handle opacity with blending modes. The blending api needs design.
                let color = drawable[ix, iy]
                if color.a == 255 {
                    self.pixel(x: ix + x, y: iy + y, color: color)
                }
            }
        }
    }
    
    public mutating func rectangle(x: Int, y: Int, w: Int, h: Int, color: some Color = RGBA.white, fill: Bool = false) {
        for ix in 0..<w {
            for iy in 0..<h {
                if ix + x == x || ix + x == x + w - 1 || iy + y == y || iy + y == y + h - 1 || fill {
                    self.pixel(x: ix + x, y: iy + y, color: color)
                }
            }
        }
    }
    
    public mutating func circle(x: Int, y: Int, r: Int, color: some Color = RGBA.white, fill: Bool = false) {
        guard r >= 0 else { return }
        for ix in (x - r)..<(x + r + 1) {
            for iy in (y - r)..<(y + r + 1) {
                let distance = Int(Double(((ix - x) * (ix - x)) + ((iy - y) * (iy - y))).squareRoot().rounded())
                if fill {
                    if distance <= r { pixel(x: ix, y: iy, color: color) }
                } else {
                    if distance == r { pixel(x: ix, y: iy, color: color) }
                }
            }
        }
    }
    
    public mutating func text(
        _ string: String,
        x: Int, y: Int,
        color: some Color = RGBA.white,
        font: TileFont<some Drawable>
    ) {
        for (i, char) in string.enumerated() {
            if let symbol = font[char] {
                self.draw(
                    symbol.colorMap(.init(RGBA.white), to: color),
                    x: x + (i * symbol.width + i * font.spacing),
                    y: y
                )
            }
        }
    }
}

// Technically `Renderer` is a `Drawable`, so it could be trivially used to for example
// color map the entire screen by rendering a `ColorMap` of itself.
extension Renderer: Drawable {
    public subscript(x: Int, y: Int) -> RGBA { self.display[x, y] }
}

public protocol Drawable<Layout>: Equatable {
    associatedtype Layout: Color
    var width: Int { get }
    var height: Int { get }
    subscript(x: Int, y: Int) -> Layout { get }
}

public extension Drawable {
    func slice(x: Int, y: Int, width: Int, height: Int) -> DrawableSlice<Self> {
        .init(self, x: x, y: y, width: width, height: height)
    }
    
    func grid(itemWidth: Int, itemHeight: Int) -> DrawableGrid<Self> {
        .init(self, itemWidth: itemWidth, itemHeight: itemHeight)
    }
    
    func colorMap<C: Color>(map: @escaping (C) -> C) -> ColorMap<Self, C> { .init(self, map: map) }
    
    func colorMap<C: Color>(_ existing: C, to new: C) -> ColorMap<Self, C> {
        self.colorMap { $0 == existing ? new : $0 }
    }
    
    /// Shorthand for flattening a nested structure of lazy drawables into a trivial image, for
    /// cases where using memory and losing information is preferable to repeatedly recomputing all layers.
    func flatten() -> Image<Layout> { .init(self) }
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

public struct EmptyDrawable<Layout: Color>: Drawable {
    public var width: Int { 0 }
    public var height: Int { 0 }
    public subscript(x: Int, y: Int) -> Layout { fatalError() }
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
    
    public subscript(x: Int, y: Int) -> Inner.Layout { inner[x + self.x, y + self.y] }
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
    
    public subscript(x: Int, y: Int) -> Inner.Layout { inner[x, y] }
    public subscript(x: Int, y: Int) -> DrawableSlice<Inner> {
        inner.slice(x: x * itemWidth, y: y * itemHeight, width: itemWidth, height: itemHeight)
    }
}

/// A lazy wrapper around a drawable, applies a map function to every color it yields.
public struct ColorMap<Inner: Drawable, L: Color>: Drawable {
    public let inner: Inner
    private let map: (L) -> L
    public var width: Int { inner.width }
    public var height: Int { inner.height }
    
    init(_ inner: Inner, map: @escaping (L) -> L) {
        self.inner = inner
        self.map = map
    }
    
    public subscript(x: Int, y: Int) -> Inner.Layout { .init(map(.init(inner[x, y]))) }
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
