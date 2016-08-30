// See http://webyrd.net/scheme-2013/papers/HemannMuKanren2013.pdf

// -- Examples --
let emptyState = State()

func fives_(_ t: Term) -> Goal {
    return disj(fresh{ $0 =~= .atom("5") }, fives)
}
let fives = callFresh(fives_)

func sixes_(_ t: Term) -> Goal {
    return disj(fresh{ $0 =~= .atom("6") }, sixes)
}
let sixes = callFresh(sixes_)

fives(emptyState).take(count: 5)
disj(fives, sixes)(emptyState).take(count: 5)

let aAndB: Goal =
    callFresh { a in a =~= .atom("quark") }
        && callFresh { b in (b =~= .atom("foo")) || (b =~= .atom("bar")) }

aAndB(emptyState)

let pair: Goal =
    fresh { w,x,y,z in
        (w =~= .pair(x, y))
        && (x =~= .atom("foo"))
        && (y =~= .pair(z, .atom("end")))
        && (z =~= .atom("bar"))
}
pair(emptyState)

