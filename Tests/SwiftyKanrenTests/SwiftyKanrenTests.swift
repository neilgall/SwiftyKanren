import XCTest
@testable import SwiftyKanren

final class SwiftyKanrenTests: XCTestCase {
    func testArithmetic() {
		var result = runKanren {
		    [$0 + 5 =~= 9]
		}
		XCTAssertEqual(result.next(), [4])
		XCTAssertEqual(result.next(), nil)
	}

	func testLogic() {
		var result = runKanren {
		    [($0 && false) =~= false]
		}
		XCTAssertEqual(result.next(), [false])
		XCTAssertEqual(result.next(), [true])
		XCTAssertEqual(result.next(), nil)
	}

	func fives(t: Term) -> Goal {
	    return fresh { $0 =~= 5 } || fresh(fives)
	}

	func sixes(t: Term) -> Goal {
	    return fresh{ $0 =~= 6 } || fresh(sixes)
	}

//	func testInfiniteSequence() {
//		var result = runKanren(taking: 10, goals: [fresh(fives)])
//		for i in 0..<10 {
//			XCTAssertEqual(result.next(), [5])
//		}
//		XCTAssertEqual(result.next(), nil)
//	}
//
//	func testInfiniteSequenceInterleave() {
//		var result = runKanren(taking: 10, goals: [fresh(fives) || fresh(sixes)])
//		for i in 0..<5 {
//			XCTAssertEqual(result.next(), [5])
//			XCTAssertEqual(result.next(), [6])
//		}
//		XCTAssertEqual(result.next(), nil)
//	}

	func testAppendoReverse1() {
		var result = runKanren {
		    [appendo($0, [4,5], [1,2,3,4,5])]
		}
		XCTAssertEqual(result.next(), [[1,2,3]])
		XCTAssertEqual(result.next(), nil)
	}

	func testAppendoReverse2() {
		var result = runKanren {
		    [appendo([1,2], $0, [1,2,3,4,5])]
		}
		XCTAssertEqual(result.next(), [[3,4,5]])
		XCTAssertEqual(result.next(), nil)
	}

	func testAppendoReverse3() {
		var result = runKanren {
		    [appendo($0, $1, [1,2,3,4,5])]
		}
		XCTAssertEqual(result.next(), [[], [1,2,3,4,5]])
		XCTAssertEqual(result.next(), [[1], [2,3,4,5]])
		XCTAssertEqual(result.next(), [[1,2], [3,4,5]])
		XCTAssertEqual(result.next(), [[1,2,3], [4,5]])
		XCTAssertEqual(result.next(), [[1,2,3,4], [5]])
		XCTAssertEqual(result.next(), [[1,2,3,4,5], []])
		XCTAssertEqual(result.next(), nil)
	}

	func testAppendoForward() {
		var result = runKanren {
		    [appendo([1,2], [3,4,5], $0)]
		}
		XCTAssertEqual(result.next(), [[1,2,3,4,5]])
		XCTAssertEqual(result.next(), nil)
	}

	func testMemberoReverse() { 
		var result = runKanren {
		    [membero($0, [1,2,3,4,5])]
		}
		XCTAssertEqual(result.next(), [1])
		XCTAssertEqual(result.next(), [2])
		XCTAssertEqual(result.next(), [3])
		XCTAssertEqual(result.next(), [4])
		XCTAssertEqual(result.next(), [5])
		XCTAssertEqual(result.next(), nil)
	}

	func testMemberoForward() {
		var result = runKanren {
		    [membero(3, [$0, $1, 3])]
		}
		XCTAssertEqual(result.next(), [3, nil])
		XCTAssertEqual(result.next(), [nil, 3])
		XCTAssertEqual(result.next(), [nil, nil])
		XCTAssertEqual(result.next(), nil)
	}

	func testLengtho() {
		var result = runKanren {
		    [lengtho($0, [1,2,3])]
		}
		XCTAssertEqual(result.next(), [3])
		XCTAssertEqual(result.next(), nil)
	}

	func testRelation() {
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

		var result1 = runKanren {
		    [parent($0, "Bart")]
		}
		XCTAssertEqual(result1.next(), ["Marge"])
		XCTAssertEqual(result1.next(), ["Homer"])
		XCTAssertEqual(result1.next(), nil)

		var result2 = runKanren {
		    [parent("Homer", $0)]
		}
		XCTAssertEqual(result2.next(), ["Maggie"])
		XCTAssertEqual(result2.next(), ["Bart"])
		XCTAssertEqual(result2.next(), ["Lisa"])
		XCTAssertEqual(result2.next(), nil)

		var result3 = runKanren {
		    [grandparent($0, "Bart")]
		}
		XCTAssertEqual(result3.next(), ["Abe"])
		XCTAssertEqual(result3.next(), nil)
	}

    static var allTests = [
        ("testArithmetic", testArithmetic),
        ("testLogic", testLogic),
//        ("testInfiniteSequence", testInfiniteSequence),
//        ("testInfiniteSequenceInterleave", testInfiniteSequenceInterleave),
        ("testAppendoReverse1" ,testAppendoReverse1),
        ("testAppendoReverse2" ,testAppendoReverse2),
        ("testAppendoReverse3" ,testAppendoReverse3),
        ("testAppendoForward", testAppendoForward),
        ("testMemberoReverse", testMemberoReverse),
        ("testMemberoForward", testMemberoForward),
        ("testLengtho", testLengtho),
        ("testRelation", testRelation)
    ]
}
