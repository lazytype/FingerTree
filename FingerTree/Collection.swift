// Collection.swift
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

public struct ImmutableCollection<T>: CollectionType {
    public typealias Index = Int

    private let tree: FingerTree<Value<T>, Size>

    init(_ tree: FingerTree<Value<T>, Size> = FingerTree.Empty) {
        self.tree = tree
    }

    public let startIndex: Int = 0

    public var endIndex: Int {
        return tree.measure
    }

    public subscript(position: Int) -> T {
        let (_, right) = try! tree.split(
            predicate: {$0 > position && position >= 0},
            startAnnotation: Size.identity
        )

        let (element, _) = right.viewLeft!
        return element.value!.value
    }

    public func generate() -> AnyGenerator<T> {
        return AnyGenerator(
            tree.generate().lazy.map {$0.value!.value}.generate()
        )
    }

    public func reverse() -> AnyGenerator<T> {
        return AnyGenerator(
            tree.reverse().lazy.map {$0.value!.value}.generate()
        )
    }

    public func preface(element: T) -> ImmutableCollection<T> {
        return ImmutableCollection(tree.preface(Value(element).toElement))
    }

    public func append(element: T) -> ImmutableCollection<T> {
        return ImmutableCollection(tree.append(Value(element).toElement))
    }

    func insert(element: T, atIndex: Int) -> ImmutableCollection<T>  {
        do {
            let (left, right) = try tree.split(
                predicate: {$0 > atIndex && atIndex >= 0},
                startAnnotation: Size.identity
            )

            let newTree = FingerTree.concatenate(
                middle: [Value(element).toElement],
                left: left,
                right: right
            )

            return ImmutableCollection(newTree)
        } catch {
            return ImmutableCollection(
                FingerTree.Single(Value(element).toElement)
            )
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
            startAnnotation: Priority.NegativeInfinity
        )

        let (element, rest) = right.viewLeft!

        let newTree = left.extend(rest) // wrong!

        return (element.value!.value, PriorityQueue(newTree))
    }

    public func push(element: T, value: Int) -> PriorityQueue<T> {
        let prioritized = Prioritized(element, priority: value)
        let newTree: FingerTree<Prioritized<T>, Priority>

        switch tree {
        case .Empty:
            newTree = FingerTree<Prioritized<T>, Priority>.Single(
                prioritized.toElement
            )
        case let .Single(a):
            newTree = FingerTree.createDeep(
                prefix: Affix<Prioritized<T>, Priority>.One(a),
                deeper: FingerTree<Prioritized<T>, Priority>.Empty,
                suffix: Affix<Prioritized<T>, Priority>.One(
                    prioritized.toElement
                )
            )
        case let .Deep(prefix, deeper, suffix, annotation):
            switch prefix {
            case let .Four(a, b, c, d):
                newTree = FingerTree<Prioritized<T>, Priority>.Deep(
                    prefix: Affix.Two(prioritized.toElement, a),
                    deeper: deeper.preface(
                        Node.Branch3(
                            b, c, d,
                            b.measure <> c.measure <> d.measure
                        ).toElement
                    ),
                    suffix: suffix,
                    prioritized.measure <> annotation
                )
            default:
                newTree = FingerTree.Deep(
                    prefix: try! prefix.preface(prioritized.toElement),
                    deeper: deeper,
                    suffix: suffix,
                    prioritized.measure <> annotation
                )
            }
        }

        return PriorityQueue(newTree)
    }
}
