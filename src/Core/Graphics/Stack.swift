
//public struct Spacer: Drawable {
//    public let width: Int = Int.max
//    public let height: Int = Int.max
//    public init() {}
//    public subscript(x: Int, y: Int) -> Color { .clear }
//}

public struct VStack: Drawable {
    public let image: Image
    public var width: Int { image.width }
    public var height: Int { image.height }
    
    @_optimize(none)
    public init<each D: Drawable>(
        alignment: Alignment = .centered,
        spacing: Int = 0,
//        height: Int? = nil,
        @DrawableBuilder drawables: () -> (repeat each D)
    ) {
        let inner = drawables()
        
        var (width, height) = (0, 0)
        for drawable in repeat each inner {
            width = width > drawable.width ? width : drawable.width
            height += drawable.height + spacing
        }
        
        var image = Image(width: width, height: height)
        
        var currentY = 0
        for drawable in repeat each inner {
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
    
    @_optimize(none)
    public init<S: Sequence, each D: Drawable>(
        iterating sequence: S,
        alignment: Alignment = .centered,
        spacing: Int = 0,
//        height: Int? = nil,
        @DrawableBuilder drawables: (S.Element) -> (repeat each D)
    ) {
        let inners = sequence.reduce(into: []) { acc, el in acc.append(drawables(el)) }
        
        var (width, height) = (0, 0)
        for inner in inners {
            for drawable in repeat each inner {
                width = width > drawable.width ? width : drawable.width
                height += drawable.height + spacing
            }
        }
        
        var image = Image(width: width, height: height)
        
        var currentY = 0
        for inner in inners {
            for drawable in repeat each inner {
                let offset = switch alignment {
                case .leading: 0
                case .trailing: width - drawable.width
                case .centered: (width - drawable.width) / 2
                }
                image.draw(drawable, x: offset, y: currentY)
                currentY += drawable.height + spacing
            }
        }
        
        self.image = image
    }
    
    public subscript(x: Int, y: Int) -> Color { image[x, y] }
    
    public enum Alignment { case leading, trailing, centered }
}

//public struct ForEach: Drawable {
//    public var image: Image
//    public var width: Int { image.width }
//    public var height: Int { image.height }
//    
//    public init<S: Sequence>(
//        _ sequence: S,
//        @DrawableBuilder drawables: (S.Element) -> some Drawable
//    ) {
//        let a = sequence.reduce(into: []) { acc, el in acc.append(drawables(el)) }
//    }
//    
//    public subscript(x: Int, y: Int) -> Color { image[x, y] }
//}
