// NodeTest.swift
//
// Copyright (c) 2015 Michael Mitchell
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import XCTest

class NodeTest: XCTestCase {
    func testBranch2ToArray() {
        let node: Node<Value<Character>, Size> = Node.Branch2(
            annotation: Size.empty(),
            Value("x"),
            Value("y")
        )

        XCTAssertEqual(node.toArray, ["x", "y"].map(Value.init))
    }

    func testBranch3ToArray() {
        let node = Node.Branch3(
            annotation: Size.empty(),
            Value("a"),
            Value("b"),
            Value("c")
        )

        XCTAssertEqual(node.toArray, ["a", "b", "c"].map(Value.init))
    }

    func testBranch2FromArray() {
        let array = ["x", "y"]
        XCTAssertEqual(try! fromArrayHelper(array), array)
    }

    func testBranch3FromArray() {
        let array = ["a", "b", "c"]
        XCTAssertEqual(try! fromArrayHelper(array), array)
    }

    func testFromArrayTooSmall() {
        let array = ["a"]
        do {
            try fromArrayHelper(array)
        } catch NodeError.ArrayTooSmall {
            return
        } catch {}

        XCTFail("fromArray() should throw ArrayTooSmall")
    }

    func testFromArrayTooLarge() {
        let array = ["a", "b", "c", "d"]
        do {
            try fromArrayHelper(array)
        } catch NodeError.ArrayTooLarge {
            return
        } catch {}

        XCTFail("fromArray() should throw ArrayTooLarge")
    }

    func fromArrayHelper<T: Equatable>(array: [T]) throws -> [T] {
        let node = try Node.fromArray(array.map(Value.init))
        return node.toArray.map {$0.value}
    }
}