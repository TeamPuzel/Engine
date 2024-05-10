
/// A `Drawable` which can be rendered into, derives a lot of rendering functionality.
public protocol MutableDrawable: Drawable {
    subscript(x: Int, y: Int) -> Color { get set }
}

public extension MutableDrawable {
    mutating func pixel(x: Int, y: Int, color: Color = .white) {
        if x < 0 || y < 0 || x >= width || y >= height { return }
        self[x, y] = color
    }
    
    mutating func clear(with color: Color = .black) {
        for x in 0..<width {
            for y in 0..<height {
                pixel(x: x, y: y, color: color)
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
                    self.pixel(x: ix + x, y: iy + y, color: color)
                }
            }
        }
    }
    
    mutating func rectangle(x: Int, y: Int, w: Int, h: Int, color: Color = .white, fill: Bool = false) {
        for ix in 0..<w {
            for iy in 0..<h {
                if ix + x == x || ix + x == x + w - 1 || iy + y == y || iy + y == y + h - 1 || fill {
                    self.pixel(x: ix + x, y: iy + y, color: color)
                }
            }
        }
    }
    
    mutating func circle(x: Int, y: Int, r: Int, color: Color = .white, fill: Bool = false) {
        guard r >= 0 else { return }
        for ix in (x - r)..<(x + r + 1) {
            for iy in (y - r)..<(y + r + 1) {
                let distance = Int(Double(((ix - x) * (ix - x)) + ((iy - y) * (iy - y))).squareRoot().rounded())
                if fill {
                    if distance <= r { self.pixel(x: ix, y: iy, color: color) }
                } else {
                    if distance == r { self.pixel(x: ix, y: iy, color: color) }
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
}

// MARK: - Hardware (Experimental)

/// Select types such as `Rectangle` can be efficiently rendered on hardware. For this reason
/// They can provide a custom draw method with direct access to a given hardware renderer.
///
/// For hardware rendering to be possible the most external drawable has to be `HardwareDrawable`,
/// otherwise there is no way to tell if some nested drawable can be rendered on hardware.
public protocol HardwareDrawable<Renderer>: Drawable {
    associatedtype Renderer: HardwareRenderer
    func draw(into renderer: inout Renderer)
}

public protocol HardwareRenderer {}

public extension HardwareRenderer {
    mutating func draw(_ drawable: some HardwareDrawable<Self>, x: Int, y: Int) {
        drawable.draw(into: &self)
    }
}
