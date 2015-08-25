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
        case let .Single(a, _):
            return (a, FingerTree())
        case let .Deep(.One(a, _), deeper, suffix, _):
            let rest: FingerTree<Element, V>

            if let (element, deeperRest) = deeper.viewLeft {
                rest = FingerTree(
                    prefix: element.toAffix,
                    deeper: deeperRest,
                    suffix: suffix
                )
            } else {
                rest = suffix.toFingerTree
            }

            return (a, rest)

        case let .Deep(prefix, deeper, suffix, _):
            let (first, rest) = prefix.viewFirst

            return (
                first,
                FingerTree(
                    prefix: rest!,
                    deeper: deeper,
                    suffix: suffix
                )
            )
        }
    }

    var viewRight: (FingerTree, Element)? {
        switch self {
        case .Empty:
            return nil
        case let .Single(a, _):
            return (FingerTree(), a)
        case let .Deep(prefix, deeper, .One(a, _), _):
            let rest: FingerTree<Element, V>

            if let (deeperRest, element) = deeper.viewRight {
                rest = FingerTree(
                    prefix: prefix,
                    deeper: deeperRest,
                    suffix: element.toAffix
                )
            } else {
                rest = prefix.toFingerTree
            }

            return (rest, a)

        case let .Deep(prefix, deeper, suffix, _):
            let (rest, last) = suffix.viewLast

            return (
                FingerTree(
                    prefix: prefix,
                    deeper: deeper,
                    suffix: rest!
                ),
                last
            )
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

extension Node {
    var toAffix: Affix<Element, V> {
        switch self {
        case let .Branch2(a, b, _):
            return Affix(a, b)
        case let .Branch3(a, b, c, _):
            return Affix(a, b, c)
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
            if let (element, rest) = deeper.viewLeft {
                return createDeep(
                    prefix: element.toAffix,
                    deeper: rest,
                    suffix: nil
                )
            } else {
                return FingerTree<Element, V>()
            }
        } else if prefix == nil {
            if let (rest, element) = deeper.viewRight {
                return createDeep(
                    prefix: element.toAffix,
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
                    suffix: element.toAffix
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
