import Foundation

// Snooze
public func zzz(_ goal: Goal) -> Goal {
    return { state in .immature(get: { goal(state) }) }
}

// Variadic conj and disj
public func conj(_ goals: Goal...) -> Goal {
    switch goals.count {
    case 0: return { state in [state] }
    case 1: return zzz(goals[0])
    default: return { state in goals.reduce([state]) { states, goal in states.flatMap(zzz(goal)) }}
    }
}

public func disj(_ goals: Goal...) -> Goal {
    return { state in goals.reduce(.empty) { states, goal in states + zzz(goal)(state) }}
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


