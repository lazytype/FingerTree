// Measure.swift
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


protocol Monoid {
    static func empty() -> Self
    static func monoidPlus(left: Self, _ right: Self) -> Self
}

extension Monoid {
    static func monoidSum(values: Self...) -> Self {
        return monoidSum(values)
    }

    static func monoidSum(values: [Self]) -> Self {
        var sum = Self.empty()
        for value in values {
            sum = monoidPlus(sum, value)
        }
        return sum
    }
}

protocol Measured {
    typealias V: Monoid
    var measure: V {get}
}

final class Value<T: Equatable>: Measured, Equatable, CustomStringConvertible {
    typealias V = Size

    let value: T

    init(_ value: T) {
        self.value = value
    }

    var measure: Size {
        return Size(1)
    }

    var description: String {
        return "'\(self.value)'"
    }
}

func ==<T: Equatable>(lhs: Value<T>, rhs: Value<T>) -> Bool {
    return lhs.value == rhs.value
}


final class Size: Monoid, CustomStringConvertible {
    let value: Int

    private init(_ value: Int) {
        self.value = value
    }

    class func monoidPlus(left: Size, _ right: Size) -> Size {
        return Size(left.value + right.value)
    }

    class func empty() -> Size {
        return Size(0)
    }

    var description : String {
        return "\(self.value)"
    }
}

