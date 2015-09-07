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

enum Affix<TMeasurable: Measurable, V: Monoid where V == TMeasurable.V>
    : Measurable, SequenceType {
    typealias Element = TreeElement<TMeasurable, V>

    case One(Element)
    case Two(Element, Element, V)
    case Three(Element, Element, Element, V)
    case Four(Element, Element, Element, Element, V)

    func preface(element: Element) throws -> Affix<TMeasurable, V> {
        switch self {
        case let .One(a):
            return Affix.Two(element, a, element.measure <> a.measure)
        case let .Two(a, b, annotation):
            return Affix.Three(element, a, b, element.measure <> annotation)
        case let .Three(a, b, c, annotation):
            return Affix.Four(element, a, b, c, element.measure <> annotation)
        case .Four:
            throw AffixError.TooLarge
        }
    }

    func append(element: Element) throws -> Affix<TMeasurable, V> {
        switch self {
        case let .One(a):
            return Affix.Two(a, element, a.measure <> element.measure)
        case let .Two(a, b, annotation):
            return Affix.Three(a, b, element, annotation <> element.measure)
        case let .Three(a, b, c, annotation):
            return Affix.Four(a, b, c, element, annotation <> element.measure)
        case .Four:
            throw AffixError.TooLarge
        }
    }

    var viewFirst: (Element, Affix<TMeasurable, V>?) {
        switch self {
        case let .One(a):
            return (a, nil)
        case let .Two(a, b, _):
            return (a, Affix.One(b))
        case let .Three(a, b, c, _):
            return (a, Affix.Two(b, c, b.measure <> c.measure))
        case let .Four(a, b, c, d, _):
            return (a, Affix.Three(b, c, d, b.measure <> c.measure <> d.measure))
        }
    }

    var viewLast: (Affix<TMeasurable, V>?, Element) {
        switch self {
        case let .One(a):
            return (nil, a)
        case let .Two(a, b, _):
            return (Affix.One(a), b)
        case let .Three(a, b, c, _):
            return (Affix.Two(a, b, a.measure <> b.measure), c)
        case let .Four(a, b, c, d, _):
            return (Affix.Three(a, b, c, a.measure <> b.measure <> c.measure), d)
        }
    }

    var toArray: [Element] {
        switch self {
        case let .One(a):
            return [a]
        case let .Two(a, b, _):
            return [a, b]
        case let .Three(a, b, c, _):
            return [a, b, c]
        case let .Four(a, b, c, d, _):
            return [a, b, c, d]
        }
    }

    var measure: V {
        switch self {
        case let .One(a):
            return a.measure
        case let .Two(_, _, annotation):
            return annotation
        case let .Three(_, _, _, annotation):
            return annotation
        case let .Four(_, _, _, _, annotation):
            return annotation
        }
    }

    func generate() -> IndexingGenerator<[Element]> {
        return self.toArray.generate()
    }
}
