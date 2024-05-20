
// MARK: - Color

/// The internal color representation of the engine, an 8 bit RGBA structure.
///
/// To reduce complexity this is no longer a protocol. If I have a need for this in the future
/// I can bring back the old generic implementation. The drawback would be that non specialized
/// drawables would be unable to specialize their color representation and everything
/// would suffer from significant performance loss.
public struct Color: Hashable, Sendable, BitwiseCopyable {
    public let r, g, b, a: UInt8
    
    public init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
    
    public init(luminosity: UInt8, a: UInt8 = 255) {
        self.r = luminosity
        self.g = luminosity
        self.b = luminosity
        self.a = a
    }
    
    // TODO(!): This does nothing yet.
    func blend(with other: Color, _ mode: BlendMode = .add) -> Color {
        other
    }
    
    public enum BlendMode {
        case add
        case subtract
        case multiply
        case divide
    }
}

extension Color {
    public static let clear = Self(r: 0, g: 0, b: 0, a: 0)
    public static let black = Self(luminosity: 0)
    public static let white = Self(luminosity: 255)
    
    public enum Strawberry {
        public static let red    = Color(r: 214, g: 95,  b: 118)
        public static let banana = Color(r: 230, g: 192, b: 130)
        public static let apple  = Color(r: 205, g: 220, b: 146)
        public static let lime   = Color(r: 177, g: 219, b: 159)
        public static let sky    = Color(r: 129, g: 171, b: 201)
        public static let lemon  = Color(r: 240, g: 202, b: 101)
        public static let orange = Color(r: 227, g: 140, b: 113)
        
        public static let white = Color(r: 224, g: 224, b: 224)
        public static let light = Color(r: 128, g: 128, b: 128)
        public static let gray  = Color(r: 59,  g: 59,  b: 59 )
        public static let dark  = Color(r: 28,  g: 28,  b: 28 )
        public static let black = Color(r: 15,  g: 15,  b: 15 )
    }
    
    public enum Pico {
        public static let black      = Color(r: 0,   g: 0,   b: 0  )
        public static let darkBlue   = Color(r: 29,  g: 43,  b: 83 )
        public static let darkPurple = Color(r: 126, g: 37,  b: 83 )
        public static let darkGreen  = Color(r: 0,   g: 135, b: 81 )
        public static let brown      = Color(r: 171, g: 82,  b: 53 )
        public static let darkGray   = Color(r: 95,  g: 87,  b: 79 )
        public static let lightGray  = Color(r: 194, g: 195, b: 199)
        public static let white      = Color(r: 255, g: 241, b: 232)
        public static let red        = Color(r: 255, g: 0,   b: 77 )
        public static let orange     = Color(r: 255, g: 163, b: 0  )
        public static let yellow     = Color(r: 255, g: 236, b: 39 )
        public static let green      = Color(r: 0,   g: 228, b: 54 )
        public static let blue       = Color(r: 41,  g: 173, b: 255)
        public static let lavender   = Color(r: 131, g: 118, b: 156)
        public static let pink       = Color(r: 255, g: 119, b: 168)
        public static let peach      = Color(r: 255, g: 204, b: 170)
    }
}

//// TODO(!!!): Blending methods. The operators can forward to those if I decide to keep them.
//public extension Color {
//    // TODO(?): Does color need these in the first place?
//    // TODO(!): These methods are extremely likely to overflow.
//    //          I should decide on the correct way to handle this.
//    static func + (lhs: Self, rhs: Self) -> Self {
//        .init(r: lhs.r + rhs.r, g: lhs.g + rhs.g, b: lhs.b + rhs.b, a: lhs.a + rhs.a)
//    }
//    static func - (lhs: Self, rhs: Self) -> Self {
//        .init(r: lhs.r - rhs.r, g: lhs.g - rhs.g, b: lhs.b - rhs.b, a: lhs.a - rhs.a)
//    }
//    static func + (lhs: Self, rhs: UInt8) -> Self {
//        .init(r: lhs.r + rhs, g: lhs.g + rhs, b: lhs.b + rhs, a: lhs.a + rhs)
//    }
//    static func - (lhs: Self, rhs: UInt8) -> Self {
//        .init(r: lhs.r - rhs, g: lhs.g - rhs, b: lhs.b - rhs, a: lhs.a - rhs)
//    }
//}


// MARK: - Drawable

/// The core of the engine. `Drawable` is an abstract representation of basically anything
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

// MARK: - Slicing

public extension Drawable {
    /// Creates a lazy slice of the drawable.
    func slice(x: Int, y: Int, width: Int, height: Int) -> DrawableSlice<Self> {
        .init(self, x: x, y: y, width: width, height: height)
    }
    
    /// Creates a lazy grid from the drawable.
    func grid(itemWidth: Int, itemHeight: Int) -> DrawableGrid<Self> {
        .init(self, itemWidth: itemWidth, itemHeight: itemHeight)
    }
    
    /// Creates a lazy square grid from the drawable.
    func grid(itemSide: Int) -> SquareDrawableGrid<Self> {
        .init(self, itemSide: itemSide)
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
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.inner = inner
    }
    
    public subscript(x: Int, y: Int) -> Color { inner[x + self.x, y + self.y] }
}

extension DrawableSlice: Sendable where Inner: Sendable {}

// TODO(!): Is this useful?
//extension DrawableSlice: MutableDrawable where Inner: MutableDrawable {
//    public subscript(x: Int, y: Int) -> Color {
//        get { inner[x + self.x, y + self.y] }
//        set { inner[x + self.x, y + self.y] = newValue }
//    }
//}

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

extension DrawableGrid: Sendable where Inner: Sendable {}

/// A lazy grid of equal size `Drawable` slices, for example a sprite sheet, tile map or tile font.
/// It is a more lightweight variant of `DrawableGrid` optimised for storing square items.
public struct SquareDrawableGrid<Inner: Drawable>: Drawable {
    public let inner: Inner
    public var width: Int { inner.width }
    public var height: Int { inner.height }
    public let itemSide: Int
    
    public init(_ inner: Inner, itemSide: Int) {
        self.inner = inner
        self.itemSide = itemSide
    }
    
    @_disfavoredOverload
    public subscript(x: Int, y: Int) -> Color { inner[x, y] }
    public subscript(x: Int, y: Int) -> DrawableSlice<Inner> {
        inner.slice(x: x * itemSide, y: y * itemSide, width: itemSide, height: itemSide)
    }
}

extension SquareDrawableGrid: Sendable where Inner: Sendable {}

// MARK: - Mapping

public extension Drawable {
    /// Lazily map color on access.
    func colorMap(_ transform: @escaping (Color) -> Color) -> ColorMap<Self> {
        .init(self, transform)
    }
    
    /// Shorthand for a simple color map from one color to another.
    func colorMap(_ existing: Color, to new: Color) -> ColorMap<Self> {
        self.colorMap { $0 == existing ? new : $0 }
    }
}

/// A lazy wrapper around a drawable, applies a transform function to every color it yields.
public struct ColorMap<Inner: Drawable>: Drawable {
    public let inner: Inner
    private let transform: (Color) -> Color
    public var width: Int { inner.width }
    public var height: Int { inner.height }
    
    public init(_ inner: Inner, _ transform: @escaping (Color) -> Color) {
        self.inner = inner
        self.transform = transform
    }
    
    public subscript(x: Int, y: Int) -> Color { transform(inner[x, y]) }
}

// Requires additional checks for the closure.
//extension ColorMap: Sendable where Inner: Sendable {}

public struct ColorBlend<Foreground: Drawable, Background: Drawable>: Drawable {
    public let foreground: Foreground
    public let background: Background
    public var width: Int { background.width }
    public var height: Int { background.height }
    
    public init(foreground: Foreground, background: Background) {
        assert(foreground.width == background.width && foreground.height == background.height)
        self.foreground = foreground
        self.background = background
    }
    
    public subscript(x: Int, y: Int) -> Color {
        background[x, y].blend(with: background[x, y])
    }
}

extension ColorBlend: Sendable where Foreground: Sendable, Background: Sendable {}

// MARK: - Iteration

extension Drawable {
    public func enumerated() -> DrawableIterator<Self> { .init(self) }
}

public struct DrawableIterator<Inner: Drawable>: IteratorProtocol {
    public typealias Element = ((x: Int, y: Int), value: Color)
    
    private var inner: Inner
    
    public init(_ drawable: Inner) { self.inner = drawable }
    
    public mutating func next() -> Element? {
        fatalError() // TODO(!)
    }
}

extension DrawableIterator: Sendable where Inner: Sendable {}

// MARK: - Transformation

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

extension ScaledDrawable: Sendable where Inner: Sendable {}

// MARK: - Fonts

/// A basic tile font, wraps a `DrawableGrid` and provides a mapping of characters
/// to grid coordinates with little to no configuration capabilities.
// TODO(!): This should be a `TileFont`. Use `Font` for a generic font protocol describing only
//          the mapping of characters to abstract drawables.
public struct TileFont<Source: Drawable> {
    public let inner: DrawableGrid<Source>
    public let map: @Sendable (Character) -> (x: Int, y: Int)?
    public let spacing: Int
    
    public init(
        source: Source,
        charWidth: Int,
        charHeight: Int,
        spacing: Int = 1,
        map: @escaping @Sendable (Character) -> (x: Int, y: Int)?
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

extension TileFont: Sendable where Source: Sendable {}

// MARK: - Infinite

public protocol InfiniteDrawable: Drawable {}

public extension InfiniteDrawable {
    var width: Int { Int.max }
    var height: Int { Int.max }
}

// MARK: - Mutability and rendering

/// A `Drawable` which can be rendered into, derives useful rendering functionality.
public protocol MutableDrawable: Drawable {
    subscript(x: Int, y: Int) -> Color { get set }
}

public extension MutableDrawable {
    /// Draws a pixel using a blending mode.
    ///
    /// It is different from using the subscript in two ways:
    /// - It performs a safety check to avoid crashing on out of bounds.
    /// - It applies a blending function to the drawing operation.
    // TODO(!): Drop the safety check here and move it to `draw`
    mutating func pixel(_ color: Color, x: Int, y: Int, blendMode: Color.BlendMode = .add) {
        if x < 0 || y < 0 || x >= width || y >= height { return }
        self[x, y] = self[x, y].blend(with: color, blendMode)
    }
    
    mutating func clear(with color: Color = .clear) {
        for x in 0..<width {
            for y in 0..<height {
                pixel(color, x: x, y: y)
            }
        }
    }
    
    // TODO(!): Slice the drawable before drawing it to avoid wasting time drawing offscreen.
    mutating func draw(_ drawable: some Drawable, x: Int, y: Int) {
        for ix in 0..<drawable.width {
            for iy in 0..<drawable.height {
                // TODO(!): Handle opacity with blending modes. The blending api needs design.
                let color = drawable[ix, iy]
                if color.a == 255 {
                    self.pixel(color, x: ix + x, y: iy + y)
                }
            }
        }
    }
    
    mutating func text(
        _ string: String,
        x: Int, y: Int,
        color: Color = .white,
        font: TileFont<some Drawable> = TileFonts.pico
    ) {
        for (i, char) in string.enumerated() {
            if let symbol = font[char] {
                self.draw(
                    symbol.colorMap(.white, to: color),
                    x: x + (i * symbol.width + i * font.spacing),
                    y: y
                )
            }
        }
    }
    
    @available(*, deprecated, message: "Might be removed in favor of a drawable")
    mutating func rectangle(x: Int, y: Int, w: Int, h: Int, color: Color = .white, fill: Bool = false) {
        for ix in 0..<w {
            for iy in 0..<h {
                if ix + x == x || ix + x == x + w - 1 || iy + y == y || iy + y == y + h - 1 || fill {
                    self.pixel(color, x: ix + x, y: iy + y)
                }
            }
        }
    }
    
    @available(*, deprecated, message: "Might be removed in favor of a drawable")
    mutating func circle(x: Int, y: Int, r: Int, color: Color = .white, fill: Bool = false) {
        guard r >= 0 else { return }
        for ix in (x - r)..<(x + r + 1) {
            for iy in (y - r)..<(y + r + 1) {
                let distance = Int(Double(((ix - x) * (ix - x)) + ((iy - y) * (iy - y))).squareRoot().rounded())
                if fill {
                    if distance <= r { self.pixel(color, x: ix, y: iy) }
                } else {
                    if distance == r { self.pixel(color, x: ix, y: iy) }
                }
            }
        }
    }
}


// MARK: - Abstract

/// A `Drawable` with no size which will panic on subscript access.
public struct EmptyDrawable: Drawable {
    public var width: Int { 0 }
    public var height: Int { 0 }
    public init() {}
    public subscript(x: Int, y: Int) -> Color { fatalError() }
}

extension EmptyDrawable: Sendable {}

/// A uniform `Drawable` of infinite proportions.
///
/// Due to its effectively infinite size this drawable should never be drawn directly.
public struct UniformDrawable: InfiniteDrawable {
    public let color: Color
    public init(_ color: Color = .clear) { self.color = color }
    public subscript(x: Int, y: Int) -> Color { color }
}

extension UniformDrawable: Sendable {}

public extension Drawable {
    func unbounded(_ backup: Color) -> UnboundedDrawable<Self> { .init(self, backup: backup) }
    func unbounded() -> ThinUnboundedDrawable<Self> { .init(self) }
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

extension UnboundedDrawable: Sendable where Inner: Sendable {}

extension UnboundedDrawable: RecursiveDrawable {
    public var children: [Child] { [(0, 0, inner)] }
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

extension ThinUnboundedDrawable: Sendable where Inner: Sendable {}

extension ThinUnboundedDrawable: RecursiveDrawable {
    public var children: [Child] { [(0, 0, inner)] }
}

// MARK: - Primitive

public extension Drawable {
    /// Shorthand for flattening a nested structure of lazy drawables into a trivial image, for
    /// cases where using memory and losing information is preferable to repeatedly recomputing all layers.
    ///
    /// This method is a convenience and overloads the generic version of this function in cases where
    /// an explicit type is not provided, since an `Image` is the most primitive of drawables.
    /// It is the equivalent of calling `flatten(into: Image.self)`.
    @_disfavoredOverload func flatten() -> Image { .init(self) }
    /// Shorthand for flattening a nested structure of lazy drawables into a primitive drawable, for
    /// cases where using memory and losing information is preferable to repeatedly recomputing all layers.
    ///
    /// This overload allows specifying the type in the middle of a method chain.
    func flatten<T>(into type: T.Type) -> T where T: PrimitiveDrawable { .init(self) }
    /// Shorthand for flattening a nested structure of lazy drawables into a primitive drawable, for
    /// cases where using memory and losing information is preferable to repeatedly recomputing all layers.
    ///
    /// This overload is used when inferring the return type.
    func flatten<T>() -> T where T: PrimitiveDrawable { .init(self) }
}

/// A standalone `Drawable` representation which can be flattened into.
public protocol PrimitiveDrawable: Drawable {
    init(_ drawable: some Drawable)
}

/// The most basic `Drawable`, supports mutability and can be rendered into.
///
/// An image is backed by an allocation of `[Color]` which can be read (but not written to) directly.
/// This is primarily intended for FFI, allowing an image to be rendered by a graphics API.
public struct Image: PrimitiveDrawable, MutableDrawable, Sendable {
    public private(set) var data: [Color]
    public let width, height: Int
    
    public init(width: Int, height: Int, color: Color = .clear) {
        self.width = width
        self.height = height
        self.data = .init(repeating: color, count: width * height)
    }
    
    // TODO(!): Initialization can safely be skipped here.
    public init(_ drawable: some Drawable) {
        self.width = drawable.width
        self.height = drawable.height
        self.data = .init(repeating: .clear, count: width * height)
        self.data.reserveCapacity(self.width * self.height)
        for x in 0..<self.width {
            for y in 0..<self.height {
                self[x, y] = drawable[x, y]
            }
        }
    }
    
    /// Resizes the image and copies over old color data into the new allocation at `x: 0. y: 0`.
    /// - Returns: `true` if the image was resized, `false` if provided dimensions were identical.
    ///
    /// When the image size is unchanged no reallocation is performed.
    @discardableResult public mutating func resize(width: Int, height: Int) -> Bool {
        guard width != self.width || height != self.height else { return false }
        var new = Image(width: width, height: height)
        new.draw(self, x: 0, y: 0)
        self = new
        return true
    }
    
    public subscript(x: Int, y: Int) -> Color {
        get { data[x + y * width] }
        set { data[x + y * width] = newValue }
    }
}

extension Image: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: [Color]...) {
        self.width = elements[0].count
        self.height = elements.count
        self.data = .init(elements.joined())
    }
}

// MARK: - Formats

/// A very unsafe implementation of the TGA image format, ignores the header assuming
/// no additional information and just reads it blindly as 32 bit BGRA.
///
/// I will likely avoid improving it, rather I will implement a simpler format of my own
/// and add it to Aseprite (or write a custom editor within this engine, probably easier).
///
/// Using it to draw directly incurs a performance cost due to the pixel format conversion.
/// It's probably insignificant but flattening into an `Image` would avoid it entirely,
/// although doubling memory usage.
///
/// # Safety
/// Actually using this type is safe as long as the assumptions about its encoding hold true.
///
/// # Concurrency
/// It's just an immutable view into const data so it can be shared across actors.
public struct UnsafeTGAPointer: Drawable, @unchecked Sendable {
    private let base: UnsafeRawPointer
    
    public init(_ base: UnsafeRawPointer) { self.base = base }
    
    public var width: Int { Int(base.load(fromByteOffset: 12, as: UInt16.self)) }
    public var height: Int { Int(base.load(fromByteOffset: 14, as: UInt16.self)) }
    
    private var data: UnsafeBufferPointer<BGRA> {
        .init(
            start: base.advanced(by: 18).bindMemory(to: BGRA.self, capacity: width * height),
            count: width * height
        )
    }
    
    public subscript(x: Int, y: Int) -> Color {
        let pixel = data[x + y * width]
        return .init(r: pixel.r, g: pixel.g, b: pixel.b, a: pixel.a)
    }
    
    private struct BGRA { let b, g, r, a: UInt8 }
}

// MARK: - Layout Builders

@resultBuilder
public struct DynamicDrawableBuilder {
    public static func buildBlock(_ drawables: [any Drawable]...) -> [any Drawable] { Array(drawables.joined()) }
    public static func buildExpression(_ expression: any Drawable) -> [any Drawable] { [expression] }
    public static func buildArray(_ components: [[any Drawable]]) -> [any Drawable] { Array(components.joined()) }
    public static func buildOptional(_ component: [any Drawable]?) -> [any Drawable] { component ?? [] }
    public static func buildEither(first component: [any Drawable]) -> [any Drawable] { component }
    public static func buildEither(second component: [any Drawable]) -> [any Drawable] { component }
}

// Still figuring this out. Will make a massive performance difference.
@resultBuilder
public struct DrawableBuilder {
    public static func buildBlock<each D: Drawable>(_ drawables: repeat each D) -> DrawableTuple<repeat each D> {
        .init(repeat each drawables)
    }
    
    public static func buildExpression<each D: Drawable>(_ expression: any Drawable) -> DrawableTuple<repeat each D> {
        fatalError()
    }
    
    public static func buildArray<each D: Drawable>(_ components: [[any Drawable]]) -> DrawableTuple<repeat each D> {
        fatalError()
    }
    
    public static func buildOptional<each D: Drawable>(_ component: [any Drawable]?) -> DrawableTuple<repeat each D> {
        fatalError()
    }
    
    public static func buildEither<each D: Drawable>(first component: [any Drawable]) -> DrawableTuple<repeat each D> {
        fatalError()
    }
    
    public static func buildEither<each D: Drawable>(second component: [any Drawable]) -> DrawableTuple<repeat each D> {
        fatalError()
    }
}

// MARK: - Stacks

// TODO(!): Variadic generics instead of this inefficient mess.
public struct VStack: RecursiveDrawable {
    public let inner: [any Drawable]
    public let image: Image
    public let alignment: Alignment
    public let spacing: Int
    public var width: Int { image.width }
    public var height: Int { image.height }
    
    public var children: [Child] {
        var buf: [Child] = []
        
        var (width, height) = (0, 0)
        for drawable in inner {
            width = width > drawable.width ? width : drawable.width
            height += drawable.height + spacing
        }
        
        var currentY = 0
        for drawable in inner {
            let offset = switch alignment {
                case .leading: 0
                case .trailing: width - drawable.width
                case .centered: (width - drawable.width) / 2
            }
            buf.append((x: offset, y: currentY, drawable))
            currentY += drawable.height + spacing
        }
        
        return buf
    }
    
    public init(
        alignment: Alignment = .centered,
        spacing: Int = 0,
        @DynamicDrawableBuilder content: () -> [any Drawable]
    ) {
        self.inner = content()
        self.spacing = spacing
        self.alignment = alignment
        
        var (width, height) = (0, 0)
        for drawable in inner {
            width = width > drawable.width ? width : drawable.width
            height += drawable.height + spacing
        }
        
        var image = Image(width: width, height: height)
        
        var currentY = 0
        for drawable in inner {
            let offset = switch alignment {
                case .leading: 0
                case .trailing: width - drawable.width
                case .centered: (width - drawable.width) / 2
            }
            image.draw(drawable, x: offset, y: currentY)
            currentY += drawable.height + spacing
        }
        
        self.image = image
    }
    
    public subscript(x: Int, y: Int) -> Color { image[x, y] }
    
    public enum Alignment { case leading, trailing, centered }
}

public struct HStack: RecursiveDrawable {
    public let inner: [any Drawable]
    public let image: Image
    public let alignment: Alignment
    public let spacing: Int
    public var width: Int { image.width }
    public var height: Int { image.height }
    
    public var children: [Child] {
        var buf: [Child] = []
        
        var (width, height) = (0, 0)
        for drawable in inner {
            height = height > drawable.height ? height : drawable.height
            width += drawable.width + spacing
        }
        
        var currentX = 0
        for drawable in inner {
            let offset = switch alignment {
                case .top: 0
                case .bottom: height - drawable.height
                case .centered: (height - drawable.height) / 2
            }
            buf.append((x: currentX, y: offset, drawable))
            currentX += drawable.width + spacing
        }
        
        return buf
    }
    
    public init(
        alignment: Alignment = .centered,
        spacing: Int = 0,
        @DynamicDrawableBuilder content: () -> [any Drawable]
    ) {
        self.inner = content()
        self.spacing = spacing
        self.alignment = alignment
        
        var (width, height) = (0, 0)
        for drawable in inner {
            height = height > drawable.height ? height : drawable.height
            width += drawable.width + spacing
        }
        
        var image = Image(width: width, height: height)
        
        var currentX = 0
        for drawable in inner {
            let offset = switch alignment {
                case .top: 0
                case .bottom: height - drawable.height
                case .centered: (height - drawable.height) / 2
            }
            image.draw(drawable, x: currentX, y: offset)
            currentX += drawable.width + spacing
        }
        
        self.image = image
    }
    
    public subscript(x: Int, y: Int) -> Color { image[x, y] }
    
    public enum Alignment { case top, bottom, centered }
}

public struct ZStack: RecursiveDrawable {
    public let inner: [any Drawable]
    public let image: Image
    public var width: Int { image.width }
    public var height: Int { image.height }
    
    public var children: [Child] {
        var buf: [Child] = []
        
        var (width, height) = (0, 0)
        for drawable in inner {
            height = height > drawable.height ? height : drawable.height
            width = width > drawable.width ? width : drawable.width
        }
        
        for drawable in inner {
            buf.append((x: (image.width - drawable.width) / 2, y: (image.height - drawable.height) / 2, drawable))
        }
        
        
        return buf
    }
    
    public init(@DynamicDrawableBuilder content: () -> [any Drawable]) {
        self.inner = content()
        
        var (width, height) = (0, 0)
        for drawable in inner {
            height = height > drawable.height ? height : drawable.height
            width = width > drawable.width ? width : drawable.width
        }
        
        var image = Image(width: width, height: height)
        
        for drawable in inner {
            image.draw(drawable, x: (image.width - drawable.width) / 2, y: (image.height - drawable.height) / 2)
        }
        
        self.image = image
    }
    
    public subscript(x: Int, y: Int) -> Color { image[x, y] }
    
    public enum Alignment { case top, bottom, centered }
}

// Impossible with existentials
//extension ZStack: Sendable {}

// MARK: - Text

public struct Text: Drawable {
    public let image: Image
    public var width: Int { image.width }
    public var height: Int { image.height }
    
    public init<D: Drawable>(_ string: String, color: Color = .white, font: TileFont<D> = TileFonts.pico) {
        var image = Image(
            width: string.count * (font.inner.itemWidth + font.spacing) - font.spacing,
            height: font.inner.itemHeight
        )
        image.text(string, x: 0, y: 0, color: color, font: font)
        self.image = image
    }
    
    public subscript(x: Int, y: Int) -> Color { image[x, y] }
}

extension Text: Sendable {}

// MARK: - Shapes

public struct Rectangle: Drawable {
    public let color: Color
    public let width: Int
    public let height: Int
    
    public init(width: Int, height: Int, color: Color = .white) {
        self.width = width
        self.height = height
        self.color = color
    }
    
    public subscript(x: Int, y: Int) -> Color {
        assert(x < width && y < height && x >= 0 && y >= 0)
        return color
    }
}

extension Rectangle: Sendable {}

// MARK: - Modifiers

public extension Drawable {
    func frame(width: Int? = nil, height: Int? = nil) -> Frame<Self> {
        .init(self, width: width ?? self.width, height: height ?? self.height)
    }
}

public struct Frame<Inner: Drawable>: Drawable {
    public let inner: Inner
    public let width: Int
    public let height: Int
    
    init(_ inner: Inner, width: Int, height: Int) {
        self.inner = inner
        self.width = max(width, inner.width)
        self.height = max(height, inner.height)
    }
    
    // TODO(!!): Branching in a subscript? Find a way to optimize this.
    public subscript(x: Int, y: Int) -> Color {
        let (offsetX, offsetY) = ((width - inner.width) / 2, (height - inner.height) / 2)
        if x >= offsetX && y >= offsetY && x < offsetX + inner.width && y < offsetY + inner.height {
            return inner[x - offsetX, y - offsetY]
        } else {
            return .clear
        }
    }
}

extension Frame: Sendable where Inner: Sendable {}

public extension Drawable {
    func pad(_ edges: Edges = .all, by length: Int = 0) -> Padding<Self> {
        .init(self, edges: edges, length: length)
    }
}

public struct Padding<Inner: Drawable>: Drawable {
    public let inner: Inner
    public let edges: Edges
    public let width: Int
    public let height: Int
    
    init(_ inner: Inner, edges: Edges = .all, length: Int = 0) {
        self.inner = inner
        self.edges = edges
        
        self.width = if edges.contains(.horizontal) {
            inner.width + length * 2
        } else if edges.contains(.leading) || edges.contains(.trailing) {
            inner.width + length
        } else {
            inner.width
        }
        
        self.height = if edges.contains(.vertical) {
            inner.height + length * 2
        } else if edges.contains(.top) || edges.contains(.bottom) {
            inner.height + length
        } else {
            inner.height
        }
    }
    
    // TODO(!!): Branching in a subscript? Find a way to optimize this.
    public subscript(x: Int, y: Int) -> Color {
        // TODO(!): Compute the correct offsets!
        fatalError()
        
//        let (offsetX, offsetY) = ((width - inner.width) / 2, (height - inner.height) / 2)
//        if x >= offsetX && y >= offsetY && x < offsetX + inner.width && y < offsetY + inner.height {
//            return inner[x - offsetX, y - offsetY]
//        } else {
//            return .clear
//        }
    }
}

extension Padding: Sendable where Inner: Sendable {}

public struct Edges: OptionSet, Sendable, BitwiseCopyable {
    public let rawValue: UInt8
    
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    
    public static let leading  = Self(rawValue: 1 << 0)
    public static let trailing = Self(rawValue: 1 << 1)
    public static let top      = Self(rawValue: 1 << 2)
    public static let bottom   = Self(rawValue: 1 << 3)
    
    public static let horizontal: Self = [.leading, .trailing]
    public static let vertical: Self = [.top, .bottom]
    public static let all: Self = [.leading, .trailing, .top, .bottom]
}

// TODO(!): Drop shadow modifier
//public struct Shadow<Inner: Drawable>: Drawable {
//
//}

// MARK: - Interactivity

/// A static collection of drawables.
///
/// Because it only bundles drawables together and carries no additional information it is not
/// `Drawable` itself. A drawable like `VStack` is required to provide the information
/// required to know how to draw it. Its main purpose is to serve as a building block
/// for the `DrawableBuilder` enabling composability of recursive drawables.
public struct DrawableTuple<each D: Drawable> {
    public let drawables: (repeat each D)
    public init(_ drawables: repeat each D) { self.drawables = (repeat each drawables) }
}

extension DrawableTuple: Sendable where repeat each D: Sendable {}

/// A `Drawable` which contains other drawables and exposes them for traversal as a tuple of
/// drawables. This is used to retroactively understand layouts for event processing.
public protocol RecursiveDrawable: Drawable {
    /// A bundle of child drawable and its position relative to the drawable origin.
    typealias Child = (x: Int, y: Int, child: any Drawable)
    var children: [Child] { get }
}

public protocol ProcessingDrawable: RecursiveDrawable {
    func process(input: Input, x: Int, y: Int)
}

public extension RecursiveDrawable {
    func traverse(input: Input, x: Int = 0, y: Int = 0) {
        (self as? any ProcessingDrawable)?.process(input: input, x: x, y: y)
        for (cx, cy, child) in children {
            (child as? any RecursiveDrawable)?.traverse(input: input, x: x + cx, y: y + cy)
        }
    }
}

public extension Drawable {
    func onClick(_ click: @escaping () -> Void) -> ClickProcessing<Self> { .init(self, click: click) }
    func onHover(_ hover: @escaping () -> Void) -> HoverProcessing<Self> { .init(self, hover: hover) }
}

public struct ClickProcessing<Inner: Drawable>: ProcessingDrawable {
    public let inner: Inner
    public let click: () -> Void
    public var width: Int { inner.width }
    public var height: Int { inner.height }
    
    public var children: [Child] { [(0, 0, inner)] }
    
    public init(_ inner: Inner, click: @escaping () -> Void) {
        self.inner = inner
        self.click = click
    }
    
    public subscript(x: Int, y: Int) -> Color { inner[x, y] }
    
    public func process(input: Input, x: Int, y: Int) {
        guard let mouse = input.mouse else { return }
        if mouse.x >= x && mouse.x < x + width && mouse.y >= y && mouse.y < y + height && mouse.left {
            click()
        }
    }
}

// Closure again
//extension ClickProcessing: Sendable where Inner: Sendable {}

public struct HoverProcessing<Inner: Drawable>: ProcessingDrawable {
    public let inner: Inner
    public let hover: () -> Void
    public var width: Int { inner.width }
    public var height: Int { inner.height }
    
    public var children: [Child] { [(0, 0, inner)] }
    
    public init(_ inner: Inner, hover: @escaping () -> Void) {
        self.inner = inner
        self.hover = hover
    }
    
    public subscript(x: Int, y: Int) -> Color { inner[x, y] }
    
    public func process(input: Input, x: Int, y: Int) {
        guard let mouse = input.mouse else { return }
        if mouse.x >= x && mouse.x < x + width && mouse.y >= y && mouse.y < y + height { hover() }
    }
}

// Closure problem
//extension HoverProcessing: Sendable where Inner: Sendable {}
