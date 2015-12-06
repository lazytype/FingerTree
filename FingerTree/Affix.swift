// Affix.swift
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

enum AffixError: ErrorType {
    case TooLarge
}

enum Affix<
    TValue: Measurable, TAnnotation: Monoid
    where TAnnotation == TValue.Annotation>: Measurable, SequenceType {
    
    typealias Element = TreeElement<TValue, TAnnotation>

    case One(Element)
    case Two(Element, Element)
    case Three(Element, Element, Element)
    case Four(Element, Element, Element, Element)

    func preface(element: Element) throws -> Affix<TValue, TAnnotation> {
        switch self {
        case let .One(a):
            return Affix.Two(element, a)
        case let .Two(a, b):
            return Affix.Three(element, a, b)
        case let .Three(a, b, c):
            return Affix.Four(element, a, b, c)
        case .Four:
            throw AffixError.TooLarge
        }
    }

    func append(element: Element) throws -> Affix<TValue, TAnnotation> {
        switch self {
        case let .One(a):
            return Affix.Two(a, element)
        case let .Two(a, b):
            return Affix.Three(a, b, element)
        case let .Three(a, b, c):
            return Affix.Four(a, b, c, element)
        case .Four:
            throw AffixError.TooLarge
        }
    }

    var viewFirst: (Element, Affix<TValue, TAnnotation>?) {
        switch self {
        case let .One(a):
            return (a, nil)
        case let .Two(a, b):
            return (a, Affix.One(b))
        case let .Three(a, b, c):
            return (a, Affix.Two(b, c))
        case let .Four(a, b, c, d):
            return (a, Affix.Three(b, c, d))
        }
    }

    var viewLast: (Affix<TValue, TAnnotation>?, Element) {
        switch self {
        case let .One(a):
            return (nil, a)
        case let .Two(a, b):
            return (Affix.One(a), b)
        case let .Three(a, b, c):
            return (Affix.Two(a, b), c)
        case let .Four(a, b, c, d):
            return (Affix.Three(a, b, c), d)
        }
    }

    var toArray: [Element] {
        switch self {
        case let .One(a):
            return [a]
        case let .Two(a, b):
            return [a, b]
        case let .Three(a, b, c):
            return [a, b, c]
        case let .Four(a, b, c, d):
            return [a, b, c, d]
        }
    }

    var measure: TAnnotation {
        switch self {
        case let .One(a):
            return a.measure
        case let .Two(a, b):
            return a.measure <> b.measure
        case let .Three(a, b, c):
            return a.measure <> b.measure <> c.measure
        case let .Four(a, b, c, d):
            return a.measure <> b.measure <> c.measure <> d.measure
        }
    }

    func generate() -> IndexingGenerator<[Element]> {
        return toArray.generate()
    }
}
