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

extension FingerTree {
    func split(
        predicate predicate: TAnnotation -> Bool,
        startAnnotation: TAnnotation
    ) throws -> (FingerTree, FingerTree) {
        switch self {
        case .Empty:
            break
        case .Single:
            if predicate(startAnnotation <> measure) {
                return (FingerTree.Empty, self)
            }
        case let .Deep(prefix, deeper, suffix, _):
            if !predicate(startAnnotation <> measure) {
                throw SplitError.NotFound
            }

            let startToPrefix = startAnnotation <> prefix.measure
            if predicate(startToPrefix) {
                if let (before, after) = FingerTree.splitList(
                    predicate: predicate,
                    startAnnotation: startAnnotation,
                    values: prefix
                ) {
                    let left: FingerTree
                    if let affix: Affix = before {
                        left = affix.toFingerTree
                    } else {
                        left = FingerTree.Empty
                    }

                    return (
                        left,
                        FingerTree.createDeep(
                            prefix: after,
                            deeper: deeper,
                            suffix: suffix
                        )
                    )
                }
            } else if predicate(startToPrefix <> deeper.measure) {
                let (left, right) = try! deeper.split(
                    predicate: predicate,
                    startAnnotation: startToPrefix
                )

                let (element, rest) = right.viewLeft!

                if let (beforeNode, afterNode) = FingerTree.splitList(
                    predicate: predicate,
                    startAnnotation: startToPrefix <> left.measure,
                    values: element.node!.toAffix
                ) {
                    return (
                        FingerTree.createDeep(
                            prefix: prefix,
                            deeper: left,
                            suffix: beforeNode
                        ),
                        FingerTree.createDeep(
                            prefix: afterNode,
                            deeper: rest,
                            suffix: suffix
                        )
                    )
                }
            } else if let (before, after) = FingerTree.splitList(
                predicate: predicate,
                startAnnotation: startToPrefix <> deeper.measure,
                values: suffix
            ) {
                return (
                    FingerTree.createDeep(
                        prefix: prefix,
                        deeper: deeper,
                        suffix: before
                    ),
                    after.toFingerTree
                )
            }
        }

        throw SplitError.NotFound
    }

    private static func splitList(
        predicate predicate: TAnnotation -> Bool,
        startAnnotation: TAnnotation,
        values: Affix<TValue, TAnnotation>
    ) -> (Affix<TValue, TAnnotation>?, Affix<TValue, TAnnotation>)? {
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
                return (Affix.One(first), after)
            }

            return (try! before!.preface(first), after)
        }

        return nil
    }
}
