import Foundation

public enum Stream<T> {
    case empty
    indirect case mature(head: T, tail: Stream<T>)
    indirect case immature(get: () -> (Stream<T>))
}

public struct StreamSequence<T>: Sequence, IteratorProtocol {
    private var stream: Stream<T>

    init(from stream: Stream<T>) {
        self.stream = stream
    }

    public mutating func next() -> T? {
        switch stream {
            case .empty:
                return nil
            case .mature(let head, let tail):
                stream = tail
                return head
            case .immature(let get):
                stream = get()
                return next()
        }
    }
}

extension Stream {
    public static func + (lhs: Stream<T>, rhs: Stream<T>) -> Stream<T> {
        switch (lhs, rhs) {
        case (_, .empty):
            return lhs
        case (.empty, _):
            return rhs
        case (.mature(let h, let t), _):
            return .mature(head: h, tail: t + rhs)
        case (.immature(let get), _):
            // interleave immature streams for a complete search strategy
            return .immature(get: { rhs + get() })
        }
    }
}

extension Stream {
    public func map<U>(_ transform: @escaping (T) -> U) -> Stream<U> {
        switch self {
        case .empty:
            return .empty
        case .mature(let head, let tail):
            return .mature(head: transform(head), tail: tail.map(transform))
        case .immature(let get):
            return .immature(get: { get().map(transform) })
        }
    }
    
    public func flatMap(_ transform: @escaping (T) -> Stream<T>) -> Stream<T> {
        switch self {
        case .empty:
            return .empty
        case .mature(let head, let tail):
            return transform(head) + tail.flatMap(transform)
        case .immature(let get):
            return .immature(get: { get().flatMap(transform) })
        }
    }
    
    public func take(count: Int) -> Stream<T> {
        guard count > 0 else { return .empty }
        switch self {
        case .empty: return .empty
        case .mature(let head, let tail):
            return .mature(head: head, tail: tail.take(count: count-1))
        case .immature(let get):
            return get().take(count: count)
        }
    }
    
    public func takeAll() -> Stream<T> {
        switch self {
        case .empty: return .empty
        case .mature(let head, let tail):
            return .mature(head: head, tail: tail.takeAll())
        case .immature(let get):
            return get().takeAll()
        }
    }

    public func toSequence() -> StreamSequence<T> {
        return StreamSequence(from: self)
    }
}


extension Stream: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: T...) {
        self = elements.reversed().reduce(.empty) { .mature(head: $1, tail: $0) }
    }
}

extension Stream: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return ""
        case .mature(let head, let tail):
            return "\(head)\(tail.internalDescription)"
        case .immature:
            return "..."
        }
    }
    
    private var internalDescription: String {
        switch self {
        case .empty:
            return ""
        case .mature(let head, let tail):
            return "; \(head)\(tail.internalDescription)"
        case .immature:
            return "; ..."
        }
    }
}
