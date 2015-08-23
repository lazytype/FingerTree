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

enum Affix<Element: Measurable, V: Monoid where V == Element.V>
    : CachedMeasurable {
    indirect case One(Element, CachedValue<V>)
    indirect case Two(Element, Element, CachedValue<V>)
    indirect case Three(Element, Element, Element, CachedValue<V>)
    indirect case Four(Element, Element, Element, Element, CachedValue<V>)

    init(_ a: Element) {
        self = Affix.One(a, CachedValue())
    }

    init(_ a: Element, _ b: Element) {
        self = Affix.Two(a, b, CachedValue())
    }

    init(_ a: Element, _ b: Element, _ c: Element) {
        self = Affix.Three(a, b, c, CachedValue())
    }

    init(_ a: Element, _ b: Element, _ c: Element, _ d: Element) {
        self = Affix.Four(a, b, c, d, CachedValue())
    }

    func preface(element: Element) throws -> Affix<Element, V> {
        switch self {
        case let .One(a, _):
            return Affix(element, a)
        case let .Two(a, b, _):
            return Affix(element, a, b)
        case let .Three(a, b, c, _):
            return Affix(element, a, b, c)
        case .Four:
            throw AffixError.TooLarge
        }
    }

    func append(element: Element) throws -> Affix<Element, V> {
        switch self {
        case let .One(a, _):
            return Affix(a, element)
        case let .Two(a, b, _):
            return Affix(a, b, element)
        case let .Three(a, b, c, _):
            return Affix(a, b, c, element)
        case .Four:
            throw AffixError.TooLarge
        }
    }

    var viewFirst: (Element, Affix<Element, V>?) {
        switch self {
        case let .One(a, _):
            return (a, nil)
        case let .Two(a, b, _):
            return (a, Affix(b))
        case let .Three(a, b, c, _):
            return (a, Affix(b, c))
        case let .Four(a, b, c, d, _):
            return (a, Affix(b, c, d))
        }
    }

    var viewLast: (Affix<Element, V>?, Element) {
        switch self {
        case let .One(a, _):
            return (nil, a)
        case let .Two(a, b, _):
            return (Affix(a), b)
        case let .Three(a, b, c, _):
            return (Affix(a, b), c)
        case let .Four(a, b, c, d, _):
            return (Affix(a, b, c), d)
        }
    }

    var toArray: [Element] {
        switch self {
        case let .One(a, _):
            return [a]
        case let .Two(a, b, _):
            return [a, b]
        case let .Three(a, b, c, _):
            return [a, b, c]
        case let .Four(a, b, c, d, _):
            return [a, b, c, d]
        }
    }

    internal var computeMeasure: V {
        switch self {
        case let .One(a, _):
            return a.measure
        case let .Two(a, b, _):
            return a.measure <> b.measure
        case let .Three(a, b, c, _):
            return a.measure <> b.measure <> c.measure
        case let .Four(a, b, c, d, _):
            return a.measure <> b.measure <> c.measure <> d.measure
        }
    }

    var cachedMeasure: CachedValue<V> {
        switch self {
        case let .One(_, annotation):
            return annotation
        case let .Two(_, _, annotation):
            return annotation
        case let .Three(_, _, _, annotation):
            return annotation
        case let .Four(_, _, _, _, annotation):
            return annotation
        }
    }
}
