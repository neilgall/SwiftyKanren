import Foundation

public enum Term {
    case none
    case string(String)
    case int(Int)
    case bool(Bool)
    case variable(Int)
    indirect case pair(Term, Term)
}

extension Term: Equatable {
    public static func == (lhs: Term, rhs: Term) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none): return true
        case (.variable(let v1), .variable(let v2)): return v1 == v2
        case (.string(let s1), .string(let s2)): return s1 == s2
        case (.int(let i1), .int(let i2)): return i1 == i2
        case (.bool(let b1), .bool(let b2)): return b1 == b2
        case (.pair(let p1, let q1), .pair(let p2, let q2)): return p1 == p2 && q1 == q2
        default: return false
        }
    }
}

extension Term: Hashable {
    public var hashValue: Int {
        switch self {
        case .none: return 0
        case .variable(let n): return n.hashValue
        case .string(let s): return s.hashValue
        case .int(let i): return i.hashValue
        case .bool(let b): return b.hashValue
        case .pair(let p, let q): return p.hashValue ^ q.hashValue
        }
    }
}

extension Term: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none: return "nil"
        case .variable(let n): return ".\(n)"
        case .string(let s): return "\"\(s)\""
        case .int(let i): return "\(i)"
        case .bool(let b): return "\(b)"
        case .pair(let p, let q): return "(\(p),\(q))"
        }
    }
}

extension Term: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .none
    }
}

extension Term: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension Term: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

extension Term: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
    
    public init(extendedGraphemeClusterLiteral value: Character) {
        self = .string(String(value))
    }
    
    public init(unicodeScalarLiteral value: UnicodeScalar) {
        self = .string(String(value))
    }
}

extension Term: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Term...) {
        self = elements.reversed().reduce(.none) { list, element in .pair(element, list) }
    }
}

// Match is a Term in an output result
public enum Match {
    case string(String)
    case int(Int)
    case bool(Bool)
    indirect case pair(Match, Match)
    case none
}

extension Match: Equatable {
    public static func == (lhs: Match, rhs: Match) -> Bool {
        switch (lhs, rhs) {
        case (.string(let s1), .string(let s2)): return s1 == s2
        case (.int(let i1), .int(let i2)): return i1 == i2
        case (.bool(let b1), .bool(let b2)): return b1 == b2
        case (.pair(let p1, let q1), .pair(let p2, let q2)): return p1 == p2 && q1 == q2
        case (.none, .none): return true
        default: return false
        }
    }
}

extension Match {
    init(term: Term) {
        switch term {
        case .string(let s):
            self = .string(s)
        case .int(let i):
            self = .int(i)
        case .bool(let b):
            self = .bool(b)
        case .pair(let a, let b):
            let ma = Match(term: a)
            self = (ma == .none) ? .none : .pair(ma, Match(term: b))
        default:
            self = .none
        }
    }
}

extension Match: CustomStringConvertible {
    public var description: String {
        switch self {
        case .string(let s): return "\"\(s)\""
        case .int(let i): return "\(i)"
        case .bool(let b): return "\(b)"
        case .pair(let a, let b): return "(\(a.description), \(b.description))"
        case .none: return "nil"
        }
    }
}

