// -- Examples --

func fives(t: Term) -> Goal {
    return fresh { $0 =~= 5 } || fresh(fives)
}
func sixes(t: Term) -> Goal {
    return fresh{ $0 =~= 6 } || fresh(sixes)
}

run(taking: 10, from: [fresh(fives)])
run(taking: 10, from: [fresh(fives) || fresh(sixes)])

run {
    a, b in [
        a =~= "quark",
        b =~= "foo" || b =~= "bar"
    ]
}

run {
    x,y,z in [
        trace("x = z") ! x =~= z,
        y =~= 3,
        z =~= false
    ]
}

run {
    [appendo($0, [4,5], [1,2,3,4,5])]
}

run {
    [appendo([1,2], $0, [1,2,3,4,5])]
}

run {
    [appendo([1,2], [3,4,5], $0)]
}

run {
    [appendo($0, $1, [1,2,3,4,5])]
}

