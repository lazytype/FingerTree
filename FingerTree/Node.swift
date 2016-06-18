// Node.swift
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

enum TreeElement<TValue: Measurable, TAnnotation where TAnnotation == TValue.Annotation>
  : Measurable {

  case aValue(TValue)
  case aNode(Node<TValue, TAnnotation>)

  var node: Node<TValue, TAnnotation>? {
    if case let .aNode(node) = self {
      return node
    }

    return nil
  }

  var value: TValue? {
    if case let .aValue(value) = self {
      return value
    }

    return nil
  }

  var measure: TAnnotation {
    switch self {
    case let .aNode(node):
      return node.measure
    case let .aValue(value):
      return value.measure
    }
  }
}

enum Node<TValue: Measurable, TAnnotation: Monoid where TAnnotation == TValue.Annotation>
  : Measurable, Sequence {

  typealias Element = TreeElement<TValue, TAnnotation>

  indirect case branch2(Element, Element, TAnnotation)
  indirect case branch3(Element, Element, Element, TAnnotation)

  var measure: TAnnotation {
    switch self {
    case let .branch2(_, _, annotation):
      return annotation
    case let .branch3(_, _, _, annotation):
      return annotation
    }
  }

  func makeArray() -> [Element] {
    switch self {
    case let .branch2(a, b, _):
      return [a, b]
    case let .branch3(a, b, c, _):
      return [a, b, c]
    }
  }

  func makeElement() -> Element {
    return Element.aNode(self)
  }

  func makeIterator() -> IndexingIterator<[Element]> {
    return makeArray().makeIterator()
  }
}
