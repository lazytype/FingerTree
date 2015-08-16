// ConsList.swift
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


enum ConsList<Element: Measured, V: Monoid where V == Element.V>
    : CustomStringConvertible {

    case Empty
    indirect case Cons(first: Element, rest: ConsList<Element, V>)

    var isEmpty: Bool {
        switch self {
        case .Empty:
            return true
        case .Cons:
            return false
        }
    }

    static func fromElements(elements: Element...) -> ConsList<Element, V> {
        return fromElements(elements)
    }

    static func fromElements(elements: [Element]) -> ConsList<Element, V> {
        var list : ConsList = .Empty
        for element in elements.reverse() {
            list = .Cons(first: element, rest: list)
        }
        return list
    }

    static func fromAffix(affix: Affix<Element, V>) -> ConsList<Element, V> {
        switch affix {
        case .One(let a):
            return fromElements(a)
        case .Two(let a, let b):
            return fromElements(a, b)
        case .Three(let a, let b, let c):
            return fromElements(a, b, c)
        case .Four(let a, let b, let c, let d):
            return fromElements(a, b, c, d)
        }
    }

    var toArray : [Element] {
        switch self {
        case .Empty:
            return []
        default:
            return (toAffix?.toArray)!
        }
    }

    var toAffix : Affix<Element, V>? {
        switch self {
        case .Cons(let a, .Cons(let b, .Cons(let c, .Cons(let d, .Empty)))):
            return .Four(a, b, c, d)
        case .Cons(let a, .Cons(let b, .Cons(let c, .Empty))):
            return .Three(a, b, c)
        case .Cons(let a, .Cons(let b, .Empty)):
            return .Two(a, b)
        case .Cons(let a, .Empty):
            return .One(a)
        default:
            return nil
        }
    }

    var description : String {
        return "\(self.toArray)"
    }
}