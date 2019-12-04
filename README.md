# SwiftyKanren
Swift 4 implementation of µKanren. I have also done a Kotlin port [here](https://github.com/neilgall/KotlinKanren).

See the original paper at http://webyrd.net/scheme-2013/papers/HemannMuKanren2013.pdf

## What's going on?
[miniKanren](http://www.minikanren.org)'s website describes it as a Domain Specific Language for logic programming. Logic programming is somewhat different from most other kinds of programming. Rather than tell the computer exactly what to do, we describe the problem to be solved. Unknowns are left as placeholders and the logic system finds solutions to them.

For (a classic) example, in traditional programming you might append two lists: `append(a,b)` gives you `a+b`. You have to know `a` and `b` first, so the computer's not being very smart. In logic programming `append` takes three arguments `a`, `b` and `c` and finds a solution where `c == a+b`.

    append(a, [4,5], [1,2,3,4,5])
    
Gives an answer for `a` which is `[1,2,3]`, since that's what you need to append `[4,5]` to to get `[1,2,3,4,5]`.

    append([1,2], b, [1,2,3,4,5])
    
Gives an answer for `b` which is `[3,4,5]`, since that's what you need to append to `[1,2]` to get `[1,2,3,4,5]`. And

    append([1,2], [3,4,5], c)
    
Gives an answer for `c` which is `[1,2,3,4,5]`, much like traditional programming.

But what if you do this?

    append(a, b, [1,2,3,4,5])

You get a list of answers:

    [], [1,2,3,4,5]
    [1], [2,3,4,5]
    [1,2], [3,4,5]
    [1,2,3], [4,5]
    [1,2,3,4], [5]
    [1,2,3,4,5], []

All of those are acceptable solutions, and logic programming finds them all. Finally, you might try:

    append([8,9], [3,4,5], [1,2,3,4,5])

A logic programming system will give you no answers, as the _relation_ defined by `append` does not hold for these inputs.

## Why Swift 3.0

The original miniKanren is embedded in Scheme and there are many other implementations, but none I could find in Swift. Standalone systems are all well and good, but embedding a DSL in your main programming language makes it easy to use within the scope of a larger application. Swift's language features (custom operators, first class function types, custom types expressible as constants) actually make it a pretty good choice for embedded DSLs and I needed a vehicle for playing with Swift 3.0 so here we are.

## The DSL

The language embedded in Swift aims to be an implementation of miniKanren, as far as Swift syntax and semantics allow. There are two main concepts: _Terms_ and _Goals_. A `Term` is a value, which can be a string, integer, boolean, nil, or a pair of any of these. If you've read SICP you know that pairs allow you to implement lists. `Term` conforms to `ExpressibleByArrayLiteral` so you can write

    [1,2,3]

and the compiler turns it into the `Term`

    .pair(1, .pair(2, .pair(3, .nil)))

A `Term` can also be a variable. Logic variables are introduced with the primitive `fresh`, of which there are currently variations for introducing one to five variables at a time. You pass `fresh` a block which receives these one to five new `Term`s and from the block you return a `Goal`.

Under the hood a `Goal` is a function of type `State -> Stream<State>` but in general you can ignore that. The DSL provides a few primitives and combinators which all yield `Goal`s, so you can keep working (and thinking) at the logic DSL level.

The fundamental primitive for building `Goal`s is `=~=`, pronounced _unify_. It is an infix operator which attempts to make the values on both sides equal. If one value is a constant and the other a variable, the variable takes on that constant value for subsequent computation down the same path. More on that in a bit. First an example:

    fresh { a in a =~= 2 }

This yields a `Goal` which unifies the variable `a` with the constant 2. Execute a group of `Goal`s with `run`:

    run(goals: [fresh { a in a =~= 2 }])

All the goals provided to `run` must agree, in that they are executed as if combined with the `&&` operator. The return value of `run` is a `KanrenResult` which is just a typealias for `Stream<[Match]>`. A Stream is like an array but can be lazily evaluated to support goals with many or even infinite results. Calling the above version of `run` automatically pulls all the results from the stream. Each item in the stream is an array of `Match`, which is like a `Term` but cannot hold variables. In each result there is one `Match` for every variable introduced by `fresh` which unified to some value. In the above case there will be one result in the stream, containing one `Match` with the integer value 2. But that's not very interesting. We can assign 2 to `a` in any language.

    run(goals: [fresh { a,b,c in a =~= b && b =~= c && c =~= 5 }])

This yields a single result with three `Match`es, all equal to 5.

    run(goals: [fresh { a,b,c in (a =~= b || a =~ c) && b =~= 8 && c =~= 3 }])

This yields two results with values [8,8,3] and [3,8,3]. `b` and `c` are fixed but there are two unifications for `a` which work.

## Run+fresh syntactic sugar

You almost always want to introduce new variables when you call `run`, so there are some additional versions which do that for you. Like `fresh`, from one to five variables are currently supported.

    run { [a in a =~= 2] }

Or using Swift's closure index variables, just

    run { [$0 =~= 2] }

mean the same as

    run(goals: [fresh { a in a =~= 2 }])
    
Note that you still must return a list of `Goal`s from the block. A typical logic program involves more than one goal.

## Lists

Two list operations are currently implemented: `appendo` and `membero`. It is a miniKanren tradition to attach an o to relational versions of functions.

`appendo` works like the example above:

    run(goals: [fresh {a,b in appendo(a, b, [1,2,3,4,5])}])

This yields all the combinations of two lists which append to give 1..5.

`membero` unifies a `Term` with any member of a list:

    run(goals: [fresh {a in membero(a, [1,2,3])}])

The above finds three results containing 1, 2 and 3 respectively.

More list operations to come.

## Facts

Logic programming is often used to find the solutions to one or more unknowns within the context of a set of fixed relations. The classic example is geneaology. SwiftyKanren lets you introduce fixed relations with the `relation` primitive:

    let parent = relation(facts:
        ["Homer", "Bart"],
        ["Homer", "Lisa"],
        ["Homer", "Maggie"],
        ["Marge", "Bart"],
        ["Marge", "Lisa"],
        ["Marge", "Maggie"],
        ["Abe", "Homer"]
    )

Each `Fact` is just a list of non-variable `Term`s. Typically each fact contains the same number of terms but this does not have to be the case. The return value of `relation` is a function which, like `=~=`, `appendo`, etc. can be used to generate `Goal`s.

    run {
        [parent($0, "Bart")]
    }

You get two results: "Marge" and "Homer". Swapping the variable to the other position performs the fact lookup in the other direction:

    run {
        [parent("Homer", $0)]
    }

Here there are three results containing "Bart", "Lisa" and "Maggie".

## Goal generators

You can write your own `Goal` generation functions by combining existing ones. All you have to remember is that these functions must accept one or more `Term`s and always return a `Goal`. You can introduce new variables if that helps the definition of your goal:

    func grandparent(_ a: Term, _ b: Term) -> Goal {
        return fresh { c in
            parent(a, c) && parent(c, b)
        }
    }

The `grandparent` relation holds if for a given `a` and `b`, there is a `c` which is a child of `a` and the parent of `b`.

That's it for now. Please download it, load the playground into Xcode 8 and tinker with it. I'd love to hear what you think.





