import Foundation

public func conde(_ clauses: [Goal]...) -> Goal {
    return disj_(clauses.map(conj_))
}

public func appendo(_ xs: Term, _ ys: Term, _ zs: Term) -> Goal {
    return
        (xs =~= nil && ys =~= zs)
        ||
        fresh { xhead, xtail, ztail in conj(
            xs =~= .pair(xhead, xtail),
            zs =~= .pair(xhead, ztail),
            appendo(xtail, ys, ztail)
    )}
}

public func membero(_ x: Term, _ ys: Term) -> Goal {
    return
        fresh { head, tail in
            .pair(head, tail) =~= ys && (x =~= head || membero(x, tail))
        }
}

public func lengtho(_ length: Term, _ xs: Term) -> Goal {
    return
        conj(xs =~= nil, length =~= 0)
        ||
        fresh { head, tail, tailLength in
            conj(
                .pair(head, tail) =~= xs,
                 lengtho(tailLength, tail),
                 length =~= tailLength + 1
            )
        }
}
