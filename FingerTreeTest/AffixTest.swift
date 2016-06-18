// AffixTest.swift
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


class AffixOneTest: XCTestCase {
  var affix: Affix<Value<Character>, Size> {
    return Affix.one(Value("a").makeElement())
  }

  var array: [Character] {
    return ["a"]
  }

  func testToArray() {
    XCTAssertEqual(affix.makeArray().map {$0.value!.value}, array)
  }

  func testPreface() {
    var array = self.array;
    array.insert("x", at: 0)

    XCTAssertEqual(try! affix.preface(Value("x").makeElement()).makeArray().map {$0.value!.value}, array)
  }

  func testAppend() {
    var array = self.array
    array.append("x")

    XCTAssertEqual(try! affix.append(Value("x").makeElement()).makeArray().map {$0.value!.value}, array)
  }

  func testMeasure() {
    XCTAssertEqual(affix.measure, array.count)
  }

  func testGenerate() {
    XCTAssertEqual(affix.makeIterator().map {$0.value!.value}, array)
  }
}

class AffixTwoTest: AffixOneTest {
  override var affix: Affix<Value<Character>, Size> {
    return Affix.two(Value("a").makeElement(), Value("b").makeElement())
  }

  override var array: [Character] {
    return ["a", "b"]
  }

  override func testToArray() {
    XCTAssertEqual(affix.makeArray().map {$0.value!.value}, self.array)
  }
}

class AffixThreeTest: AffixOneTest {
  override var affix: Affix<Value<Character>, Size> {
    return Affix.three(Value("a").makeElement(), Value("b").makeElement(), Value("c").makeElement())
  }

  override var array: [Character] {
    return ["a", "b", "c"]
  }
}

class AffixFourTest: AffixOneTest {
  override var affix: Affix<Value<Character>, Size> {
    return Affix.four(
      Value("a").makeElement(),
      Value("b").makeElement(),
      Value("c").makeElement(),
      Value("d").makeElement()
    )
  }

  override var array: [Character] {
    return ["a", "b", "c", "d"]
  }

  override func testPreface() {
    do {
      _ = try affix.preface(Value("x").makeElement())
    } catch AffixError.tooLarge {
      return
    } catch {}

    XCTFail("preface() should throw AffixError.TooLarge")
  }

  override func testAppend() {
    do {
      _ = try affix.append(Value("x").makeElement())
    } catch AffixError.tooLarge {
      return
    } catch {}

    XCTFail("append() should throw AffixError.TooLarge")
  }
}

class AffixTest: XCTestCase {
  func testViewFirst() {
    let array = ["a", "b", "c", "d"]
    var affix: Affix? = Affix.four(
      Value("a").makeElement(),
      Value("b").makeElement(),
      Value("c").makeElement(),
      Value("d").makeElement()
    )
    for value in array {
      let (first, rest) = affix!.viewFirst

      affix = rest
      XCTAssert(value == first.value!.value)
    }

    XCTAssert(affix == nil)
  }

  func testViewLast() {
    let array = ["a", "b", "c", "d"]
    var affix: Affix? = Affix.four(
      Value("a").makeElement(),
      Value("b").makeElement(),
      Value("c").makeElement(),
      Value("d").makeElement()
    )
    for value in array.reversed() {
      let (rest, last) = affix!.viewLast
      
      affix = rest
      XCTAssert(value == last.value!.value)
    }

    XCTAssert(affix == nil)
  }
}
