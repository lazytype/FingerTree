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

    init(_ tree: FingerTree<Value<T>, Size> = FingerTree()) {
        self.tree = tree
    }

    public let startIndex: Int = 0

    public var endIndex: Int {
        return tree.measure.value
    }

    public subscript(position: Int) -> T {
        let (_, right) = try! splitTree(
            predicate: {$0.value > position && position >= 0},
            startAnnotation: Size.identity,
            tree: self.tree
        )

        let (element, _) = right.viewLeft!
        return element.value
    }

    public func generate() -> AnyGenerator<T> {
        let generator = tree.generate()

        return anyGenerator {
            if let nextElement = generator.next() {
                return nextElement.value
            }

            return nil
        }
    }

    public func reverse() -> AnyGenerator<T> {
        let reversed = tree.reverse()

        return anyGenerator {
            if let nextElement = reversed.next() {
                return nextElement.value
            }

            return nil
        }
    }

    func insert(element: T, atIndex: Int) -> ImmutableCollection<T>  {
        do {
            let (left, right) = try splitTree(
                predicate: {$0.value > atIndex && atIndex >= 0},
                startAnnotation: Size.identity,
                tree: self.tree
            )

            let tree = FingerTree.concatenate(
                middle: [Value(element)],
                left: left,
                right: right
            )

            return ImmutableCollection(tree)
        } catch {
            return ImmutableCollection(FingerTree(Value(element)))
        }
    }
}

public struct PriorityQueue<T> {
    let tree: FingerTree<Prioritized<T>, Priority>
    
    init(_ tree: FingerTree<Prioritized<T>, Priority>) {
        self.tree = tree
    }

    public func pop() -> (T, PriorityQueue<T>) {
        let (left, right) = try! splitTree(
            predicate: {$0 == self.tree.measure},
            startAnnotation: Priority.NegativeInfinity,
            tree: self.tree
        )

        let (element, rest) = right.viewLeft!

        let newTree = left.extend(rest) // wrong!

        return (element.value, PriorityQueue(newTree))
    }

    public func push(element: T, value: Int) -> PriorityQueue<T> {
        let prioritized = Prioritized(element, priority: value)
        let newTree: FingerTree<Prioritized<T>, Priority>

        switch self.tree {
        case .Empty:
            newTree = FingerTree(prioritized)
        case let .Single(a, _):
            newTree = FingerTree.createDeep(
                prefix: Affix(a),
                deeper: FingerTree(),
                suffix: Affix(prioritized)
            )
        case let .Deep(prefix, deeper, suffix, _):
            switch prefix {
            case let .Four(a, b, c, d, _):
                newTree = FingerTree(
                    prefix: Affix(prioritized, a),
                    deeper: deeper.preface(Node(b,c,d)),
                    suffix: suffix
                )
            default:
                newTree = FingerTree(
                    prefix: try! prefix.preface(prioritized),
                    deeper: deeper,
                    suffix: suffix
                )
            }
        }

        return PriorityQueue(newTree)
    }
}

