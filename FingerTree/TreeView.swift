// TreeView.swift
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

struct TreeView<Element: Measurable, V: Monoid where V == Element.V> {
    typealias NodeTree = FingerTree<Node<Element, V>, V>

    let element: Element
    let rest: FingerTree<Element, V>

    init(element: Element, rest: FingerTree<Element, V>) {
        self.element = element
        self.rest = rest
    }

    static func viewLeft(
        tree: FingerTree<Element, V>
    ) -> TreeView<Element, V>? {
        switch tree {
        case .Empty:
            return nil
        case let .Single(a, _):
            return TreeView<Element, V>(
                element: a,
                rest: FingerTree<Element, V>()
            )
        case let .Deep(.One(a, _), deeper, suffix, _):
            let rest: FingerTree<Element, V>

            if let view = TreeView<Node<Element, V>, V>.viewLeft(deeper) {
                rest = FingerTree<Element, V>(
                    prefix: nodeToAffix(view.element),
                    deeper: view.rest,
                    suffix: suffix
                )
            } else {
                rest = suffix.toFingerTree
            }

            return TreeView<Element, V>(element: a, rest: rest)

        case let .Deep(prefix, deeper, suffix, _):
            let (first, rest) = prefix.viewFirst

            return TreeView<Element, V>(
                element: first,
                rest: FingerTree<Element, V>(
                    prefix: rest!,
                    deeper: deeper,
                    suffix: suffix
                )
            )
        }
    }

    static func viewRight(
        tree: FingerTree<Element, V>
    ) -> TreeView<Element, V>? {
        switch tree {
        case .Empty:
            return nil
        case let .Single(a, _):
            return TreeView<Element, V>(
                element: a,
                rest: FingerTree<Element, V>()
            )
        case let .Deep(prefix, deeper, .One(a, _), _):
            let rest: FingerTree<Element, V>

            if let view = TreeView<Node<Element, V>, V>.viewRight(deeper) {
                rest = FingerTree(
                    prefix: prefix,
                    deeper: view.rest,
                    suffix: nodeToAffix(view.element)
                )
            } else {
                rest = prefix.toFingerTree
            }

            return TreeView<Element, V>(element: a, rest: rest)

        case let .Deep(prefix, deeper, suffix, _):
            let (rest, last) = suffix.viewLast

            return TreeView<Element, V>(
                element: last,
                rest: FingerTree<Element, V>(
                    prefix: prefix,
                    deeper: deeper,
                    suffix: rest!
                )
            )
        }
    }

    internal static func nodeToAffix(
        node: Node<Element, V>
    ) -> Affix<Element, V> {
        switch node {
        case let .Branch2(a, b, _):
            return Affix(a, b)
        case let .Branch3(a, b, c, _):
            return Affix(a, b, c)
        }
    }
}

extension Affix {
    typealias NodeTree = FingerTree<Node<Element, V>, V>

    var toFingerTree: FingerTree<Element, V> {
        switch self {
        case let .One(a, _):
            return FingerTree<Element, V>(a)
        case let .Two(a, b, _):
            return FingerTree<Element, V>(
                prefix: Affix(a),
                deeper: NodeTree(),
                suffix: Affix(b)
            )
        case let .Three(a, b, c, _):
            return FingerTree<Element, V>(
                prefix: Affix(a, b),
                deeper: NodeTree(),
                suffix: Affix(c)
            )
        case let .Four(a, b, c, d, _):
            return FingerTree<Element, V>(
                prefix: Affix(a, b),
                deeper: NodeTree(),
                suffix: Affix(c, d)
            )
        }
    }
}

extension FingerTree {
    static func createDeep(
        prefix prefix: Affix<Element, V>?,
        deeper: NodeTree,
        suffix: Affix<Element, V>?
    ) -> FingerTree {
        if prefix == nil && suffix == nil {
            if let view = TreeView<Node<Element, V>, V>.viewLeft(deeper) {
                return createDeep(
                    prefix: TreeView.nodeToAffix(view.element),
                    deeper: view.rest,
                    suffix: nil
                )
            } else {
                return FingerTree<Element, V>()
            }
        } else if prefix == nil {
            if let view = TreeView<Node<Element, V>, V>.viewRight(deeper) {
                return createDeep(
                    prefix: TreeView.nodeToAffix(view.element),
                    deeper: view.rest,
                    suffix: suffix
                )
            } else {
                return suffix!.toFingerTree
            }
        } else if suffix == nil {
            if let view = TreeView<Node<Element, V>, V>.viewRight(deeper) {
                return createDeep(
                    prefix: prefix,
                    deeper: view.rest,
                    suffix: TreeView.nodeToAffix(view.element)
                )
            } else {
                return prefix!.toFingerTree
            }
        } else {
            return FingerTree(
                prefix: prefix!,
                deeper: deeper,
                suffix: suffix!
            )
        }
    }
}
