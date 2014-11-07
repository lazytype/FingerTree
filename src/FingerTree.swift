// FingerTree.swift
//
// Copyright (c) 2014 Michael Mitchell
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


enum Node<T: Measured, V: Monoid where V == T.M>: Measured {
    typealias M = V

    case Branch2(
        annotation: @autoclosure () -> V,
        @autoclosure () -> T,
        @autoclosure () -> T
    )
    case Branch3(
        annotation: @autoclosure () -> V,
        @autoclosure () -> T,
        @autoclosure () -> T,
        @autoclosure () -> T
    )

    var measure: V {
        switch self {
        case .Branch2(let annotation, _, _):
            return annotation()
        case .Branch3(let annotation, _, _, _):
            return annotation()
        }
    }
}


enum Affix<T: Measured, V: Monoid where V == T.M>: Measured {
    typealias M = V

    case One(
        @autoclosure () -> T
    )
    case Two(
        @autoclosure () -> T,
        @autoclosure () -> T
    )
    case Three(
        @autoclosure () -> T,
        @autoclosure () -> T,
        @autoclosure () -> T
    )
    case Four(
        @autoclosure () -> T,
        @autoclosure () -> T,
        @autoclosure () -> T,
        @autoclosure () -> T
    )

    func prepend(element: T) -> Affix? {
        switch self {
        case .One(let a):
            return Two(element, a)
        case .Two(let a, let b):
            return Three(element, a, b)
        case .Three(let a, let b, let c):
            return Four(element, a, b, c)
        case .Four:
            return nil
        }
    }

    func append(element: T) -> Affix? {
        switch self {
        case .One(let a):
            return Two(a, element)
        case .Two(let a, let b):
            return Three(a, b, element)
        case .Three(let a, let b, let c):
            return Four(a, b, c, element)
        case .Four:
            return nil
        }
    }

    var viewFirst: (T, Affix<T, V>?) {
        switch self {
        case .One(let a):
            return (a(), nil)
        case .Two(let a, let b):
            return (a(), One(b))
        case .Three(let a, let b, let c):
            return (a(), Two(b, c))
        case .Four(let a, let b, let c, let d):
            return (a(), Three(b, c, d))
        }
    }

    var viewLast: (Affix<T, V>?, T) {
        switch self {
        case .One(let a):
            return (nil, a())
        case .Two(let a, let b):
            return (One(a), b())
        case .Three(let a, let b, let c):
            return (Two(a, b), c())
        case .Four(let a, let b, let c, let d):
            return (Three(a, b, c), d())
        }
    }

    static func fromNode(
        node: @autoclosure () -> Node<T, V>
    ) -> Affix<T, V> {

        switch node() {
        case .Branch2(let annotation, let a, let b):
            return Affix<T, V>.Two(a, b)
        case .Branch3(let annotation, let a, let b, let c):
            return Affix<T, V>.Three(a, b, c)
        }
    }

    var toArray: [T] {
        switch self {
        case .One(let a):
            return [a()]
        case .Two(let a, let b):
            return [a(), b()]
        case .Three(let a, let b, let c):
            return [a(), b(), c()]
        case .Four(let a, let b, let c, let d):
            return [a(), b(), c(), d()]
        }
    }

    var measure: V {
        return self.toArray.map {
            $0.measure
        } .reduce(V.empty()) {
            V.monoidPlus(left: $0, right: $1)
        }
    }
}


enum FingerTree<T: Measured, V: Monoid where V == T.M>: Measured {
    typealias M = V

    case Empty
    case Single(@autoclosure () -> T)
    case Deep(
        annotation: @autoclosure () -> V,
        prefix: Affix<T, V>,
        deeper: @autoclosure () -> FingerTree<Node<T, V>, V>,
        suffix: Affix<T, V>
    )

    func prepend(element: T) -> FingerTree<T, V> {
        switch self {
        case .Empty:
            return Single(element)
        case .Single(let a):
            return Deep(
                annotation: V.empty(),
                prefix: Affix.One(element),
                deeper: FingerTree<Node<T, V>, V>.Empty,
                suffix: Affix.One(a)
            )
        case .Deep(
            let annotation,
            .Four(let a, let b, let c, let d),
            let deeper,
            let suffix
        ):
            return Deep(
                annotation: V.empty(),
                prefix: Affix.Two(element, a),
                deeper: deeper().prepend(
                    Node.Branch3(annotation: annotation, b, c, d)
                ),
                suffix: suffix
            )
        case .Deep(_, let prefix, let deeper, let suffix):
            return Deep(
                annotation: V.empty(),
                prefix: prefix.prepend(element)!,
                deeper: deeper(),
                suffix: suffix
            )
        }
    }

    func append(element: T) -> FingerTree<T, V> {
        switch self {
        case .Empty:
            return Single(element)
        case .Single(let a):
            return Deep(
                annotation: V.empty(),
                prefix: Affix.One(a),
                deeper: FingerTree<Node<T, V>, V>.Empty,
                suffix: Affix.One(element)
            )
        case .Deep(
            let annotation,
            let prefix,
            let deeper,
            .Four(let a, let b, let c, let d)
        ):
            return Deep(
                annotation: V.empty(),
                prefix: prefix,
                deeper: deeper().append(
                    Node.Branch3(annotation: annotation, a, b, c)
                ),
                suffix: Affix.Two(d, element)
            )
        case .Deep(_, let prefix, let deeper, let suffix):
            return Deep(
                annotation: V.empty(),
                prefix: prefix,
                deeper: deeper,
                suffix: suffix.append(element)!
            )
        }
    }

    private static func nodes(array: [T]) -> [Node<T, V>]? {
        if array.count <= 1 {
            return nil
        } else if array.count == 2 {
            return [
                Node<T, V>.Branch2(
                    annotation: V.empty(),
                    array[0], array[1]
                )
            ]
        } else if array.count == 3 {
            return [
                Node<T, V>.Branch3(
                    annotation: V.empty(),
                    array[0], array[1], array[2]
                )
            ]
        } else {
            var nodeArray = nodes(Array(array[0..<(array.count - 2)]))
            nodeArray!.append(
                Node<T, V>.Branch2(
                    annotation: V.empty(),
                    array[array.count - 2],
                    array[array.count - 1]
                )
            )
            return nodeArray
        }
    }

    private static func joinTwo(
        joiner: [T] = [],
        left: FingerTree<T, V>,
        right: FingerTree<T, V>
    ) -> FingerTree<T, V> {

        switch (joiner, left, right) {
        case (_, .Empty, _) where joiner.isEmpty:
            return right

        case (_, _, .Empty) where joiner.isEmpty:
            return left

        case (_, .Empty, _):
            return joinTwo(
                joiner: Array(joiner[1..<joiner.count]),
                left: FingerTree<T, V>.Empty,
                right: right
            ).prepend(joiner.first!)

        case (_, _, .Empty):
            return joinTwo(
                joiner: Array(joiner[0..<(joiner.count - 1)]),
                left: left,
                right: FingerTree<T, V>.Empty
            ).append(joiner.last!)

        case (_, .Single(let a), _):
            return joinTwo(
                joiner: joiner,
                left: FingerTree<T, V>.Empty,
                right: right
            ).prepend(a())

        case (_, _, .Single(let a)):
            return joinTwo(
                joiner: joiner,
                left: left,
                right: FingerTree<T, V>.Empty
            ).append(a())

        case (
            _,
            .Deep(_, let leftPrefix, let leftDeeper, let leftSuffix),
            .Deep(_, let rightPrefix, let rightDeeper, let rightSuffix)
        ):
            return FingerTree<T, V>.Deep(
                annotation: V.empty(),
                prefix: leftPrefix,
                deeper: FingerTree<Node<T, V>, V>.joinTwo(
                    joiner: nodes(
                        leftSuffix.toArray + joiner + rightPrefix.toArray
                    )!,
                    left: leftDeeper(),
                    right: rightDeeper()
                ),
                suffix: rightSuffix
            )

        default:
            // All cases have actually been exhausted.
            // This is needed because the compiler is stupid.
            return FingerTree.Empty
        }
    }

    static func join(
        sequence: [T] = [],
        trees: FingerTree<T, V>...
    ) -> FingerTree<T, V> {

        return trees.reduce(FingerTree.Empty) {
            FingerTree.joinTwo(left: $0, right: $1)
        }
    }

    func extend(tree: FingerTree<T, V>) -> FingerTree<T, V> {
        return FingerTree<T, V>.join(trees: self, tree)
    }

    static func fromAffix(affix: Affix<T, V>) -> FingerTree<T, V> {
        switch affix {
        case .One(let a):
            return FingerTree<T, V>.Single(a)
        case .Two(let a, let b):
            return FingerTree<T, V>.Deep(
                annotation: V.empty(),
                prefix: Affix<T, V>.One(a),
                deeper: FingerTree<Node<T, V>, V>.Empty,
                suffix: Affix<T, V>.One(b)
            )
        case .Three(let a, let b, let c):
            return FingerTree<T, V>.Deep(
                annotation: V.empty(),
                prefix: Affix<T, V>.Two(a, b),
                deeper: FingerTree<Node<T, V>, V>.Empty,
                suffix: Affix<T, V>.One(c)
            )
        case .Four(let a, let b, let c, let d):
            return FingerTree<T, V>.Deep(
                annotation: V.empty(),
                prefix: Affix<T, V>.Two(a, b),
                deeper: FingerTree<Node<T, V>, V>.Empty,
                suffix: Affix<T, V>.Two(c, d)
            )
        }
    }

    var measure: V {
        switch self {
        case .Empty:
            return V.empty()
        case .Single(let a):
            return a().measure
        case .Deep(let annotation, _, _, _):
            return annotation()
        }
    }
}


enum TreeView<T: Measured, V: Monoid where V == T.M> {
    case Nil
    case View(
        element: @autoclosure () -> T,
        rest: FingerTree<T, V>
    )

    static func viewLeft(
        tree: @autoclosure () -> FingerTree<T, V>
    ) -> TreeView<T, V> {
        switch tree() {
        case .Empty:
            return TreeView<T, V>.Nil
        case .Single(let a):
            return TreeView<T, V>.View(
                element: a,
                rest: FingerTree<T, V>.Empty
            )
        case .Deep(_, .One(let a), let deeper, let suffix):
            var rest: FingerTree<T, V>

            switch TreeView<Node<T, V>, V>.viewLeft(deeper) {
            case .View(let element, let deepRest):
                let prefix: Affix<T, V> = Affix<T, V>.fromNode(element)
                let measures = [
                    prefix.measure,
                    deepRest.measure,
                    suffix.measure
                ]
                let annotation = measures.reduce(V.empty()) {
                    V.monoidPlus(left: $0, right: $1)
                }

                rest = FingerTree<T, V>.Deep(
                    annotation: annotation,
                    prefix: prefix,
                    deeper: deepRest,
                    suffix: suffix
                )
            case .Nil:
                rest = FingerTree<T, V>.fromAffix(suffix)
            }

            return TreeView<T, V>.View(
                element: a,
                rest: rest
            )
        case .Deep(_, let prefix, let deeper, let suffix):
            let (first, rest) = prefix.viewFirst

            return TreeView<T, V>.View(
                element: first,
                rest: FingerTree<T, V>.Deep(
                    annotation: V.empty(),
                    prefix: rest!,
                    deeper: deeper,
                    suffix: suffix
                )
            )
        }
    }

    static func viewRight(
        tree: @autoclosure () -> FingerTree<T, V>
    ) -> TreeView<T, V> {

        switch tree() {
        case .Empty:
            return TreeView<T, V>.Nil
        case .Single(let a):
            return TreeView<T, V>.View(
                element: a,
                rest: FingerTree<T, V>.Empty
            )
        case .Deep(_, let prefix, let deeper, .One(let a)):
            var rest: FingerTree<T, V>

            switch TreeView<Node<T, V>, V>.viewRight(deeper) {
            case .View(let element, let deepRest):
                let suffix: Affix<T, V> = Affix<T, V>.fromNode(element)
                let measures = [
                    prefix.measure,
                    deepRest.measure,
                    suffix.measure
                ]
                let annotation = measures.reduce(V.empty()) {
                    V.monoidPlus(left: $0, right: $1)
                }

                rest = FingerTree<T, V>.Deep(
                    annotation: annotation,
                    prefix: prefix,
                    deeper: deepRest,
                    suffix: Affix<T, V>.fromNode(element)
                )
            case .Nil:
                rest = FingerTree<T, V>.fromAffix(prefix)
            }

            return TreeView<T, V>.View(
                element: a,
                rest: rest
            )
        case .Deep(_, let prefix, let deeper, let suffix):
            let (rest, last) = prefix.viewLast

            return TreeView<T, V>.View(
                element: last,
                rest: FingerTree<T, V>.Deep(
                    annotation: V.empty(),
                    prefix: prefix,
                    deeper: deeper,
                    suffix: rest!
                )
            )
        }
    }
}
