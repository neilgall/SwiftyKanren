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

typealias Substitutions = [Term: Term]

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

func walk(_ s: Substitutions, _ t: Term) -> Term {
    switch t {
    case .variable:
        return s[t].map{ walk(s, $0) } ?? t
    default:
        return t
    }
}

struct State {
    let subs: Substitutions
    let vars: Int
    
    init(subs: Substitutions = [:], vars: Int = 0) {
        self.subs = subs
        self.vars = vars
    }
    
    func adding(subs newSubs: Substitutions) -> State {
        return State(subs: subs.union(newSubs), vars: vars)
    }
    
    func withNewVar(run f: (Term) -> Goal) -> [State] {
        let newVar = Term.variable(vars)
        let newState = State(subs: subs, vars: vars+1)
        let goal = f(newVar)
        return goal(newState)
    }
}

extension State: CustomStringConvertible {
    var description: String {
        let d = subs.map({ "\($0.0) = \($0.1)" }).joined(separator: ", ")
        return "[\(d)]"
    }
}

extension State {
    func unify(_ lhs: Term, _ rhs: Term) -> [State] {
        func unifyExpr(_ lhs: Term, _ rhs: Term) -> Substitutions? {
            switch (lhs, rhs) {
            case (.atom(let s), .atom(let t)) where s == t: return [:]
            case (.variable, _): return [lhs: rhs]
            case (_, .variable): return [rhs: lhs]
            default: return nil
            }
        }

        switch unifyExpr(walk(subs, lhs), walk(subs, rhs)) {
        case .none: return []
        case .some(let newSubs): return [adding(subs: newSubs)]
        }
    }
}

typealias Goal = (State) -> [State]

infix operator ===
func === (lhs: Term, rhs: Term) -> Goal {
    return { state in state.unify(lhs, rhs) }
}

func callFresh(_ f: @escaping (Term) -> Goal) -> Goal {
    return { state in state.withNewVar(run: f) }
}

func || (lhs: Goal, rhs: Goal) -> Goal {
    return { state in Array(transpose([lhs(state), rhs(state)]).joined()) }
}

func && (lhs: Goal, rhs: Goal) -> Goal {
    return { state in lhs(state).flatMap(rhs) }
}

// Convenience fresh functions for introducing multiple variables at once
func fresh(_ f: @escaping (Term, Term) -> Goal) -> Goal {
    return callFresh { (a: Term) in
        callFresh { (b: Term) in f((a,b)) }
    }
}
func fresh(_ f: @escaping (Term, Term, Term) -> Goal) -> Goal {
    return callFresh { (a: Term) in
        callFresh { (b: Term) in
            callFresh { (c: Term) in f((a,b,c)) }
        }
    }
}
func fresh(_ f: @escaping (Term, Term, Term, Term) -> Goal) -> Goal {
    return callFresh { (a: Term) in
        callFresh { (b: Term) in
            callFresh { (c: Term) in
                callFresh { (d: Term) in f((a,b,c,d)) }
            }
        }
    }
}


// -- Examples --
let emptyState = State()

// this will hang - infinite streams not supported yet
//func fives_(_ t: Term) -> Goal {
//    return (callFresh{ $0 === .atom("5") }) || fives_(t)
//}
//let fives = callFresh(fives_)

let five: Goal = callFresh { x in x === .atom("5") }
let six: Goal = callFresh { y in y === .atom("6") }

(five || six)(emptyState).description
(five && six)(emptyState).description

let aAndB: Goal =
    callFresh { a in a === .atom("quark") }
    && callFresh { b in (b === .atom("foo")) || (b === .atom("bar")) }

let fooState = State(subs: [.variable(1): .atom("foo")], vars: 0)

aAndB(emptyState).description
aAndB(fooState).description
