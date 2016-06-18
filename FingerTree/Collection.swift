// Collection.swift
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

public struct ImmutableCollection<T>: Collection {
  private let tree: FingerTree<Value<T>, Size>

  init(_ tree: FingerTree<Value<T>, Size> = FingerTree.empty) {
    self.tree = tree
  }

  public let startIndex: Int = 0

  public var endIndex: Int {
    return tree.measure
  }

  public subscript(index: Int) -> T {
    let (_, right) = try! tree.split(
      predicate: {$0 > index && index >= 0},
      startAnnotation: Size.identity
    )

    let (element, _) = right.viewLeft!
    return element.value!.value
  }

  public func index(after i: Int) -> Int {
    precondition(i < endIndex, "Can't advance beyond endIndex")
    return i + 1
  }

  public func makeIterator() -> AnyIterator<T> {
    return AnyIterator(tree.makeIterator().lazy.map {$0.value!.value}.makeIterator())
  }

  public func reversed() -> AnyIterator<T> {
    return AnyIterator(tree.reversed().lazy.map {$0.value!.value}.makeIterator())
  }

  public func preface(_ element: T) -> ImmutableCollection<T> {
    return ImmutableCollection(tree.preface(Value(element).makeElement()))
  }

  public func append(_ element: T) -> ImmutableCollection<T> {
    return ImmutableCollection(tree.append(Value(element).makeElement()))
  }

  func insert(_ element: T, atIndex: Int) -> ImmutableCollection<T>  {
    do {
      let (left, right) = try tree.split(
        predicate: {$0 > atIndex && atIndex >= 0},
        startAnnotation: Size.identity
      )
      let middle = [Value(element).makeElement()]
      let newTree = FingerTree.concatenate(middle: middle, left: left, right: right)

      return ImmutableCollection(newTree)
    } catch {
      return ImmutableCollection(FingerTree.single(Value(element).makeElement()))
    }
  }
}

public struct PriorityQueue<T> {
  let tree: FingerTree<Prioritized<T>, Priority>

  init(_ tree: FingerTree<Prioritized<T>, Priority>) {
    self.tree = tree
  }

  public func pop() -> (T, PriorityQueue<T>) {
    let (left, right) = try! tree.split(
      predicate: {$0 == self.tree.measure},
      startAnnotation: Priority.negativeInfinity
    )

    let (element, rest) = right.viewLeft!

    let newTree = left.extend(rest) // wrong!

    return (element.value!.value, PriorityQueue(newTree))
  }

  public func push(_ element: T, value: Int) -> PriorityQueue<T> {
    let prioritized = Prioritized(element, priority: value)
    let newTree: FingerTree<Prioritized<T>, Priority>

    switch tree {
    case .empty:
      newTree = FingerTree<Prioritized<T>, Priority>.single(prioritized.makeElement())
    case let .single(a):
      newTree = FingerTree.createDeep(
        prefix: Affix<Prioritized<T>, Priority>.one(a),
        deeper: FingerTree<Prioritized<T>, Priority>.empty,
        suffix: Affix<Prioritized<T>, Priority>.one(prioritized.makeElement())
      )
    case let .deep(prefix, deeper, suffix, annotation):
      switch prefix {
      case let .four(a, b, c, d):
        newTree = FingerTree<Prioritized<T>, Priority>.deep(
          prefix: Affix.two(prioritized.makeElement(), a),
          deeper: deeper.preface(
            Node.branch3(b, c, d, b.measure <> c.measure <> d.measure).makeElement()
          ),
          suffix: suffix,
          prioritized.measure <> annotation
        )
      default:
        newTree = FingerTree.deep(
          prefix: try! prefix.preface(prioritized.makeElement()),
          deeper: deeper,
          suffix: suffix,
          prioritized.measure <> annotation
        )
      }
    }

    return PriorityQueue(newTree)
  }
}
