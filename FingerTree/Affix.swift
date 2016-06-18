// Affix.swift
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

enum AffixError: ErrorProtocol {
  case tooLarge
}

enum Affix<TValue: Measurable, TAnnotation: Monoid where TAnnotation == TValue.Annotation>
  : Measurable, Sequence {
  
  typealias Element = TreeElement<TValue, TAnnotation>

  case one(Element)
  case two(Element, Element)
  case three(Element, Element, Element)
  case four(Element, Element, Element, Element)

  var viewFirst: (Element, Affix<TValue, TAnnotation>?) {
    switch self {
    case let .one(a):
      return (a, nil)
    case let .two(a, b):
      return (a, Affix.one(b))
    case let .three(a, b, c):
      return (a, Affix.two(b, c))
    case let .four(a, b, c, d):
      return (a, Affix.three(b, c, d))
    }
  }

  var viewLast: (Affix<TValue, TAnnotation>?, Element) {
    switch self {
    case let .one(a):
      return (nil, a)
    case let .two(a, b):
      return (Affix.one(a), b)
    case let .three(a, b, c):
      return (Affix.two(a, b), c)
    case let .four(a, b, c, d):
      return (Affix.three(a, b, c), d)
    }
  }

  var measure: TAnnotation {
    switch self {
    case let .one(a):
      return a.measure
    case let .two(a, b):
      return a.measure <> b.measure
    case let .three(a, b, c):
      return a.measure <> b.measure <> c.measure
    case let .four(a, b, c, d):
      return a.measure <> b.measure <> c.measure <> d.measure
    }
  }

  func preface(_ element: Element) throws -> Affix<TValue, TAnnotation> {
    switch self {
    case let .one(a):
      return Affix.two(element, a)
    case let .two(a, b):
      return Affix.three(element, a, b)
    case let .three(a, b, c):
      return Affix.four(element, a, b, c)
    case .four:
      throw AffixError.tooLarge
    }
  }

  func append(_ element: Element) throws -> Affix<TValue, TAnnotation> {
    switch self {
    case let .one(a):
      return Affix.two(a, element)
    case let .two(a, b):
      return Affix.three(a, b, element)
    case let .three(a, b, c):
      return Affix.four(a, b, c, element)
    case .four:
      throw AffixError.tooLarge
    }
  }

  func makeArray() -> [Element] {
    switch self {
    case let .one(a):
      return [a]
    case let .two(a, b):
      return [a, b]
    case let .three(a, b, c):
      return [a, b, c]
    case let .four(a, b, c, d):
      return [a, b, c, d]
    }
  }

  func makeIterator() -> IndexingIterator<[Element]> {
    return makeArray().makeIterator()
  }
}
