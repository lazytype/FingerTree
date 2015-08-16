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


enum TreeView<Element: Measured, V: Monoid where V == Element.V> {
    typealias T = Element
    typealias NodeTree = FingerTree<Node<Element, V>, V>

    case Nil
    case View(
        element: T,
        rest: FingerTree<Element, V>
    )

    static func viewLeft(
        tree: FingerTree<Element, V>
    ) -> TreeView<Element, V> {
        switch tree {
        case .Empty:
            return TreeView<Element, V>.Nil
        case .Single(let a):
            return TreeView<Element, V>.View(
                element: a,
                rest: FingerTree<Element, V>.Empty
            )
        case .Deep(_, .One(let a), let deeper, let suffix):
            var rest: FingerTree<Element, V>

            switch TreeView<Node<Element, V>, V>.viewLeft(deeper) {
            case .View(let element, let deepRest):
                let prefix: Affix<Element, V> = nodeToAffix(element)
                let measures = [
                    prefix.measure,
                    deepRest.measure,
                    suffix.measure
                ]
                let annotation = V.monoidSum(measures)

                rest = FingerTree<Element, V>.Deep(
                    annotation: annotation,
                    prefix: prefix,
                    deeper: deepRest,
                    suffix: suffix
                )
            case .Nil:
                rest = suffix.toFingerTree
            }

            return TreeView<Element, V>.View(
                element: a,
                rest: rest
            )
        case .Deep(_, let prefix, let deeper, let suffix):
            let (first, rest) = prefix.viewFirst
            let measures = [
                rest!.measure,
                deeper.measure,
                suffix.measure
            ]
            let annotation: V = V.monoidSum(measures)

            return TreeView<Element, V>.View(
                element: first,
                rest: FingerTree<Element, V>.Deep(
                    annotation: annotation,
                    prefix: rest!,
                    deeper: deeper,
                    suffix: suffix
                )
            )
        }
    }

    static func viewRight(
        tree: FingerTree<Element, V>
    ) -> TreeView<Element, V> {
        switch tree {
        case .Empty:
            return TreeView<Element, V>.Nil
        case .Single(let a):
            return TreeView<Element, V>.View(
                element: a,
                rest: FingerTree<Element, V>.Empty
            )
        case .Deep(_, let prefix, let deeper, .One(let a)):
            var rest: FingerTree<Element, V>

            switch TreeView<Node<Element, V>, V>.viewRight(deeper) {
            case .View(let element, let deepRest):
                let suffix: Affix<Element, V> = nodeToAffix(element)
                let measures: [V] = [
                    prefix.measure,
                    deepRest.measure,
                    suffix.measure
                ]
                let annotation: V = V.monoidSum(measures)

                rest = FingerTree<Element, V>.Deep(
                    annotation: annotation,
                    prefix: prefix,
                    deeper: deepRest,
                    suffix: nodeToAffix(element)
                )
            case .Nil:
                rest = prefix.toFingerTree
            }

            return TreeView<Element, V>.View(
                element: a,
                rest: rest
            )
        case .Deep(_, let prefix, let deeper, let suffix):
            let (rest, last) = suffix.viewLast

            let annotation: V = V.monoidSum(
                prefix.measure,
                deeper.measure,
                rest!.measure
            )

            return TreeView<Element, V>.View(
                element: last,
                rest: FingerTree<Element, V>.Deep(
                    annotation: annotation,
                    prefix: prefix,
                    deeper: deeper,
                    suffix: rest!
                )
            )
        }
    }

    private static func nodeToAffix(
        node: Node<Element, V>
    ) -> Affix<Element, V> {
        switch node {
        case .Branch2(_, let a, let b):
            return Affix<Element, V>.Two(a, b)
        case .Branch3(_, let a, let b, let c):
            return Affix<Element, V>.Three(a, b, c)
        }
    }
}


extension Affix {
    typealias NodeTree = FingerTree<Node<Element, V>, V>

    var toFingerTree: FingerTree<Element, V> {
        switch self {
        case .One(let a):
            return FingerTree<Element, V>.Single(a)
        case .Two(let a, let b):
            return FingerTree<Element, V>.Deep(
                annotation: self.measure,
                prefix: Affix<Element, V>.One(a),
                deeper: NodeTree.Empty,
                suffix: Affix<Element, V>.One(b)
            )
        case .Three(let a, let b, let c):
            return FingerTree<Element, V>.Deep(
                annotation: self.measure,
                prefix: Affix<Element, V>.Two(a, b),
                deeper: NodeTree.Empty,
                suffix: Affix<Element, V>.One(c)
            )
        case .Four(let a, let b, let c, let d):
            return FingerTree<Element, V>.Deep(
                annotation: self.measure,
                prefix: Affix<Element, V>.Two(a, b),
                deeper: NodeTree.Empty,
                suffix: Affix<Element, V>.Two(c, d)
            )
        }
    }
}


extension FingerTree {
    static func createDeep(
        prefix prefix: [Element],
        deeper: NodeTree,
        suffix: [Element]
    ) -> FingerTree? {
        if prefix.isEmpty && suffix.isEmpty {
            switch TreeView<Node<Element, V>, V>.viewLeft(deeper) {
            case .Nil:
                return FingerTree<Element, V>.Empty
            case .View(let node, let leftDeeper):
                return createDeep(
                    prefix: node.toArray,
                    deeper: leftDeeper,
                    suffix: [] as [Element]
                )
            }
        } else if prefix.isEmpty {
            switch TreeView<Node<Element, V>, V>.viewRight(deeper) {
            case .Nil:
                return try! Affix<Element, V>.fromArray(suffix).toFingerTree
            case .View(let node, let rightDeeper):
                return createDeep(
                    prefix: node.toArray,
                    deeper: rightDeeper,
                    suffix: suffix
                )
            }
        } else if suffix.isEmpty {
            switch TreeView<Node<Element, V>, V>.viewRight(deeper) {
            case .Nil:
                return try! Affix<Element, V>.fromArray(prefix).toFingerTree
            case .View(let node, let rightDeeper):
                return createDeep(
                    prefix: prefix,
                    deeper: rightDeeper,
                    suffix: node.toArray
                )
            }
        } else if prefix.count <= 4 && suffix.count <= 4 {
            let prefixMeasure: V = V.monoidSum(prefix.map({$0.measure}))
            let suffixMeasure: V = V.monoidSum(suffix.map({$0.measure}))
            let annotation: V = V.monoidSum(
                prefixMeasure,
                deeper.measure,
                suffixMeasure
            );
            return FingerTree.Deep(
                annotation: annotation,
                prefix: try! Affix.fromArray(prefix),
                deeper: deeper,
                suffix: try! Affix.fromArray(suffix)
            )
        }
        return nil
    }
}