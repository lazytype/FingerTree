// FingerTree.swift
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

enum FingerTree<TValue: Measurable, TAnnotation: Monoid where TAnnotation == TValue.Annotation>
  : Measurable {

  typealias Element = TreeElement<TValue, TAnnotation>

  case empty
  case single(Element)
  indirect case deep(
    prefix: Affix<TValue, TAnnotation>,
    deeper: FingerTree,
    suffix: Affix<TValue, TAnnotation>,
    TAnnotation
  )

  var measure: TAnnotation {
    switch self {
    case .empty:
      return TAnnotation.identity
    case let .single(a):
      return a.measure
    case let .deep(_, _, _, annotation):
      return annotation
    }
  }

  func preface(_ element: Element) -> FingerTree {
    switch self {
    case .empty:
      return FingerTree.single(element)
    case let .single(a):
      return FingerTree.deep(
        prefix: Affix.one(element),
        deeper: FingerTree.empty,
        suffix: Affix.one(a),
        element.measure <> a.measure
      )
    case let .deep(.four(a, b, c, d), deeper, suffix, annotation):
      return FingerTree.deep(
        prefix: Affix.two(element, a),
        deeper: deeper.preface(
          Node.branch3(b, c, d, b.measure <> c.measure <> d.measure).makeElement()
        ),
        suffix: suffix,
        element.measure <> annotation
      )
    case let .deep(prefix, deeper, suffix, annotation):
      return FingerTree.deep(
        prefix: try! prefix.preface(element),
        deeper: deeper,
        suffix: suffix,
        element.measure <> annotation
      )
    }
  }

  func append(_ element: Element) -> FingerTree {
    switch self {
    case .empty:
      return FingerTree.single(element)
    case let .single(a):
      return FingerTree.deep(
        prefix: Affix.one(a),
        deeper: FingerTree.empty,
        suffix: Affix.one(element),
        a.measure <> element.measure
      )
    case let .deep(prefix, deeper, .four(a, b, c, d), annotation):
      return FingerTree.deep(
        prefix: prefix,
        deeper: deeper.append(
          Node.branch3(a, b, c, a.measure <> b.measure <> c.measure).makeElement()
        ),
        suffix: Affix.two(d, element),
        annotation <> element.measure
      )
    case let .deep(prefix, deeper, suffix, annotation):
      return FingerTree.deep(
        prefix: prefix,
        deeper: deeper,
        suffix: try! suffix.append(element),
        annotation <> element.measure
      )
    }
  }

  private static func nodes(_ array: [Element]) -> [Element]? {
    switch array.count {
    case 1:
      return nil
    case 2:
      let annotation = array[0].measure <> array[1].measure
      return [Node.branch2(array[0], array[1], annotation).makeElement()]
    case 3:
      let annotation = array[0].measure <> array[1].measure <> array[2].measure
      return [Node.branch3(array[0], array[1], array[2], annotation).makeElement()]
    default:
      var nodeArray = nodes(Array(array[0..<(array.count - 2)]))
      let annotation = array[array.count - 2].measure <> array[array.count - 1].measure
      nodeArray!.append(
        Node.branch2(array[array.count - 2], array[array.count - 1], annotation).makeElement()
      )
      return nodeArray
    }
  }

  static func concatenate(middle: [Element], left: FingerTree, right: FingerTree) -> FingerTree {
    switch (middle, left, right) {
    case (_, .empty, _) where middle.isEmpty:
      return right

    case (_, _, .empty) where middle.isEmpty:
      return left

    case (_, .empty, _):
      let middle = Array(middle[1..<middle.count])
      let first = middle.first!
      return concatenate(middle: middle, left: FingerTree.empty, right: right).preface(first)

    case (_, _, .empty):
      let middle = Array(middle[0..<(middle.count - 1)])
      let last = middle.last!
      return concatenate(middle: middle, left: left, right: FingerTree.empty).append(last)

    case let (_, .single(a), _):
      return concatenate(middle: middle, left: FingerTree.empty, right: right).preface(a)

    case let (_, _, .single(a)):
      return concatenate(middle: middle, left: left, right: FingerTree.empty).append(a)

    case let (
      _,
      .deep(leftPrefix, leftDeeper, leftSuffix, _),
      .deep(rightPrefix, rightDeeper, rightSuffix, _)
    ):
      let middle = nodes(leftSuffix.makeArray() + middle + rightPrefix.makeArray())!
      let deeper = FingerTree.concatenate(middle: middle, left: leftDeeper, right: rightDeeper)
      let annotation = leftPrefix.measure <> deeper.measure <> rightSuffix.measure
      return FingerTree.deep(prefix: leftPrefix, deeper: deeper, suffix: rightSuffix, annotation)

    default:
      // All cases have actually been exhausted. Remove when the compiler is smarter about this.
      return FingerTree.empty
    }
  }

  func extend(_ tree: FingerTree) -> FingerTree {
    return FingerTree.concatenate(middle: [], left: self, right: tree)
  }

  func makeIterator() -> AnyIterator<Element> {
    switch self {
    case .empty:
      return AnyIterator(EmptyIterator())
    case let .single(a):
      return AnyIterator(IteratorOverOne(_elements: a))
    case let .deep(prefix, deeper, suffix, _):
      var (prefixIter, deeperIter, suffixIter) = (
        prefix.makeIterator(),
        deeper.makeIterator(),
        suffix.makeIterator()
      )

      var nodeIter = deeperIter.next()?.node!.makeIterator()

      return AnyIterator {
        if let value = prefixIter.next() {
          return value
        }

        repeat {
          if let value = nodeIter?.next() {
            return value
          }

          nodeIter = deeperIter.next()?.node!.makeIterator()
        } while nodeIter != nil

        if let value = suffixIter.next() {
          return value
        }

        return nil
      }
    }
  }

  func reversed() -> AnyIterator<Element> {
    switch self {
    case .empty:
      return AnyIterator(EmptyIterator())
    case let .single(a):
      return AnyIterator(IteratorOverOne(_elements: a))
    case let .deep(prefix, deeper, suffix, _):
      var (prefixIter, deeperIter, suffixIter) = (
        prefix.reversed().makeIterator(),
        deeper.reversed(),
        suffix.reversed().makeIterator()
      )

      var nodeIter = deeperIter.next()?.node!.makeIterator()

      return AnyIterator {
        if let value = suffixIter.next() {
          return value
        }

        repeat {
          if let value = nodeIter?.next() {
            return value
          }

          nodeIter = deeperIter.next()?.node!.makeIterator()
        } while nodeIter != nil

        return prefixIter.next()
      }
    }
  }
}
