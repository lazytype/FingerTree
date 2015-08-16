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


class Split<Element: Measured, V: Monoid where V == Element.V> {
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
    ) -> Split<Element, V>? {

        switch tree {
        case .Empty:
            return nil
        case .Single(let a):
            let annotation: V = V.monoidPlus(startAnnotation, a.measure)

            if predicate(annotation) {
                return Split(
                    left: FingerTree<Element, V>.Empty,
                    element: a,
                    right: FingerTree<Element, V>.Empty
                )
            }

            return nil

        case .Deep(let totalAnnotation, let prefix, let deeper, let suffix):
            if !predicate(V.monoidPlus(startAnnotation, totalAnnotation)) {
                return nil
            }

            let startToPrefix = V.monoidPlus(startAnnotation, prefix.measure)
            if predicate(startToPrefix) {
                let (before, after) = Split.splitList(
                    predicate: predicate,
                    startAnnotation: startAnnotation,
                    values: ConsList.fromAffix(prefix)
                )!
                switch after {
                case .Empty:
                    return nil
                case .Cons(let first, let rest):
                    let left : FingerTree<Element, V>
                    if let affix : Affix = before.toAffix {
                        left = affix.toFingerTree
                    } else {
                        left = .Empty
                    }
                    return Split(
                        left: left,
                        element: first,
                        right: FingerTree.createDeep(
                            prefix: rest.toArray,
                            deeper: deeper,
                            suffix: suffix.toArray
                        )!
                    )
                }
            } else if predicate(
                V.monoidSum(startAnnotation, prefix.measure, deeper.measure)
            ) {
                let split = Split<Node<Element, V>, V>.split(
                    predicate: predicate,
                    startAnnotation: startToPrefix,
                    tree: deeper
                )!
                let startToDeeperLeft = V.monoidPlus(
                    startToPrefix,
                    split.left.measure
                )
                let (beforeNode, afterNode) = Split.splitList(
                    predicate: predicate,
                    startAnnotation: startToDeeperLeft,
                    values: ConsList.fromElements(split.element.toArray)
                )!

                switch afterNode {
                case .Empty:
                    return nil
                case .Cons(let first, let rest):
                    return Split(
                        left: FingerTree.createDeep(
                            prefix: prefix.toArray,
                            deeper: split.left,
                            suffix: beforeNode.toArray
                        )!,
                        element: first,
                        right: FingerTree.createDeep(
                            prefix: rest.toArray,
                            deeper: split.right,
                            suffix: suffix.toArray
                        )!
                    )
                }
            } else {
                let startToDeep = V.monoidPlus(startToPrefix, deeper.measure)
                let (before, after) = Split.splitList(
                    predicate: predicate,
                    startAnnotation: startToDeep,
                    values: ConsList.fromAffix(suffix)
                )!
                switch after {
                case .Empty:
                    return nil
                case .Cons(let first, let rest):
                    let right: FingerTree<Element, V>
                    if let affix : Affix = rest.toAffix {
                        right = affix.toFingerTree
                    } else {
                        right = .Empty
                    }
                    return Split(
                        left: FingerTree.createDeep(
                            prefix: prefix.toArray,
                            deeper: deeper,
                            suffix: before.toArray
                        )!,
                        element: first,
                        right: right
                    )
                }
            }
        }
    }

    private class func splitList(
        predicate predicate: V -> Bool,
        startAnnotation: V,
        values: ConsList<Element, V>
    ) -> (ConsList<Element, V>, ConsList<Element, V>)? {

        switch values {
        case .Empty:
            return nil
        case .Cons(let first, let rest):
             let start: V = V.monoidPlus(startAnnotation, first.measure)

             if predicate(start) {
                 return (ConsList.Empty, values)
             }

             let (before, after) = splitList(
                 predicate: predicate,
                 startAnnotation: start,
                 values: rest
             )!

             return (ConsList.Cons(first: first, rest: before), after)
        }
    }
}