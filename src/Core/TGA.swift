
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
    
    public var data: UnsafeBufferPointer<BGRA> {
        .init(
            start: base.advanced(by: 18).bindMemory(to: BGRA.self, capacity: width * height),
            count: width * height
        )
    }
    
    public subscript(x: Int, y: Int) -> BGRA { data[x + y * width] }
}

public struct UnsafeTGA: Drawable {
    private let data: [UInt8]
    
    public init(_ data: [UInt8]) { self.data = data }
    
    public var width: Int {
        data.withUnsafeBufferPointer { buf in
            Int(UnsafeRawPointer(buf.baseAddress!).load(fromByteOffset: 12, as: UInt16.self))
        }
    }
    
    public var height: Int {
        data.withUnsafeBufferPointer { buf in
            Int(UnsafeRawPointer(buf.baseAddress!).load(fromByteOffset: 14, as: UInt16.self))
        }
    }
    
    private var colorBuffer: UnsafeBufferPointer<BGRA> {
        data.withUnsafeBufferPointer { buf in
            .init(
                start: UnsafeRawPointer(buf.baseAddress!).advanced(by: 18).bindMemory(to: BGRA.self, capacity: width * height),
                count: width * height
            )
        }
    }
    
    public subscript(x: Int, y: Int) -> BGRA { colorBuffer[x + y * width] }
}
