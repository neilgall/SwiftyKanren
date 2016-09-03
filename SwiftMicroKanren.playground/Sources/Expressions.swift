import Foundation

extension BinaryOperation {
    public func evaluate(lhs: Term, rhs: Term) -> Term? {
        switch self {
        case .plus:
            switch (lhs, rhs) {
            case (.int(let i1), .int(let i2)):
                return .int(i1 + i2)
            case (.string(let s1), .string(let s2)):
                return .string(s1 + s2)
            default:
                return nil
            }
        case .minus:
            guard case .int(let i1) = lhs, case .int(let i2) = rhs else { return nil }
            return .int(i1 - i2)
        case .multiply:
            guard case .int(let i1) = lhs, case .int(let i2) = rhs else { return nil }
            return .int(i1 * i2)
        case .divide:
            guard case .int(let i1) = lhs, case .int(let i2) = rhs else { return nil }
            return .int(i1 / i2)
        case .mod:
            guard case .int(let i1) = lhs, case .int(let i2) = rhs else { return nil }
            return .int(i1 % i2)
        case .and:
            guard case .bool(let b1) = lhs, case .bool(let b2) = rhs else { return nil }
            return .bool(b1 && b2)
        case .or:
            guard case .bool(let b1) = lhs, case .bool(let b2) = rhs else { return nil }
            return .bool(b1 || b2)
        }
    }
    
    public func reverseEvaluateLHS(rhs: Term, result: Term) -> Stream<Term>? {
        switch self {
        case .plus:
            guard case .int(let i1) = result, case .int(let i2) = rhs else { return nil }
            return [.int(i1 - i2)]
        case .minus:
            guard case .int(let i1) = result, case .int(let i2) = rhs else { return nil }
            return [.int(i1 + i2)]
        case .multiply:
            guard case .int(let i1) = result, case .int(let i2) = rhs else { return nil }
            return [.int(i1 / i2)]
        case .divide:
            guard case .int(let i1) = result, case .int(let i2) = rhs else { return nil }
            return [.int(i1 * i2)]
        case .mod:
            return nil
        case .and:
            guard case .bool(let b1) = result, case .bool(let b2) = rhs else { return nil }
            return b2 ? [.bool(b1)] : [false, true]
        case .or:
            guard case .bool(let b1) = result, case .bool(let b2) = rhs else { return nil }
            return b2 ? [false, true] : [.bool(b1)]
        }
    }
    
    public func reverseEvaluateRHS(lhs: Term, result: Term) -> Stream<Term>? {
        switch self {
        case .plus:
            guard case .int(let i1) = result, case .int(let i2) = lhs else { return nil }
            return [.int(i1 - i2)]
        case .minus:
            guard case .int(let i1) = result, case .int(let i2) = lhs else { return nil }
            return [.int(-(i1 - i2))]
        case .multiply:
            guard case .int(let i1) = result, case .int(let i2) = lhs else { return nil }
            return [.int(i1 / i2)]
        case .divide:
            guard case .int(let i1) = result, case .int(let i2) = lhs else { return nil }
            return [.int(i2 / i1)]
        case .mod:
            return nil
        case .and:
            guard case .bool(let b1) = result, case .bool(let b2) = lhs else { return nil }
            return b2 ? [.bool(b1)] : [false, true]
        case .or:
            guard case .bool(let b1) = result, case .bool(let b2) = lhs else { return nil }
            return !b2 ? [.bool(b1)] : [false, true]
        }
    }
}

