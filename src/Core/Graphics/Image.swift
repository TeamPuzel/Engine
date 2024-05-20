
/// The most basic `Drawable`, supports mutability and can be rendered into.
///
/// An image is backed by an allocation of `[Color]` which can be read (but not written to) directly.
/// This is primarily intended for FFI, allowing an image to be rendered by a graphics API.
public struct Image: MutableDrawable, Sendable {
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

public extension Drawable {
    /// Shorthand for flattening a nested structure of lazy drawables into a trivial image, for
    /// cases where using memory and losing information is preferable to repeatedly recomputing all layers.
    func flatten() -> Image { .init(self) }
}
