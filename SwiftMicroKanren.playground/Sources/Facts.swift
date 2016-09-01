import Foundation

public typealias Fact = [Term]

private func unify(fact: Fact, withTerms terms: [Term]) -> Goal? {
    guard fact.count == terms.count else { return nil }
    return conj_(zip(fact, terms).map { pair in pair.0 =~= pair.1 })
}

public func relation(facts: Fact...) -> (Term...) -> Goal {
    return { (terms: Term...) in
        return disj_(facts.flatMap { unify(fact: $0, withTerms: terms) })
    }
}
