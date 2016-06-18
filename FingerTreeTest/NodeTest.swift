// NodeTest.swift
//
// Copyright (c) 2015-Present, Michael Mitchell
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software
// and associated documentation files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import XCTest

class NodeTwoTest: XCTestCase {
  var node: Node<Value<Character>, Size> {
    return Node.branch2(Value("a").makeElement(), Value("b").makeElement(), Size(2))
  }

  var array: [Character] {
    return ["a", "b"]
  }

  func testToArray() {
    XCTAssertEqual(node.makeArray().map {$0.value!.value}, array)
  }

  func testMeasure() {
    XCTAssertEqual(node.measure, 2)
  }

  func testGenerate() {
    XCTAssertEqual(node.makeIterator().map {$0.value!.value}, array)
  }
}

class NodeThreeTest: XCTestCase {
  var node: Node<Value<Character>, Size> {
    return Node.branch3(Value("a").makeElement(), Value("b").makeElement(), Value("c").makeElement(), Size(3))
  }

  var array: [Character] {
    return ["a", "b", "c"]
  }

  func testToArray() {
    XCTAssertEqual(node.makeArray().map {$0.value!.value}, array)
  }

  func testMeasure() {
    XCTAssertEqual(node.measure, 3)
  }

  func testGenerate() {
    XCTAssertEqual(node.makeIterator().map {$0.value!.value}, array)
  }
}
