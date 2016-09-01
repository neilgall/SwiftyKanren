import Foundation

public let emptyState = State()

precedencegroup UnificationPrecedence {
    associativity: left
    higherThan: LogicalConjunctionPrecedence
    lowerThan: ComparisonPrecedence
}

infix operator =~= : UnificationPrecedence
public func =~= (lhs: Term, rhs: Term) -> Goal {
    return { state in state.unify(lhs, rhs) }
}

public func fresh(_ f: @escaping (Term) -> Goal) -> Goal {
    return { state in state.withNewVar(run: f) }
}

// Snooze
public func zzz(_ goal: Goal) -> Goal {
    return { state in .immature(get: { goal(state) }) }
}

public func conj_(_ goals: [Goal]) -> Goal {
    switch goals.count {
    case 0: return { state in [state] }
    case 1: return goals[0]
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

// Infix conj and disj
public func && (lhs: Goal, rhs: Goal) -> Goal {
    return { state in lhs(state).flatMap(zzz(rhs)) }
}

public func || (lhs: Goal, rhs: Goal) -> Goal {
    return { state in lhs(state) + zzz(rhs)(state) }
}


// Convenience fresh functions for introducing multiple variables at once
public func fresh(_ f: @escaping (Term, Term) -> Goal) -> Goal {
    return fresh { (a: Term) in
        fresh { (b: Term) in f(a,b) }
    }
}

public func fresh(_ f: @escaping (Term, Term, Term) -> Goal) -> Goal {
    return fresh { (a: Term) in
        fresh { (b: Term) in
            fresh { (c: Term) in f(a,b,c) }
        }
    }
}

public func fresh(_ f: @escaping (Term, Term, Term, Term) -> Goal) -> Goal {
    return fresh { (a: Term) in
        fresh { (b: Term) in
            fresh { (c: Term) in
                fresh { (d: Term) in f(a,b,c,d) }
            }
        }
    }
}

public func fresh(_ f: @escaping (Term, Term, Term, Term, Term) -> Goal) -> Goal {
    return fresh { (a: Term) in
        fresh { (b: Term) in
            fresh { (c: Term) in
                fresh { (d: Term) in
                    fresh { (e: Term) in f(a,b,c,d,e) }
                }
            }
        }
    }
}

public typealias KanrenResult = Stream<[Match]>

public func reify(count: Int) -> (State) -> [Match] {
    return { state in
        return (0..<count).map { i in
            let r = state.walk(.variable(Int(i)))
            return Match(term: r)
        }
    }
}

public func reifyMatching(state: State) -> [Match] {
    return (0..<state.vars).flatMap { (i: Int) -> Match? in
        let r = state.walk(.variable(i))
        let m = Match(term: r)
        return m == .none ? nil : m
    }
}

// Take wrapper
private func take(from goal: Goal, results count: Int?) -> Stream<State> {
    let stream = goal(emptyState)
    if let count = count {
        return stream.take(count: count)
    } else {
        return stream.takeAll()
    }
}

// Run
public func run(taking count: Int? = nil, goals: [Goal]) -> KanrenResult {
    return take(from: conj_(goals), results: count).map(reifyMatching)
}

public func run(taking count: Int? = nil, from goals: @escaping (Term) -> [Goal]) -> KanrenResult {
    let goal = fresh { a in conj_(goals(a)) }
    return take(from: goal, results: count).map(reify(count: 1))
}

public func run(taking count: Int? = nil, from goals: @escaping (Term, Term) -> [Goal]) -> KanrenResult {
    let goal = fresh { a, b in conj_(goals(a, b)) }
    return take(from: goal, results: count).map(reify(count: 2))
}

public func run(taking count: Int? = nil, from goals: @escaping (Term, Term, Term) -> [Goal]) -> KanrenResult {
    let goal = fresh { a, b, c in conj_(goals(a, b, c)) }
    return take(from: goal, results: count).map(reify(count: 3))
}

public func run(taking count: Int? = nil, from goals: @escaping (Term, Term, Term, Term) -> [Goal]) -> KanrenResult {
    let goal = fresh { a, b, c, d in conj_(goals(a, b, c, d)) }
    return take(from: goal, results: count).map(reify(count: 4))
}

public func run(taking count: Int? = nil, from goals: @escaping (Term, Term, Term, Term, Term) -> [Goal]) -> KanrenResult {
    let goal = fresh { a, b, c, d, e in  conj_(goals(a, b, c, d, e)) }
    return take(from: goal, results: count).map(reify(count: 5))
}

