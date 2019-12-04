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
            return op.evaluate(lhs: walk(p), rhs: walk(q)) ?? t
        default:
            return t
        }
    }
    
    func unifyExpr(_ lhs: Term, _ rhs: Term) -> Stream<Substitutions>? {
        let unified: Stream<Substitutions> = .mature(head: [:], tail: .empty)
        
        switch (lhs, rhs) {

        case (.string(let s1), .string(let s2)) where s1 == s2:
            return unified
        
        case (.int(let i1), .int(let i2)) where i1 == i2:
            return unified
        
        case (.bool(let b1), .bool(let b2)) where b1 == b2:
            return unified
            
        case (.none, .none):
            return unified

        case (.pair(let p1, let q1), .pair(let p2, let q2)):
            guard let ps = unifyExpr(p1, p2), let qs = unifyExpr(q1, q2) else { return nil }
            return ps.flatMap { p in qs.map { q in p.union(q) } }

        case (.variable, _):
            return [ [lhs: rhs] ]
        
        case (_, .variable):
            return [ [rhs: lhs] ]
        
        case (.binaryExpression(.variable(let v), let op, let exprRHS), _):
            guard let exprLHS = op.reverseEvaluateLHS(rhs: exprRHS, result: rhs) else { return nil }
            return  exprLHS.map { [.variable(v): $0] }

        case (.binaryExpression(let exprLHS, let op, .variable(let v)), _):
            guard let exprRHS = op.reverseEvaluateRHS(lhs: exprLHS, result: rhs) else { return nil }
            return exprRHS.map { [.variable(v): $0] }

        case (_, .binaryExpression(.variable(let v), let op, let exprRHS)):
            guard let exprLHS = op.reverseEvaluateLHS(rhs: exprRHS, result: lhs) else { return nil }
            return exprLHS.map { [.variable(v): $0] }
            
        case (_, .binaryExpression(let exprLHS, let op, .variable(let v))):
            guard let exprRHS = op.reverseEvaluateRHS(lhs: exprLHS, result: lhs) else { return nil }
            return exprRHS.map { [.variable(v): $0] }

        default:
            return nil
        }
    }
    
   public func unify(_ lhs: Term, _ rhs: Term) -> Stream<State> {
        switch unifyExpr(walk(lhs), walk(rhs)) {
        case .none: return []
        case .some(let newSubs): return newSubs.map { self.adding(subs: $0) }
        }
    }
    
    public func disunify(_ lhs: Term, _ rhs: Term) -> Stream<State> {
        switch unifyExpr(walk(lhs), walk(rhs)) {
        case .none: return [self]
        case .some: return []
        }
    }
}

extension State: CustomStringConvertible {
    public var description: String {
        let d = subs.map({ "\($0.0) = \($0.1)" }).joined(separator: ", ")
        return "[\(d)]"
    }
}

