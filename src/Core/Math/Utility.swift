
public extension BinaryInteger {
    func normalized(from: ClosedRange<Self>, to: ClosedRange<Self>) -> Self {
        (to.upperBound - to.lowerBound) / (from.upperBound - from.lowerBound) * (self - from.lowerBound) + to.upperBound
    }
}

public extension FloatingPoint {
    func normalized(from: ClosedRange<Self>, to: ClosedRange<Self>) -> Self {
        (to.upperBound - to.lowerBound) / (from.upperBound - from.lowerBound) * (self - from.lowerBound) + to.upperBound
    }
}

public protocol Fractional {
    static func / (lhs: Self, rhs: Self) -> Self
}

extension Float16: Fractional {}
extension Float32: Fractional {}
extension Float64: Fractional {}

extension Int8: Fractional {}
extension Int16: Fractional {}
extension Int32: Fractional {}
extension Int64: Fractional {}

extension UInt8: Fractional {}
extension UInt16: Fractional {}
extension UInt32: Fractional {}
extension UInt64: Fractional {}
