// -- Examples --

func fives(t: Term) -> Goal {
    return fresh { $0 =~= 5 } || fresh(fives)
}
func sixes(t: Term) -> Goal {
    return fresh{ $0 =~= 6 } || fresh(sixes)
}

run(taking: 10, goals: [fresh(fives)])
run(taking: 10, goals: [fresh(fives) || fresh(sixes)])

run {
    [14 =~= $0 + 2, 14 =~= $1 - 2, 14 =~= $2 * 2, 14 =~= $3 / 2]
}
run {
    [15 =~= 3 + $0, 15 =~= 3 - $1, 15 =~= 3 * $2, 5 =~= 3 / $3]
}
run {
    [$0 + 6 =~= 10, $1 - 6 =~= 10, $2 * 4 =~= 20, $3 / 4 =~= 5]
}
run {
    [8 + $0 =~= 10, 18 - $1 =~= 10, 18 * $2 =~= 54, 18 / $3 =~= 9]
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
