
/// A `Drawable` which can be rendered into, derives a lot of rendering functionality.
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
