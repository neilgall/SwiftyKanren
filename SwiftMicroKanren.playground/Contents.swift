// -- Examples --

run {
    [$0 + 5 =~= 9]
}

run {
    [($0 && false) =~= false]
}

func fives(t: Term) -> Goal {
    return fresh { $0 =~= 5 } || fresh(fives)
}
func sixes(t: Term) -> Goal {
    return fresh{ $0 =~= 6 } || fresh(sixes)
}

run(taking: 10, goals: [fresh(fives)])
run(taking: 10, goals: [fresh(fives) || fresh(sixes)])

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

run {
    [membero($0, [1,2,3,4,5])]
}

run {
    [membero(3, [$0, $1, 3])]
}

run {
    [lengtho($0, [1,2,3])]
}

let parent = relation(facts:
    ["Homer", "Bart"],
    ["Homer", "Lisa"],
    ["Homer", "Maggie"],
    ["Marge", "Bart"],
    ["Marge", "Lisa"],
    ["Marge", "Maggie"],
    ["Abe", "Homer"]
)

func grandparent(_ a: Term, _ b: Term) -> Goal {
    return fresh { c in
        parent(a, c) && parent(c, b)
    }
}

run {
    [parent($0, "Bart")]
}

run {
    [parent("Homer", $0)]
}

run {
    [grandparent($0, "Bart")]
}

// DOG + CAT = BAD
//run { digits, d, o, g, c in
//    [digits =~= [0,1,2,3,4,5,6,7,8,9],
//     membero(d, digits),
//     membero(o, digits), o =/= d,
//     membero(g, digits), g =/= d, g =/= o,
//     membero(c, digits), c =/= d, c =/= o, c =/= g,
//     fresh { a, t, b in conj(
//        membero(a, digits), a =/= d, a =/= o, a =/= g, a =/= c,
//        membero(t, digits), t =/= d, t =/= o, t =/= g, t =/= c, t =/= a,
//        membero(b, digits), b =/= d, b =/= o, b =/= g, b =/= c, b =/= a, b =/= t,
//        d + c =~= b,
//        o + a =~= a,
//        g + t =~= d
//    )}]
//}

//let digits: Term = [0,1,2,3,4,5,6,7,8,9]
//
//print(run { x in
//    [fresh { a,b,c in conj(
//        membero(a, digits), a =/= 0,
//        membero(b, digits), b =/= a,
//        membero(c, digits), c =/= a, c =/= b,
//        x =~= 100 * a + 10 * b + c)
//        }]
//})
