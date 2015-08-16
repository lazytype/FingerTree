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


enum FingerTree<Element: Measured, V: Monoid where V == Element.V>
    : Measured, CustomStringConvertible {
    typealias NodeTree = FingerTree<Node<Element, V>, V>

    case Empty
    case Single(Element)
    indirect case Deep(
        annotation: V,
        prefix: Affix<Element, V>,
        deeper: NodeTree,
        suffix: Affix<Element, V>
    )

    func preface(element: Element) -> FingerTree<Element, V> {
        let newAnnotation = V.monoidPlus(element.measure, self.measure)

        switch self {
        case .Empty:
            return FingerTree.Single(element)
        case .Single(let a):
            return FingerTree.Deep(
                annotation: newAnnotation,
                prefix: Affix.One(element),
                deeper: NodeTree.Empty,
                suffix: Affix.One(a)
            )
        case .Deep(
            _,
            .Four(let a, let b, let c, let d),
            let deeper,
            let suffix
        ):
            return FingerTree.Deep(
                annotation: newAnnotation,
                prefix: Affix.Two(element, a),
                deeper: deeper.preface(
                    Node.Branch3(
                        annotation: V.monoidSum(
                            b.measure,
                            c.measure,
                            d.measure
                        ),
                        b,
                        c,
                        d
                    )
                ),
                suffix: suffix
            )
        case .Deep(_, let prefix, let deeper, let suffix):
            return FingerTree.Deep(
                annotation: newAnnotation,
                prefix: try! prefix.preface(element),
                deeper: deeper,
                suffix: suffix
            )
        }
    }

    func append(element: Element) -> FingerTree {
        let newAnnotation = V.monoidPlus(self.measure, element.measure)

        switch self {
        case .Empty:
            return FingerTree.Single(element)
        case .Single(let a):
            return FingerTree.Deep(
                annotation: newAnnotation,
                prefix: Affix.One(a),
                deeper: NodeTree.Empty,
                suffix: Affix.One(element)
            )
        case .Deep(
            _,
            let prefix,
            let deeper,
            .Four(let a, let b, let c, let d)
        ):
            return FingerTree.Deep(
                annotation: newAnnotation,
                prefix: prefix,
                deeper: deeper.append(
                    Node.Branch3(
                        annotation: V.monoidSum(
                            a.measure,
                            b.measure,
                            c.measure
                        ),
                        a,
                        b,
                        c
                    )
                ),
                suffix: Affix.Two(d, element)
            )
        case .Deep(_, let prefix, let deeper, let suffix):
            return FingerTree.Deep(
                annotation: newAnnotation,
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
            return [
                Node<Element, V>.Branch2(
                    annotation: V.monoidSum(array.map({$0.measure})),
                    array[0],
                    array[1]
                )
            ]
        case 3:
            return [
                Node<Element, V>.Branch3(
                    annotation: V.monoidSum(array.map({$0.measure})),
                    array[0],
                    array[1],
                    array[2]
                )
            ]
        default:
            var nodeArray = nodes(Array(array[0..<(array.count - 2)]))
            nodeArray!.append(
                Node<Element, V>.Branch2(
                    annotation: V.monoidSum(
                        array[array.count - 2].measure,
                        array[array.count - 1].measure
                    ),
                    array[array.count - 2],
                    array[array.count - 1]
                )
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
                left: .Empty,
                right: right
            ).preface(middle.first!)

        case (_, _, .Empty):
            return concatenate(
                Array(middle[0..<(middle.count - 1)]),
                left: left,
                right: .Empty
            ).append(middle.last!)

        case (_, .Single(let a), _):
            return concatenate(
                middle,
                left: FingerTree<Element, V>.Empty,
                right: right
            ).preface(a)

        case (_, _, .Single(let a)):
            return concatenate(
                middle,
                left: left,
                right: FingerTree<Element, V>.Empty
            ).append(a)

        case (
            _,
            .Deep(_, let leftPrefix, let leftDeeper, let leftSuffix),
            .Deep(_, let rightPrefix, let rightDeeper, let rightSuffix)
        ):
            return FingerTree<Element, V>.Deep(
                annotation: V.monoidPlus(left.measure, right.measure),
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
            return FingerTree.Empty
        }
    }

    func extend(tree: FingerTree<Element, V>) -> FingerTree<Element, V> {
        return FingerTree<Element, V>.concatenate(left: self, right: tree)
    }

    var measure: V {
        switch self {
        case .Empty:
            return V.empty()
        case .Single(let a):
            return a.measure
        case .Deep(let annotation, _, _, _):
            return annotation
        }
    }

    var description: String {
        switch self {
        case .Empty:
            return "{}"
        case .Single(let a):
            return "{\(a)}"
        case .Deep(_, let left, let deeper, let right):
            let deepDesc: String = "\n".join(
                deeper.description.characters.split("\n")
                    .map {" " + String($0)}
            )
            return (
                "{\n" +
                " \(left.toArray),\n" +
                deepDesc + ",\n" +
                " \(right.toArray)\n" +
                "}"
            )
        }
    }
}
