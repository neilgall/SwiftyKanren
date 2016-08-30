// See http://webyrd.net/scheme-2013/papers/HemannMuKanren2013.pdf

// -- Examples --
func fives_(_ t: Term) -> Goal {
    return disj(fresh{ $0 =~= .atom("5") }, fives)
}
let fives = callFresh(fives_)

func sixes_(_ t: Term) -> Goal {
    return disj(fresh{ $0 =~= .atom("6") }, sixes)
}
let sixes = callFresh(sixes_)

run(count: 5, goals: fives)
run(count: 5, goals: disj(fives, sixes))

let aAndB: Goal =
    callFresh { a in a =~= .atom("quark") }
        && callFresh { b in (b =~= .atom("foo")) || (b =~= .atom("bar")) }

run(goals: aAndB)

let pair: Goal =
    fresh { w,x,y,z in
        (w =~= .pair(x, y))
        && (x =~= .atom("foo"))
        && (y =~= .pair(z, .atom("end")))
        && (z =~= .atom("bar"))
}

run(goals: pair)


