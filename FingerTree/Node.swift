// Node.swift
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

enum Node<Element: Measurable, V: Monoid where V == Element.V>
    : CachedMeasurable, CustomStringConvertible {
    indirect case Branch2(Element, Element, CachedValue<V>)
    indirect case Branch3(Element, Element, Element, CachedValue<V>)

    init(_ a: Element, _ b: Element) {
        self = Node.Branch2(a, b, CachedValue())
    }

    init(_ a: Element, _ b: Element, _ c: Element) {
        self = Node.Branch3(a, b, c, CachedValue())
    }

    private var toArray: [Element] {
        switch self {
        case let .Branch2(a, b, _):
            return [a, b]
        case let .Branch3(a, b, c, _):
            return [a, b, c]
        }
    }

    internal var computeMeasure: V {
        switch self {
        case let .Branch2(a, b, _):
            return a.measure <> b.measure
        case let .Branch3(a, b, c, _):
            return a.measure <> b.measure <> c.measure
        }
    }

    var cachedMeasure: CachedValue<V> {
        switch self {
        case let .Branch2(_, _, annotation):
            return annotation
        case let .Branch3(_, _, _, annotation):
            return annotation
        }
    }

    var description: String {
        return "[\(self.measure)] \(self.toArray)"
    }
}
