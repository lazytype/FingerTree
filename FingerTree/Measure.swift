// Measure.swift
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

protocol Monoid {
  static var identity: Self {get}
  func append(_ other: Self) -> Self
}

infix operator <> { associativity left precedence 140 }
internal func <> <TAnnotation: Monoid>(lhs: TAnnotation, rhs: TAnnotation) -> TAnnotation {
  return lhs.append(rhs)
}

internal protocol Measurable {
  associatedtype Annotation: Monoid
  var measure: Annotation {get}
}

struct Value<T>: Measurable, CustomStringConvertible {
  typealias Annotation = Size

  let value: T

  init(_ value: T) {
    self.value = value
  }

  var measure: Size {
    return 1
  }

  var description: String {
    return "'\(value)'"
  }
}

extension Measurable {
  func makeElement() -> TreeElement<Self, Annotation> {
    return TreeElement.aValue(self)
  }
}

typealias Size = Int

extension Size: Monoid {
  static var identity: Size = 0

  func append(_ other: Size) -> Size {
    return self + other
  }
}

struct Prioritized<T>: Measurable {
  typealias Annotation = Priority

  let value: T
  let priority: Int

  init(_ value: T, priority: Int) {
    self.value = value
    self.priority = priority
  }

  var measure: Priority {
    return Priority.value(priority)
  }
}

enum Priority: Monoid {
  case negativeInfinity
  case value(Int)

  static var identity: Priority {
    return Priority.negativeInfinity
  }

  func append(_ other: Priority) -> Priority {
    switch (self, other) {
    case (.negativeInfinity, _):
      return other
    case (_, .negativeInfinity):
      return self
    case let (.value(value), .value(otherValue)):
      return value > otherValue ? self : other
    default:
      // All cases have actually been exhausted. Remove when the compiler is smarter about this.
      return self
    }
  }
}

func == (lhs: Priority, rhs: Priority) -> Bool {
  switch (lhs, rhs) {
  case (.negativeInfinity, .negativeInfinity):
    return true
  case let (.value(lvalue), .value(rvalue)):
    return lvalue == rvalue
  default:
    return false
  }
}
