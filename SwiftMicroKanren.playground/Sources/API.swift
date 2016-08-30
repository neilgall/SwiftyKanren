import Foundation

public let emptyState = State()

// Snooze
public func zzz(_ goal: Goal) -> Goal {
    return { state in .immature(get: { goal(state) }) }
}

public func conj_(_ goals: [Goal]) -> Goal {
    switch goals.count {
    case 0: return { state in [state] }
    case 1: return zzz(goals[0])
    default: return { state in goals.reduce([state]) { states, goal in states.flatMap(zzz(goal)) }}
    }
}

public func disj_(_ goals: [Goal]) -> Goal {
    return { state in goals.reduce(.empty) { states, goal in states + zzz(goal)(state) }}
}

// Variadic conj and disj
public func conj(_ goals: Goal...) -> Goal {
    return conj_(goals)
}

public func disj(_ goals: Goal...) -> Goal {
    return disj_(goals)
}

// Conde
public func conde(_ clauses: [Goal]...) -> Goal {
    return disj_(clauses.map(conj_))
}

// Convenience fresh functions for introducing multiple variables at once
public func fresh(_ f: @escaping (Term) -> Goal) -> Goal {
    return callFresh(f)
}

public func fresh(_ f: @escaping (Term, Term) -> Goal) -> Goal {
    return callFresh { (a: Term) in
        callFresh { (b: Term) in f((a,b)) }
    }
}

public func fresh(_ f: @escaping (Term, Term, Term) -> Goal) -> Goal {
    return callFresh { (a: Term) in
        callFresh { (b: Term) in
            callFresh { (c: Term) in f((a,b,c)) }
        }
    }
}

public func fresh(_ f: @escaping (Term, Term, Term, Term) -> Goal) -> Goal {
    return callFresh { (a: Term) in
        callFresh { (b: Term) in
            callFresh { (c: Term) in
                callFresh { (d: Term) in f((a,b,c,d)) }
            }
        }
    }
}

public func fresh(_ f: @escaping (Term, Term, Term, Term, Term) -> Goal) -> Goal {
    return callFresh { (a: Term) in
        callFresh { (b: Term) in
            callFresh { (c: Term) in
                callFresh { (d: Term) in
                    callFresh { (e: Term) in f((a,b,c,d,e)) }
                }
            }
        }
    }
}

// Typical miniKanren reification
public func reify(_ state: State) -> String {
    for i in 0..<state.vars {
        let r = state.walk(.variable(Int(i)))
        switch r {
        case .atom, .pair:
            return r.description
        default:
            break
        }
    }
    return ""
}

// Run
public func run(count: Int, goals: Goal...) -> Stream<String> {
    return conj_(goals)(emptyState).take(count: count).map(reify)
}

public func run(goals: Goal...) -> Stream<String> {
    return conj_(goals)(emptyState).takeAll().map(reify)
}
