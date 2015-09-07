// FingerTreeTest.swift
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

class FingerTreeTest: XCTestCase {

    /*
     * Not a real test
     */
    func performance() {
        self.measureBlock {
            let start1 = NSDate()
            let bigTree = (0..<1000000).reduce(FingerTree()) {
            return $0.append(Value($1))
            }
            print(-start1.timeIntervalSinceNow)

            let start2 = NSDate()
            var anotherTree: FingerTree<Value<Int>, Size> = FingerTree()
            for i in 0..<1000000 {
            anotherTree = anotherTree.preface(Value(i))
            }
            print(-start2.timeIntervalSinceNow)


            let starti = NSDate()
            var yetAnother = ImmutableCollection(FingerTree<Value<Int>, Size>())
            for i in 0..<10000 {
            yetAnother = yetAnother.insert(i, atIndex: yetAnother.count / 2)
            }
            print(-starti.timeIntervalSinceNow)


            let starts = NSDate()
            for _ in bigTree.generate() {
            }
            print(-starts.timeIntervalSinceNow)

            let starts2 = NSDate()
            for _ in bigTree.reverse() {
            }
            print(-starts2.timeIntervalSinceNow)

            let start3 = NSDate()
            let rando: ImmutableCollection<Int> = ImmutableCollection(bigTree)

            for i in 0..<100000 {
            rando[i]
            }
            let d: Double = -start3.timeIntervalSinceNow
            print(d)

            let start4 = NSDate()
            for _ in rando.generate() {

            }
            print(-start4.timeIntervalSinceNow)

            let start5 = NSDate()
            for _ in rando.reverse() {

            }
            print(-start5.timeIntervalSinceNow)
        }
    }
}
