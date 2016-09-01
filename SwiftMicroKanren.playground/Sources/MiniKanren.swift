import Foundation

public func conde(_ clauses: [Goal]...) -> Goal {
    return disj_(clauses.map(conj_))
}

public func appendo(_ xs: Term, _ ys: Term, _ zs: Term) -> Goal {
    return
        (xs =~= nil && ys =~= zs)
        ||
        fresh { xh, xt, zt in conj(
            xs =~= .pair(xh, xt),
            zs =~= .pair(xh, zt),
            appendo(xt, ys, zt)
    )}
}

public func membero(_ x: Term, _ ys: Term) -> Goal {
    return
        fresh { h, t in conj(
            .pair(h, t) =~= ys,
            x =~= h || membero(x, t)
        )}
}
