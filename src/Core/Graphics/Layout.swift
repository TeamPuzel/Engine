
@resultBuilder
public struct DrawableBuilder {
    public static func buildBlock(_ drawables: [any Drawable]...) -> [any Drawable] { Array(drawables.joined()) }
    public static func buildExpression(_ expression: any Drawable) -> [any Drawable] { [expression] }
    public static func buildArray(_ components: [[any Drawable]]) -> [any Drawable] { Array(components.joined()) }
    public static func buildOptional(_ component: [any Drawable]?) -> [any Drawable] { component ?? [] }
    public static func buildEither(first component: [any Drawable]) -> [any Drawable] { component }
    public static func buildEither(second component: [any Drawable]) -> [any Drawable] { component }
}

public struct VStack: Drawable {
    public let image: Image
    public var width: Int { image.width }
    public var height: Int { image.height }
    
    public init(
        alignment: Alignment = .centered,
        spacing: Int = 0,
        @DrawableBuilder drawables: () -> [any Drawable]
    ) {
        let inner = drawables()
        
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
        @DrawableBuilder drawables: () -> [any Drawable]
    ) {
        let inner = drawables()
        
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
    
    public init(@DrawableBuilder drawables: () -> [any Drawable]) {
        let inner = drawables()
        
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
