
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
