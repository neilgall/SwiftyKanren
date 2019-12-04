import Foundation

public enum Term {
    case none
    case string(String)
    case int(Int)
    case bool(Bool)
    case variable(Int)
    indirect case binaryExpression(Term, BinaryOperation, Term)
    indirect case pair(Term, Term)
}

public enum BinaryOperation: String {
    case plus = "+"
    case minus = "-"
    case multiply = "*"
    case divide = "/"
    case mod = "%"
    case and = "&&"
    case or = "||"
}

extension Term: Equatable {
    public static func == (lhs: Term, rhs: Term) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.variable(let v1), .variable(let v2)):
            return v1 == v2
        case (.string(let s1), .string(let s2)):
            return s1 == s2
        case (.int(let i1), .int(let i2)):
            return i1 == i2
        case (.bool(let b1), .bool(let b2)):
            return b1 == b2
        case (.pair(let p1, let q1), .pair(let p2, let q2)):
            return p1 == p2 && q1 == q2
        case (.binaryExpression(let t11, let op1, let t12), .binaryExpression(let t21, let op2, let t22)):
            return t11 == t21 && op1 == op2 && t12 == t22
        default:
            return false
        }
    }
}

extension Term: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .none:
            hasher.combine("none")
        case .variable(let n):
            hasher.combine("var")
            hasher.combine(n)
        case .string(let s):
            hasher.combine("str")
            hasher.combine(s)
        case .int(let i):
            hasher.combine("int")
            hasher.combine(i)
        case .bool(let b):
            hasher.combine("bool")
            hasher.combine(b)
        case .pair(let p, let q):
            hasher.combine("pair")
            hasher.combine(p)
            hasher.combine(q)
        case .binaryExpression(let t1, let op, let t2):
            hasher.combine("bin")
            hasher.combine(t1)
            hasher.combine(op)
            hasher.combine(t2)
        }
    }
}

extension Term: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none:
            return "nil"
        case .variable(let n):
            return ".\(n)"
        case .string(let s):
            return "\"\(s)\""
        case .int(let i):
            return "\(i)"
        case .bool(let b):
            return "\(b)"
        case .pair(let p, let q):
            return "(\(p), \(q))"
        case .binaryExpression(let t1, let op, let t2):
            return "(\(t1) \(op.rawValue) \(t2))"
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

// String operations
extension Term {
    public static func + (lhs: Term, rhs: String) -> Term {
        return .binaryExpression(lhs, .plus, .string(rhs))
    }
    public static func + (lhs: String, rhs: Term) -> Term {
        return .binaryExpression(.string(lhs), .plus, rhs)
    }
}

// Integer arithmetic
extension Term {
    public static func + (lhs: Term, rhs: Int) -> Term {
        return .binaryExpression(lhs, .plus, .int(rhs))
    }
    public static func + (lhs: Int, rhs: Term) -> Term {
        return .binaryExpression(.int(lhs), .plus, rhs)
    }

    public static func - (lhs: Term, rhs: Int) -> Term {
        return .binaryExpression(lhs, .minus, .int(rhs))
    }
    public static func - (lhs: Int, rhs: Term) -> Term {
        return .binaryExpression(.int(lhs), .minus, rhs)
    }
    public static func - (lhs: Term, rhs: Term) -> Term {
        return .binaryExpression(lhs, .minus, rhs)
    }
    
    public static func * (lhs: Term, rhs: Int) -> Term {
        return .binaryExpression(lhs, .multiply, .int(rhs))
    }
    public static func * (lhs: Int, rhs: Term) -> Term {
        return .binaryExpression(.int(lhs), .multiply, rhs)
    }
    public static func * (lhs: Term, rhs: Term) -> Term {
        return .binaryExpression(lhs, .multiply, rhs)
    }
    
    public static func / (lhs: Term, rhs: Int) -> Term {
        return .binaryExpression(lhs, .divide, .int(rhs))
    }
    public static func / (lhs: Int, rhs: Term) -> Term {
        return .binaryExpression(.int(lhs), .divide, rhs)
    }
    public static func / (lhs: Term, rhs: Term) -> Term {
        return .binaryExpression(lhs, .divide, rhs)
    }

    public static func % (lhs: Term, rhs: Int) -> Term {
        return .binaryExpression(lhs, .mod, .int(rhs))
    }
    public static func % (lhs: Int, rhs: Term) -> Term {
        return .binaryExpression(.int(lhs), .mod, rhs)
    }
    public static func % (lhs: Term, rhs: Term) -> Term {
        return .binaryExpression(lhs, .mod, rhs)
    }
}

// Boolean operations
extension Term {
    public static func && (lhs: Term, rhs: Bool) -> Term {
        return .binaryExpression(lhs, .and, .bool(rhs))
    }
    public static func && (lhs: Bool, rhs: Term) -> Term {
        return .binaryExpression(.bool(lhs), .and, rhs)
    }
    public static func && (lhs: Term, rhs: Term) -> Term {
        return .binaryExpression(lhs, .and, rhs)
    }

    public static func || (lhs: Term, rhs: Bool) -> Term {
        return .binaryExpression(lhs, .or, .bool(rhs))
    }
    public static func || (lhs: Bool, rhs: Term) -> Term {
        return .binaryExpression(.bool(lhs), .or, rhs)
    }
    public static func || (lhs: Term, rhs: Term) -> Term {
        return .binaryExpression(lhs, .or, rhs)
    }
}

// Ambiguous operations on two terms
extension Term {
    public static func + (lhs: Term, rhs: Term) -> Term {
        return .binaryExpression(lhs, .plus, rhs)
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
        case .none: return "nil"
        case .pair(let head, let tail):
            switch tail {
            case .pair, .none:
                return "[\(head)\(tail.internalDescription)]"
            default:
                return "(\(head), \(tail))"
            }
        }
    }
    
    private var internalDescription: String {
        switch self {
        case .none:
            return ""
        case .pair(let head, let tail):
            return ", \(head)\(tail.internalDescription)"
        default:
            return description
        }
    }
}

extension Match: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .none
    }
}

extension Match: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension Match: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

extension Match: ExpressibleByStringLiteral {
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

extension Match: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Match...) {
        self = elements.reversed().reduce(.none) { list, element in .pair(element, list) }
    }
}
