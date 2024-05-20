
#if canImport(Darwin)
import Darwin

fileprivate func getTime() -> Double {
    var timespec = timespec()
    clock_gettime(CLOCK_UPTIME_RAW, &timespec)
    return Double(timespec.tv_sec) * 1_000_000_000 + Double(timespec.tv_nsec)
}

#elseif canImport(Glibc)
import Glibc

fileprivate func getTime() -> Double {
    var timespec = timespec()
    clock_gettime(CLOCK_BOOTTIME, &timespec)
    return timespec.tv_nsec
}

#endif

public struct Timer: ~Copyable {
    private var prevTime: Double = getTime()
    public init() {}
    
    public var elapsed: Double {
        (getTime() - prevTime) / 1000000 // Converting nano to milliseconds
    }
    
    @discardableResult
    public mutating func lap() -> Double {
        let elapsed = elapsed
        prevTime = getTime()
        return elapsed
    }
}

public struct BufferedTimer: ~Copyable {
    public private(set) var inner: Timer = .init()
    private var buffer: [Double] = .init(repeating: 0, count: 360)
    public init() {}
    
    public var elapsed: Double { buffer.average() }
    
    @discardableResult
    public mutating func lap() -> Double {
        buffer.removeFirst()
        buffer.append(inner.lap())
        return elapsed
    }
}
