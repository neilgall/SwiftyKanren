// -- Examples --

func fives_(_ t: Term) -> Goal {
    return fresh{ $0 =~= 5 } || fives
}
let fives: Goal = fresh(fives_)

func sixes_(_ t: Term) -> Goal {
    return fresh{ $0 =~= 6 } || sixes
}
let sixes: Goal = fresh(sixes_)

run(taking: 10, from: [fives])
run(taking: 10, from: [fives || sixes])

run {
    a, b in [
        a =~= "quark",
        b =~= "foo" || b =~= "bar"
    ]
}

run {
    x,y,z in [
        x =~= z,
        y =~= 3,
        z =~= false
    ]
}

run {
    w,x,y,z in [
        w =~= .pair(x, y),
        x =~= "foo",
        y =~= .pair(z, "end"),
        z =~= "bar"
    ]
}


