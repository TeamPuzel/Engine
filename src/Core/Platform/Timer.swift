
#if canImport(Darwin)
import Darwin

fileprivate func getTime() -> Int {
    var timespec = timespec()
    clock_gettime(CLOCK_MONOTONIC, &timespec)
    return timespec.tv_nsec
}
#endif

public struct Timer: ~Copyable {
    private var prevTime: Int = getTime()
    public init() {}
    
    public var elapsed: Double {
        Double(getTime() - prevTime) / 1000000 // Converting nano to milliseconds
    }
    
    @discardableResult
    public mutating func lap() -> Double {
        let elapsed = elapsed
        prevTime = getTime()
        return elapsed
    }
}
