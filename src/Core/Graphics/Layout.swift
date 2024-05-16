
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

public struct Edges: OptionSet, Sendable {
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
        if
            input.mouse.x >= x &&
            input.mouse.x < x + width &&
            input.mouse.y >= y &&
            input.mouse.y < y + height &&
            input.mouse.left
        {
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
        if
            input.mouse.x >= x &&
            input.mouse.x < x + width &&
            input.mouse.y >= y &&
            input.mouse.y < y + height
        {
            hover()
        }
    }
}

// Closure problem
//extension HoverProcessing: Sendable where Inner: Sendable {}
