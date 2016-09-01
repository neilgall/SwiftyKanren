import Foundation

public typealias Substitutions = [Term: Term]
public typealias Goal = (State) -> Stream<State>

extension Dictionary {
    func union(_ d: Dictionary<Key,Value>) -> Dictionary<Key, Value> {
        var r = self
        for (k,v) in d {
            r[k] = v
        }
        return r
    }
}

private func evaluate(lhs: Term, operation op: BinaryOperation, rhs: Term) -> Term? {
    switch op {
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

private func reverseEvaluateLHS(operation op: BinaryOperation, rhs: Term, result: Term) -> Term? {
    switch op {
    case .plus:
        guard case .int(let i1) = result, case .int(let i2) = rhs else { return nil }
        return .int(i1 - i2)
    case .minus:
        guard case .int(let i1) = result, case .int(let i2) = rhs else { return nil }
        return .int(i1 + i2)
    case .multiply:
        guard case .int(let i1) = result, case .int(let i2) = rhs else { return nil }
        return .int(i1 / i2)
    case .divide:
        guard case .int(let i1) = result, case .int(let i2) = rhs else { return nil }
        return .int(i1 * i2)
    case .mod:
        return nil
    case .and:
        guard case .bool(let b1) = result, case .bool(let b2) = rhs, b2 else { return nil }
        return .bool(b1)
    case .or:
        guard case .bool(let b1) = result, case .bool(let b2) = rhs, !b2 else { return nil }
        return .bool(b1)
    }
}

private func reverseEvaluateRHS(lhs: Term, operation op: BinaryOperation, result: Term) -> Term? {
    print(lhs, result, op)
    switch op {
    case .plus:
        guard case .int(let i1) = result, case .int(let i2) = lhs else { return nil }
        return .int(i1 - i2)
    case .minus:
        guard case .int(let i1) = result, case .int(let i2) = lhs else { return nil }
        return .int(-(i1 - i2))
    case .multiply:
        guard case .int(let i1) = result, case .int(let i2) = lhs else { return nil }
        return .int(i1 / i2)
    case .divide:
        guard case .int(let i1) = result, case .int(let i2) = lhs else { return nil }
        return .int(i2 / i1)
    case .mod:
        return nil
    case .and:
        guard case .bool(let b1) = result, case .bool(let b2) = lhs, b2 else { return nil }
        return .bool(b1)
    case .or:
        guard case .bool(let b1) = result, case .bool(let b2) = lhs, !b2 else { return nil }
        return .bool(b1)
    }
}

public struct State {
    let subs: Substitutions
    let vars: Int
    
    public init(subs: Substitutions = [:], vars: Int = 0) {
        self.subs = subs
        self.vars = vars
    }
    
    public func adding(subs newSubs: Substitutions) -> State {
        return State(subs: subs.union(newSubs), vars: vars)
    }
    
    public func withNewVar(run f: (Term) -> Goal) -> Stream<State> {
        let newVar = Term.variable(vars)
        let newState = State(subs: subs, vars: vars+1)
        let goal = f(newVar)
        return goal(newState)
    }
}

extension State {
    func walk(_ t: Term) -> Term {
        func substitute(_ term: Term) -> Term {
            return subs[term].map(walk) ?? term
        }
        
        switch t {
        case .variable:
            return substitute(t)
        case .pair(let p, let q):
            return .pair(substitute(p), substitute(q))
        case .binaryExpression(let p, let op, let q):
            return evaluate(lhs: substitute(p), operation: op, rhs: substitute(q)) ?? t
        default:
            return t
        }
    }
    
    func unifyExpr(_ lhs: Term, _ rhs: Term) -> Substitutions? {
        switch (lhs, rhs) {

        case (.string(let s1), .string(let s2)) where s1 == s2:
            return [:]
        
        case (.int(let i1), .int(let i2)) where i1 == i2:
            return [:]
        
        case (.bool(let b1), .bool(let b2)) where b1 == b2:
            return [:]
            
        case (.none, .none):
            return [:]

        case (.pair(let p1, let q1), .pair(let p2, let q2)):
            if let p = unifyExpr(p1, p2), let q = unifyExpr(q1, q2) {
                return p.union(q)
            } else {
                return nil
            }

        case (.variable, _):
            return [lhs: rhs]
        
        case (_, .variable):
            return [rhs: lhs]
        
        case (.binaryExpression(.variable(let v), let op, let exprRHS), _):
            guard let exprLHS = reverseEvaluateLHS(operation: op, rhs: exprRHS, result: rhs) else { return nil }
            return [.variable(v): exprLHS]

        case (.binaryExpression(let exprLHS, let op, .variable(let v)), _):
            guard let exprRHS = reverseEvaluateRHS(lhs: exprLHS, operation: op, result: rhs) else { return nil }
            return [.variable(v): exprRHS]

        case (_, .binaryExpression(.variable(let v), let op, let exprRHS)):
            guard let exprLHS = reverseEvaluateLHS(operation: op, rhs: exprRHS, result: lhs) else { return nil }
            return [.variable(v): exprLHS]
            
        case (_, .binaryExpression(let exprLHS, let op, .variable(let v))):
            guard let exprRHS = reverseEvaluateRHS(lhs: exprLHS, operation: op, result: lhs) else { return nil }
            return [.variable(v): exprRHS]

        default:
            return nil
        }
    }
    
   public func unify(_ lhs: Term, _ rhs: Term) -> Stream<State> {
        switch unifyExpr(walk(lhs), walk(rhs)) {
        case .none: return []
        case .some(let newSubs): return [adding(subs: newSubs)]
        }
    }
}

extension State: CustomStringConvertible {
    public var description: String {
        let d = subs.map({ "\($0.0) = \($0.1)" }).joined(separator: ", ")
        return "[\(d)]"
    }
}

