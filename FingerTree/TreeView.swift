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

extension FingerTree {
    var viewLeft: (Element, FingerTree)? {
        switch self {
        case .Empty:
            return nil
        case let .Single(a):
            return (a, FingerTree.Empty)
        case let .Deep(.One(a), deeper, suffix, _):
            let rest: FingerTree

            if let (element, deeperRest) = deeper.viewLeft {
                rest = FingerTree.Deep(
                    prefix: element.node!.toAffix,
                    deeper: deeperRest,
                    suffix: suffix,
                    deeper.measure <> suffix.measure
                )
            } else {
                rest = suffix.toFingerTree
            }

            return (a, rest)

        case let .Deep(prefix, deeper, suffix, _):
            let (first, rest) = prefix.viewFirst

            return (
                first,
                FingerTree.Deep(
                    prefix: rest!,
                    deeper: deeper,
                    suffix: suffix,
                    rest!.measure <> deeper.measure <> suffix.measure
                )
            )
        }
    }

    var viewRight: (FingerTree, Element)? {
        switch self {
        case .Empty:
            return nil
        case let .Single(a):
            return (FingerTree.Empty, a)
        case let .Deep(prefix, deeper, .One(a), _):
            let rest: FingerTree

            if let (deeperRest, element) = deeper.viewRight {
                rest = FingerTree.Deep(
                    prefix: prefix,
                    deeper: deeperRest,
                    suffix: element.node!.toAffix,
                    prefix.measure <> deeper.measure
                )
            } else {
                rest = prefix.toFingerTree
            }

            return (rest, a)

        case let .Deep(prefix, deeper, suffix, _):
            let (rest, last) = suffix.viewLast

            return (
                FingerTree.Deep(
                    prefix: prefix,
                    deeper: deeper,
                    suffix: rest!,
                    prefix.measure <> deeper.measure <> rest!.measure
                ),
                last
            )
        }
    }
}

extension Affix {
    var toFingerTree: FingerTree<TValue, TAnnotation> {
        switch self {
        case let .One(a):
            return FingerTree.Single(a)
        case let .Two(a, b, annotation):
            return FingerTree.Deep(
                prefix: Affix.One(a),
                deeper: FingerTree.Empty,
                suffix: Affix.One(b),
                annotation
            )
        case let .Three(a, b, c, annotation):
            return FingerTree.Deep(
                prefix: Affix.Two(a, b, a.measure <> b.measure),
                deeper: FingerTree.Empty,
                suffix: Affix.One(c),
                annotation
            )
        case let .Four(a, b, c, d, annotation):
            return FingerTree.Deep(
                prefix: Affix.Two(a, b, a.measure <> b.measure),
                deeper: FingerTree.Empty,
                suffix: Affix.Two(c, d, c.measure <> d.measure),
                annotation
            )
        }
    }
}

extension Node {
    var toAffix: Affix<TValue, TAnnotation> {
        switch self {
        case let .Branch2(a, b, annotation):
            return Affix.Two(a, b, annotation)
        case let .Branch3(a, b, c, annotation):
            return Affix.Three(a, b, c, annotation)
        }
    }
}

extension FingerTree {
    static func createDeep(
        prefix prefix: Affix<TValue, TAnnotation>?,
        deeper: FingerTree,
        suffix: Affix<TValue, TAnnotation>?
    ) -> FingerTree {
        if prefix == nil && suffix == nil {
            if let (element, rest) = deeper.viewLeft {
                return createDeep(
                    prefix: element.node!.toAffix,
                    deeper: rest,
                    suffix: nil
                )
            } else {
                return FingerTree.Empty
            }
        } else if prefix == nil {
            if let (rest, element) = deeper.viewRight {
                return createDeep(
                    prefix: element.node!.toAffix,
                    deeper: rest,
                    suffix: suffix
                )
            } else {
                return suffix!.toFingerTree
            }
        } else if suffix == nil {
            if let (rest, element) = deeper.viewRight {
                return createDeep(
                    prefix: prefix,
                    deeper: rest,
                    suffix: element.node!.toAffix
                )
            } else {
                return prefix!.toFingerTree
            }
        } else {
            return FingerTree.Deep(
                prefix: prefix!,
                deeper: deeper,
                suffix: suffix!,
                prefix!.measure <> deeper.measure <> suffix!.measure
            )
        }
    }
}
