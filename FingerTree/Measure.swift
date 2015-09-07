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
    static var identity: Self {get}
    func append(other: Self) -> Self
}

infix operator <> { associativity left precedence 140 }
internal func <><V: Monoid>(lhs: V, rhs: V) -> V {
    return lhs.append(rhs)
}

internal protocol Measurable {
    typealias V: Monoid
    var measure: V {get}
}

struct Value<T>: Measurable, CustomStringConvertible {
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

extension Measurable {
    var toElement: TreeElement<Self, V> {
        return TreeElement.AValue(self)
    }
}

struct Size: Monoid, CustomStringConvertible {
    let value: Int

    private static let zero: Size = Size(0)

    internal init(_ value: Int) {
        self.value = value
    }

    func append(other: Size) -> Size {
        return Size(self.value + other.value)
    }

    static var identity: Size {
        return Size.zero
    }

    var description: String {
        return "\(self.value)"
    }
}

struct Prioritized<T>: Measurable {
    typealias V = Priority

    let value: T
    let priority: Int

    init(_ value: T, priority: Int) {
        self.value = value
        self.priority = priority
    }

    var measure: Priority {
        return Priority.Value(self.priority)
    }
}

enum Priority: Monoid {
    case NegativeInfinity
    case Value(Int)

    func append(other: Priority) -> Priority {
        switch (self, other) {
        case (.NegativeInfinity, _):
            return other
        case (_, .NegativeInfinity):
            return self
        case let (.Value(value), .Value(otherValue)):
            return value > otherValue ? self : other
        default:
            // All cases have actually been exhausted.
            // Remove when the compiler is smarter about this.
            return self
        }
    }

    static var identity: Priority {
        return Priority.NegativeInfinity
    }
}

func ==(lhs: Priority, rhs: Priority) -> Bool {
    switch (lhs, rhs) {
    case (.NegativeInfinity, .NegativeInfinity):
        return true
    case let (.Value(lvalue), .Value(rvalue)):
        return lvalue == rvalue
    default:
        return false
    }
}