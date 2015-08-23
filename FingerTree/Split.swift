// Split.swift
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

enum SplitError: ErrorType {
    case NotFound
}

class Split<Element: Measurable, V: Monoid where V == Element.V> {
    let left: FingerTree<Element, V>
    let element: Element
    let right: FingerTree<Element, V>

    init(
        left: FingerTree<Element, V>,
        element: Element,
        right: FingerTree<Element, V>
    ) {
        self.left = left
        self.element = element
        self.right = right
    }

    class func split(
        predicate predicate: V -> Bool,
        startAnnotation: V,
        tree: FingerTree<Element, V>
    ) throws -> Split<Element, V> {

        switch tree {
        case .Empty:
            break
        case let .Single(a, _):
            if predicate(startAnnotation <> tree.measure) {
                return Split(
                    left: FingerTree<Element, V>(),
                    element: a,
                    right: FingerTree<Element, V>()
                )
            }
        case let .Deep(prefix, deeper, suffix, _):
            if !predicate(startAnnotation <> tree.measure) {
                throw SplitError.NotFound
            }

            let startToPrefix = startAnnotation <> prefix.measure
            if predicate(startToPrefix) {
                if let (before, after) = Split.splitList(
                    predicate: predicate,
                    startAnnotation: startAnnotation,
                    values: prefix
                ) {
                    let (first, rest) = after.viewFirst

                    let left: FingerTree<Element, V>
                    if let affix: Affix = before {
                        left = affix.toFingerTree
                    } else {
                        left = FingerTree()
                    }

                    return Split(
                        left: left,
                        element: first,
                        right: FingerTree.createDeep(
                            prefix: rest,
                            deeper: deeper,
                            suffix: suffix
                        )
                    )
                }
            } else if predicate(startToPrefix <> deeper.measure) {
                let split = try! Split<Node<Element, V>, V>.split(
                    predicate: predicate,
                    startAnnotation: startToPrefix,
                    tree: deeper
                )

                if let (beforeNode, afterNode) = Split.splitList(
                    predicate: predicate,
                    startAnnotation: startToPrefix <> split.left.measure,
                    values: TreeView.nodeToAffix(split.element)
                ) {
                    let (first, rest) = afterNode.viewFirst

                    return Split(
                        left: FingerTree.createDeep(
                            prefix: prefix,
                            deeper: split.left,
                            suffix: beforeNode
                        ),
                        element: first,
                        right: FingerTree.createDeep(
                            prefix: rest,
                            deeper: split.right,
                            suffix: suffix
                        )
                    )
                }
            } else if let (before, after) = Split.splitList(
                predicate: predicate,
                startAnnotation: startToPrefix <> deeper.measure,
                values: suffix
            ) {
                let (first, rest) = after.viewFirst

                let right: FingerTree<Element, V>
                if let affix: Affix = rest {
                    right = affix.toFingerTree
                } else {
                    right = FingerTree()
                }

                return Split(
                    left: FingerTree.createDeep(
                        prefix: prefix,
                        deeper: deeper,
                        suffix: before
                    ),
                    element: first,
                    right: right
                )
            }
        }

        throw SplitError.NotFound
    }

    private class func splitList(
        predicate predicate: V -> Bool,
        startAnnotation: V,
        values: Affix<Element, V>
    ) -> (Affix<Element, V>?, Affix<Element, V>)? {
        let (first, rest) = values.viewFirst

        let start = startAnnotation <> first.measure

        if predicate(start) {
            return (nil, values)
        }

        if rest == nil {
            return nil
        }

        if let (before, after) = splitList(
            predicate: predicate,
            startAnnotation: start,
            values: rest!
        ) {
            if before == nil {
                return (Affix(first), after)
            }
            
            return (try! before!.preface(first), after)
        }

        return nil
    }
}
