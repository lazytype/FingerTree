// AffixTest.swift
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

class AffixOneTest: XCTestCase {
    var affix: Affix<Value<Character>, Size> {
        return Affix(Value("a"))
    }

    var array: [Character] {
        return ["a"]
    }

    func testToArray() {
        XCTAssertEqual(affix.toArray.map {$0.value}, array)
    }

    func testPreface() {
        var array = affix.toArray
        array.insert(Value("x"), atIndex: 0)

        XCTAssertEqual(
            try! affix.preface(Value("x")).toArray.map {$0.value},
            array.map {$0.value}
        )
    }

    func testAppend() {
        var array = affix.toArray
        array.append(Value("x"))

        XCTAssertEqual(
            try! affix.append(Value("x")).toArray.map {$0.value},
            array.map {$0.value}
        )
    }
}

class AffixTwoTest: AffixOneTest {
    override var affix: Affix<Value<Character>, Size> {
        return Affix(
            Value("a"),
            Value("b")
        )
    }

    override var array: [Character] {
        return ["a", "b"]
    }

    override func testToArray() {
        XCTAssertEqual(affix.toArray.map {$0.value}, ["a", "b"])
    }
}

class AffixThreeTest: AffixOneTest {
    override var affix: Affix<Value<Character>, Size> {
        return Affix(Value("a"), Value("b"), Value("c"))
    }

    override var array: [Character] {
        return ["a", "b", "c"]
    }
}

class AffixFourTest: AffixOneTest {
    override var affix: Affix<Value<Character>, Size> {
        return Affix(Value("a"), Value("b"), Value("c"),Value("d"))
    }

    override var array: [Character] {
        return ["a", "b", "c", "d"]
    }

    override func testPreface() {
        do {
            try affix.preface(Value("x"))
        } catch AffixError.TooLarge {
            return
        } catch {}

        XCTFail("preface() should throw AffixError.TooLarge")
    }

    override func testAppend() {
        do {
            try affix.append(Value("x"))
        } catch AffixError.TooLarge {
            return
        } catch {}

        XCTFail("append() should throw AffixError.TooLarge")
    }
}

class AffixTest: XCTestCase {
    func testViewFirst() {
        let array = ["a", "b", "c", "d"]
        var affix: Affix? = Affix(
            Value("a"),
            Value("b"),
            Value("c"),
            Value("d")
        )
        for value in array {
            let (first, rest) = affix!.viewFirst

            affix = rest
            XCTAssert(value == first.value)
        }

        XCTAssert(affix == nil)
    }

    func testViewLast() {
        let array = ["a", "b", "c", "d"]
        var affix: Affix? = Affix(
            Value("a"),
            Value("b"),
            Value("c"),
            Value("d")
        )
        for value in array.reverse() {
            let (rest, last) = affix!.viewLast
            
            affix = rest
            XCTAssert(value == last.value)
        }
        
        XCTAssert(affix == nil)
    }
}
