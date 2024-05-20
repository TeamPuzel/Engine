
public extension BinaryInteger {
    func normalized(from: ClosedRange<Self>, to: ClosedRange<Self>) -> Self {
        (to.upperBound - to.lowerBound) / (from.upperBound - from.lowerBound) * (self - from.upperBound) + to.upperBound
    }
}

public extension FloatingPoint {
    func normalized(from: ClosedRange<Self>, to: ClosedRange<Self>) -> Self {
        (to.upperBound - to.lowerBound) / (from.upperBound - from.lowerBound) * (self - from.upperBound) + to.upperBound
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

public extension Sequence where Element: FloatingPointMath {
    /// Returns the average of all the numbers in the sequence.
    func average() -> Element {
        var count = 0
        let sum = self.reduce(into: Element.zero) { acc, el in acc += el; count += 1 }
        return sum / Element(count)
    }
}

public extension Sequence where Element: AdditiveArithmetic {
    /// Returns the sum of elements in the sequence.
    func sum() -> Element { self.reduce(into: Element.zero) { acc, el in acc += el } }
}

public extension Collection where Element: FloatingPointMath {
    /// Returns the average of all the numbers in the collection.
    func average() -> Element { self.sum() / Element(self.count) }
}
