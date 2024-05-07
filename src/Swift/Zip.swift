
struct Zip<each S: Sequence> {
    private let sequences: (repeat each S)
    
    init(_ sequences: repeat each S) {
        self.sequences = (repeat each sequences)
    }
}

extension Zip: Sequence {
    typealias Element = (repeat (each S).Element)
    typealias Iterator = ZipIterator<repeat (each S).Iterator>
    
    func makeIterator() -> ZipIterator<repeat (each S).Iterator> {
        .init((repeat InteriorMutable((each self.sequences).makeIterator())))
    }
}

struct ZipIterator<each I: IteratorProtocol>: IteratorProtocol {
    private var iterators: (repeat InteriorMutable<each I>)
    private var index: Int = 0
    
    fileprivate init(_ iterators: (repeat InteriorMutable<each I>)) {
        self.iterators = iterators
    }
    
    mutating func next() -> (repeat (each I).Element)? {
        do {
            return (repeat try Self.unwrapIter(each iterators))
        } catch {
            return nil
        }
    }
    
    private static func unwrapIter<T: IteratorProtocol>(_ iter: InteriorMutable<T>) throws(PhantomError) -> T.Element {
        if let next = iter.inner.next() {
            return next
        } else {
            throw .error
        }
    }
}

fileprivate enum PhantomError: Error { case error }

fileprivate final class InteriorMutable<T> {
    var inner: T
    
    init(_ inner: T) {
        self.inner = inner
    }
}
