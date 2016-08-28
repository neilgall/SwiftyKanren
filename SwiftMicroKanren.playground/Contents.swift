// See http://webyrd.net/scheme-2013/papers/HemannMuKanren2013.pdf

enum Term {
    case variable(Int)
    case atom(String)
}

extension Term: Equatable {
    static func == (lhs: Term, rhs: Term) -> Bool {
        switch (lhs, rhs) {
        case (.variable(let n), .variable(let m)): return n == m
        case (.atom(let s), .atom(let t)): return s == t
        default: return false
        }
    }
}

extension Term: Hashable {
    var hashValue: Int {
        switch self {
        case .variable(let n): return n.hashValue
        case .atom(let s): return s.hashValue
        }
    }
}

extension Term: CustomStringConvertible {
    var description: String {
        switch self {
        case .variable(let n): return ".\(n)"
        case .atom(let s): return "\"\(s)\""
        }
    }
}

typealias Substitution = [Term: Term]

extension Dictionary {
    func union(_ d: Dictionary<Key,Value>) -> Dictionary<Key, Value> {
        var r = self
        for (k,v) in d {
            r[k] = v
        }
        return r
    }
}

func transpose<T>(_ matrix: [[T]]) -> [[T]] {
    var t: [[T]] = []
    let rows: Int = matrix.map({ $0.count }).max()!
    for i in 0..<rows {
        var row: [T] = []
        matrix.forEach { column in
            if i < column.count {
                row.append(column[i])
            }
        }
        t.append(row)
    }
    return t
}

func walk(_ s: Substitution, _ t: Term) -> Term {
    switch t {
    case .variable:
        return s[t].map({ x in walk(s, x) }) ?? t
    default:
        return t
    }
}

func unify(_ lhs: Term, _ rhs: Term, _ subs: Substitution) -> Substitution? {
    let unified = unifyExpr(walk(subs, lhs), walk(subs, rhs))
    return unified.map{$0.union(subs)}
}

func unifyExpr(_ lhs: Term, _ rhs: Term) -> Substitution? {
    switch (lhs, rhs) {
    case (.atom(let s), .atom(let t)) where s == t: return [:]
    case (.variable, _): return [lhs: rhs]
    case (_, .variable): return [rhs: lhs]
    default: return nil
    }
}

struct State: CustomStringConvertible {
    let subs: Substitution
    let vars: Int
    
    func with(subs newSubs: Substitution) -> State {
        return State(subs: newSubs, vars: vars)
    }
    
    func newVar() -> (Term, State) {
        let variable = Term.variable(vars)
        return (variable, State(subs: subs, vars: vars+1))
    }
    
    var description: String {
        let d = subs.map({ "\($0.0) = \($0.1)" }).joined(separator: ", ")
        return "[\(d)]"
    }
}

typealias Goal = (State) -> [State]

infix operator ===
func === (lhs: Term, rhs: Term) -> Goal {
    return { state in
        switch unify(lhs, rhs, state.subs) {
        case .none: return []
        case .some(let subs_): return [state.with(subs: subs_)]
        }
    }
}

func callFresh(_ f: @escaping (Term) -> Goal) -> Goal {
    return { state in
        let (newVar, nextState) = state.newVar()
        let goal = f(newVar)
        return goal(nextState)
    }
}

func || (lhs: Goal, rhs: Goal) -> Goal {
    return { state in
        return Array(transpose([lhs(state), rhs(state)]).joined())
    }
}

func && (lhs: Goal, rhs: Goal) -> Goal {
    return { state in
        return lhs(state).flatMap(rhs)
    }
}

// -- Examples --
let emptyState: State = State(subs: [:], vars: 0)

// infinite streams not supported yet
let five: Goal = callFresh { $0 === .atom("5") }
let six: Goal = callFresh { $0 === .atom("6") }

(five || six)(emptyState).description
(five && six)(emptyState).description

let aAndB: Goal =
    callFresh { $0 === .atom("quark") }
    && callFresh { ($0 === .atom("foo")) || ($0 === .atom("bar")) }

let fooState = State(subs: [.variable(1): .atom("foo")], vars: 0)

aAndB(emptyState).description
aAndB(fooState).description


