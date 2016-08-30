// See http://webyrd.net/scheme-2013/papers/HemannMuKanren2013.pdf

// -- Examples --
let emptyState = State()

func fives_(_ t: Term) -> Goal {
    return disj(fresh{ $0 =~= .atom("5") }, callFresh{ _ in fives_(t) })
}
let fives = callFresh(fives_)

func sixes_(_ t: Term) -> Goal {
    return disj(fresh{ $0 =~= .atom("6") }, callFresh{ _ in sixes_(t) })
}
let sixes = callFresh(sixes_)

fives(emptyState).take(count: 5)
disj(fives, sixes)(emptyState).take(count: 5)

let pair: Goal =
    fresh { w,x,y,z in
        (w =~= .pair(x, y))
        && (x =~= .atom("foo"))
        && (y =~= .pair(z, .atom("end")))
        && (z =~= .atom("bar"))
}

let aAndB: Goal =
    callFresh { a in a =~= .atom("quark") }
    && callFresh { b in (b =~= .atom("foo")) || (b =~= .atom("bar")) }

let fooState = State(subs: [.variable(1): .atom("foo")], vars: 0)

pair(emptyState)
aAndB(emptyState)
aAndB(fooState)
