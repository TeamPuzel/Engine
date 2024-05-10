
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

public protocol RecursiveDrawable: Drawable {
    associatedtype Children: Drawable
    var children: DrawableTuple<Children> { get }
}

// MARK: - Stacks

public struct VStack: Drawable {
    public let image: Image
    public var width: Int { image.width }
    public var height: Int { image.height }
    
    public init(
        alignment: Alignment = .centered,
        spacing: Int = 0,
        @DynamicDrawableBuilder content: () -> [any Drawable]
    ) {
        let inner = content()
        
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

public struct HStack: Drawable {
    public let image: Image
    public var width: Int { image.width }
    public var height: Int { image.height }
    
    public init(
        alignment: Alignment = .centered,
        spacing: Int = 0,
        @DynamicDrawableBuilder content: () -> [any Drawable]
    ) {
        let inner = content()
        
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

public struct ZStack: Drawable {
    public let image: Image
    public var width: Int { image.width }
    public var height: Int { image.height }
    
    public init(@DynamicDrawableBuilder content: () -> [any Drawable]) {
        let inner = content()
        
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

// MARK: - Modifiers

public extension Drawable {
    func framed(width: Int? = nil, height: Int? = nil) -> Frame<Self> {
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

public extension Drawable {
    func padded(_ edges: Edges = .all, by length: Int = 0) -> Padding<Self> {
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

public struct Edges: OptionSet {
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
