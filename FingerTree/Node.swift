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


enum NodeError: ErrorType {
    case ArrayTooSmall
    case ArrayTooLarge
}

enum Node<Element: Measured, V: Monoid where V == Element.V>
: Measured, CustomStringConvertible {
    case Branch2(annotation: V, Element, Element)
    case Branch3(annotation: V, Element, Element, Element)

    var toArray: [Element] {
        switch self {
        case .Branch2(_, let a, let b):
            return [a, b]
        case .Branch3(_, let a, let b, let c):
            return [a, b, c]
        }
    }

    static func fromArray(elements: [Element]) throws -> Node<Element, V> {
        if elements.count == 2 {
            return Node.Branch2(
                annotation: V.monoidSum(elements.map {$0.measure}),
                elements[0],
                elements[1]
            )
        } else if elements.count == 3 {
            return Node.Branch3(
                annotation: V.monoidSum(elements.map {$0.measure}),
                elements[0],
                elements[1],
                elements[2]
            )
        } else if elements.count < 2 {
            throw NodeError.ArrayTooSmall
        } else {
            throw NodeError.ArrayTooLarge
        }
    }

    var measure: V {
        switch self {
        case .Branch2(let annotation, _, _):
            return annotation
        case .Branch3(let annotation, _, _, _):
            return annotation
        }
    }

    var description: String {
        return "\(self.toArray)"
    }
}