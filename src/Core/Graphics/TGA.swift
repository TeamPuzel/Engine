
/// A very unsafe experimental implementation of the TGA image format, ignores the header assuming
/// no additional information and just reads it blindly as 32 bit BGRA.
///
/// I will likely avoid improving it, rather I will implement a simpler format of my own
/// and add it to Aseprite (or write a custom editor within this engine, probably easier).
public struct UnsafeTGAPointer: Drawable {
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
