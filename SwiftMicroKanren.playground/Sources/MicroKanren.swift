import Foundation

public enum Term {
    case atom(String)
    case variable(Int)
    indirect case pair(Term, Term)
}

extension Term: Equatable {
    public static func == (lhs: Term, rhs: Term) -> Bool {
        switch (lhs, rhs) {
        case (.variable(let v1), .variable(let v2)): return v1 == v2
        case (.atom(let a1), .atom(let a2)): return a1 == a2
        case (.pair(let p1, let q1), .pair(let p2, let q2)): return p1 == p2 && q1 == q2
        default: return false
        }
    }
}

extension Term: Hashable {
    public var hashValue: Int {
        switch self {
        case .variable(let n): return n.hashValue
        case .atom(let s): return s.hashValue
        case .pair(let p, let q): return p.hashValue ^ q.hashValue
        }
    }
}

extension Term: CustomStringConvertible {
    public var description: String {
        switch self {
        case .variable(let n): return ".\(n)"
        case .atom(let s): return "\"\(s)\""
        case .pair(let p, let q): return "(\(p),\(q))"
        }
    }
}

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
    
    func adding(subs newSubs: Substitutions) -> State {
        return State(subs: subs.union(newSubs), vars: vars)
    }
    
    func withNewVar(run f: (Term) -> Goal) -> Stream<State> {
        let newVar = Term.variable(vars)
        let newState = State(subs: subs, vars: vars+1)
        let goal = f(newVar)
        return goal(newState)
    }
}

extension State {
    func walk(_ t: Term) -> Term {
        func recur(_ term: Term) -> Term {
            return subs[term].map(walk) ?? term
        }
        
        switch t {
        case .variable:
            return recur(t)
        case .pair(let p, let q):
            return .pair(recur(p), recur(q))
        default:
            return t
        }
    }
    
    func unifyExpr(_ lhs: Term, _ rhs: Term) -> Substitutions? {
        switch (lhs, rhs) {
        case (.atom(let s), .atom(let t)) where s == t:
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
        default:
            return nil
        }
    }
    
    func unify(_ lhs: Term, _ rhs: Term) -> Stream<State> {
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


infix operator =~=
public func =~= (lhs: Term, rhs: Term) -> Goal {
    return { state in state.unify(lhs, rhs) }
}

public func callFresh(_ f: @escaping (Term) -> Goal) -> Goal {
    return { state in state.withNewVar(run: f) }
}

public func || (lhs: Goal, rhs: Goal) -> Goal {
    return { state in lhs(state) + rhs(state) }
}

public func && (lhs: Goal, rhs: Goal) -> Goal {
    return { state in lhs(state).flatMap(rhs) }
}

