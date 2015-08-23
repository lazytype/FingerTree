// FingerTree.swift
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

enum FingerTree<Element: Measurable, V: Monoid where V == Element.V>
    : CachedMeasurable, CustomStringConvertible {
    typealias NodeTree = FingerTree<Node<Element, V>, V>

    indirect case Empty(CachedValue<V>)
    indirect case Single(Element, CachedValue<V>)
    indirect case Deep(
        prefix: Affix<Element, V>,
        deeper: NodeTree,
        suffix: Affix<Element, V>,
        CachedValue<V>
    )

    init() {
        self = .Empty(CachedValue())
    }

    init(_ a: Element) {
        self = .Single(a, CachedValue())
    }

    init(
        prefix: Affix<Element, V>,
        deeper: NodeTree,
        suffix: Affix<Element, V>
    ) {
        self = .Deep(
            prefix: prefix,
            deeper: deeper,
            suffix: suffix,
            CachedValue()
        )
    }

    func preface(element: Element) -> FingerTree<Element, V> {
        switch self {
        case .Empty:
            return FingerTree(element)
        case let .Single(a, _):
            return FingerTree(
                prefix: Affix(element),
                deeper: NodeTree(),
                suffix: Affix(a)
            )
        case let .Deep(.Four(a, b, c, d, _), deeper, suffix, _):
            return FingerTree(
                prefix: Affix(element, a),
                deeper: deeper.preface(Node(b, c, d)),
                suffix: suffix
            )
        case let .Deep(prefix, deeper, suffix, _):
            return FingerTree(
                prefix: try! prefix.preface(element),
                deeper: deeper,
                suffix: suffix
            )
        }
    }

    func append(element: Element) -> FingerTree<Element, V> {
        switch self {
        case .Empty:
            return FingerTree(element)
        case let .Single(a, _):
            return FingerTree(
                prefix: Affix(a),
                deeper: NodeTree(),
                suffix: Affix(element)
            )
        case let .Deep(prefix, deeper, .Four(a, b, c, d, _), _):
            return FingerTree(
                prefix: prefix,
                deeper: deeper.append(Node(a, b, c)),
                suffix: Affix(d, element)
            )
        case let .Deep(prefix, deeper, suffix, _):
            return FingerTree(
                prefix: prefix,
                deeper: deeper,
                suffix: try! suffix.append(element)
            )
        }
    }

    private static func nodes(array: [Element]) -> [Node<Element, V>]? {
        switch array.count {
        case 1:
            return nil
        case 2:
            return [Node<Element, V>(array[0], array[1])]
        case 3:
            return [Node<Element, V>(array[0], array[1], array[2])]
        default:
            var nodeArray = nodes(Array(array[0..<(array.count - 2)]))
            nodeArray!.append(
                Node<Element, V>(array[array.count - 2], array[array.count - 1])
            )
            return nodeArray
        }
    }

    static func concatenate(
        middle: [Element] = [],
        left: FingerTree<Element, V>,
        right: FingerTree<Element, V>
    ) -> FingerTree<Element, V> {

        switch (middle, left, right) {
        case (_, .Empty, _) where middle.isEmpty:
            return right

        case (_, _, .Empty) where middle.isEmpty:
            return left

        case (_, .Empty, _):
            return concatenate(
                Array(middle[1..<middle.count]),
                left: FingerTree(),
                right: right
            ).preface(middle.first!)

        case (_, _, .Empty):
            return concatenate(
                Array(middle[0..<(middle.count - 1)]),
                left: left,
                right: FingerTree()
            ).append(middle.last!)

        case let (_, .Single(a, _), _):
            return concatenate(
                middle,
                left: FingerTree(),
                right: right
            ).preface(a)

        case let (_, _, .Single(a, _)):
            return concatenate(
                middle,
                left: left,
                right: FingerTree()
            ).append(a)

        case let (
            _,
            .Deep(leftPrefix, leftDeeper, leftSuffix, _),
            .Deep(rightPrefix, rightDeeper, rightSuffix, _)
        ):
            return FingerTree(
                prefix: leftPrefix,
                deeper: NodeTree.concatenate(
                    self.nodes(
                        leftSuffix.toArray + middle + rightPrefix.toArray
                    )!,
                    left: leftDeeper,
                    right: rightDeeper
                ),
                suffix: rightSuffix
            )

        default:
            // All cases have actually been exhausted.
            // Remove when the compiler is smarter about this.
            return FingerTree()
        }
    }

    func extend(tree: FingerTree<Element, V>) -> FingerTree<Element, V> {
        return FingerTree.concatenate(left: self, right: tree)
    }

    internal var computeMeasure: V {
        switch self {
        case .Empty:
            return V.identity
        case let .Single(a, _):
            return a.measure
        case let .Deep(prefix, deeper, suffix, _):
            return prefix.measure <> deeper.measure <> suffix.measure
        }
    }

    var cachedMeasure: CachedValue<V> {
        switch self {
        case let .Empty(annotation):
            return annotation
        case let .Single(_, annotation):
            return annotation
        case let .Deep(_, _, _, annotation):
            return annotation
        }
    }

    var description: String {
        switch self {
        case .Empty:
            return "{}"
        case let .Single(a, _):
            return "{\(a)}"
        case let .Deep(left, deeper, right, _):
            let deepDesc: String = "\n".join(
                deeper.description.characters.split("\n")
                    .map {" " + String($0)}
            )
            return (
                "[\(self.measure)] {\n" +
                " \(left.toArray),\n" +
                deepDesc + ",\n" +
                " \(right.toArray)\n" +
                "}"
            )
        }
    }
}
