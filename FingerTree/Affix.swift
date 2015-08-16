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
    case ArrayTooSmall
    case ArrayTooLarge
    case AffixTooLarge
}

enum Affix<Element: Measured, V: Monoid where V == Element.V>: Measured {
    case One(Element)
    case Two(Element, Element)
    case Three(Element, Element, Element)
    case Four(Element, Element, Element, Element)

    func preface(element: Element) throws -> Affix<Element, V> {
        switch self {
        case .One(let a):
            return Two(element, a)
        case .Two(let a, let b):
            return Three(element, a, b)
        case .Three(let a, let b, let c):
            return Four(element, a, b, c)
        case .Four:
            throw AffixError.AffixTooLarge
        }
    }

    func append(element: Element) throws -> Affix<Element, V> {
        switch self {
        case .One(let a):
            return Two(a, element)
        case .Two(let a, let b):
            return Three(a, b, element)
        case .Three(let a, let b, let c):
            return Four(a, b, c, element)
        case .Four:
            throw AffixError.AffixTooLarge
        }
    }

    var viewFirst: (Element, Affix<Element, V>?) {
        switch self {
        case .One(let a):
            return (a, nil)
        case .Two(let a, let b):
            return (a, One(b))
        case .Three(let a, let b, let c):
            return (a, Two(b, c))
        case .Four(let a, let b, let c, let d):
            return (a, Three(b, c, d))
        }
    }

    var viewLast: (Affix<Element, V>?, Element) {
        switch self {
        case .One(let a):
            return (nil, a)
        case .Two(let a, let b):
            return (One(a), b)
        case .Three(let a, let b, let c):
            return (Two(a, b), c)
        case .Four(let a, let b, let c, let d):
            return (Three(a, b, c), d)
        }
    }

    var toArray: [Element] {
        switch self {
        case .One(let a):
            return [a]
        case .Two(let a, let b):
            return [a, b]
        case .Three(let a, let b, let c):
            return [a, b, c]
        case .Four(let a, let b, let c, let d):
            return [a, b, c, d]
        }
    }

    static func fromArray(array: [Element]) throws -> Affix<Element, V> {
        switch array.count {
        case 1:
            return .One(array[0])
        case 2:
            return .Two(array[0], array[1])
        case 3:
            return .Three(array[0], array[1], array[2])
        case 4:
            return .Four(array[0], array[1], array[2], array[3])
        default:
            if array.count == 0 {
                throw AffixError.ArrayTooSmall
            } else {
                throw AffixError.ArrayTooLarge
            }
        }
    }

    var measure: V {
        return V.monoidSum(self.toArray.map {$0.measure})
    }
}