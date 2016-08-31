import Foundation

func trace(goal: Goal) -> Goal {
    return { state in
        print("trace:", state)
        return goal(state)
    }
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