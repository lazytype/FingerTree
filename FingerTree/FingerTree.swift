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

enum FingerTree<
    TValue: Measurable, TAnnotation: Monoid
    where TAnnotation == TValue.Annotation> : Measurable {

    typealias Element = TreeElement<TValue, TAnnotation>

    case Empty
    case Single(Element)
    indirect case Deep(
        prefix: Affix<TValue, TAnnotation>,
        deeper: FingerTree,
        suffix: Affix<TValue, TAnnotation>,
        TAnnotation
    )

    func preface(let element: Element) -> FingerTree {
        switch self {
        case .Empty:
            return FingerTree.Single(element)
        case let .Single(a):
            return FingerTree.Deep(
                prefix: Affix.One(element),
                deeper: FingerTree.Empty,
                suffix: Affix.One(a),
                element.measure <> a.measure
            )
        case let .Deep(.Four(a, b, c, d), deeper, suffix, annotation):
            return FingerTree.Deep(
                prefix: Affix.Two(element, a),
                deeper: deeper.preface(
                    Node.Branch3(b, c, d, b.measure <> c.measure <> d.measure)
                        .toElement
                ),
                suffix: suffix,
                element.measure <> annotation
            )
        case let .Deep(prefix, deeper, suffix, annotation):
            return FingerTree.Deep(
                prefix: try! prefix.preface(element),
                deeper: deeper,
                suffix: suffix,
                element.measure <> annotation
            )
        }
    }

    func append(element: Element) -> FingerTree {
        switch self {
        case .Empty:
            return FingerTree.Single(element)
        case let .Single(a):
            return FingerTree.Deep(
                prefix: Affix.One(a),
                deeper: FingerTree.Empty,
                suffix: Affix.One(element),
                a.measure <> element.measure
            )
        case let .Deep(prefix, deeper, .Four(a, b, c, d), annotation):
            return FingerTree.Deep(
                prefix: prefix,
                deeper: deeper.append(
                    Node.Branch3(a, b, c, a.measure <> b.measure <> c.measure)
                        .toElement
                ),
                suffix: Affix.Two(d, element),
                annotation <> element.measure
            )
        case let .Deep(prefix, deeper, suffix, annotation):
            return FingerTree.Deep(
                prefix: prefix,
                deeper: deeper,
                suffix: try! suffix.append(element),
                annotation <> element.measure
            )
        }
    }

    private static func nodes(array: [Element]) -> [Element]? {
        switch array.count {
        case 1:
            return nil
        case 2:
            let annotation = array[0].measure <> array[1].measure
            return [Node.Branch2(array[0], array[1], annotation).toElement]
        case 3:
            return [
                Node.Branch3(
                    array[0],
                    array[1],
                    array[2],
                    array[0].measure <> array[1].measure <> array[2].measure
                ).toElement
            ]
        default:
            var nodeArray = nodes(Array(array[0..<(array.count - 2)]))

            nodeArray!.append(
                Node.Branch2(
                    array[array.count - 2],
                    array[array.count - 1],
                    array[array.count - 2].measure
                        <> array[array.count - 1].measure
                ).toElement
            )
            return nodeArray
        }
    }

    static func concatenate<
        S: CollectionType where
        S.Index == Int, S.SubSequence == ArraySlice<Element>,
        S.Generator.Element == Element
    >(middle middle: S, left: FingerTree, right: FingerTree) -> FingerTree {
        switch (middle, left, right) {
        case (_, .Empty, _) where middle.isEmpty:
            return right

        case (_, _, .Empty) where middle.isEmpty:
            return left

        case (_, .Empty, _):
            return concatenate(
                middle: middle[1..<middle.count],
                left: FingerTree.Empty,
                right: right
            ).preface(middle.first!)

        case (_, _, .Empty):
            return concatenate(
                middle: middle[0..<(middle.count - 1)],
                left: left,
                right: FingerTree.Empty
            ).append(middle.last!)

        case let (_, .Single(a), _):
            return concatenate(
                middle: middle,
                left: FingerTree.Empty,
                right: right
            ).preface(a)

        case let (_, _, .Single(a)):
            return concatenate(
                middle: middle,
                left: left,
                right: FingerTree.Empty
            ).append(a)

        case let (
            _,
            .Deep(leftPrefix, leftDeeper, leftSuffix, leftAnnotation),
            .Deep(rightPrefix, rightDeeper, rightSuffix, rightAnnotation)
        ):

            let middle = Array(leftSuffix.generate())
            return FingerTree.Deep(
                prefix: leftPrefix,
                deeper: FingerTree.concatenate(
                    middle: nodes(
                        leftSuffix.toArray + middle + rightPrefix.toArray
                    )!,
                    left: leftDeeper,
                    right: rightDeeper
                ),
                suffix: rightSuffix,
                leftAnnotation <> rightAnnotation
            )

        default:
            // All cases have actually been exhausted.
            // Remove when the compiler is smarter about this.
            return FingerTree.Empty
        }
    }

    func extend(tree: FingerTree) -> FingerTree {
        return FingerTree.concatenate(middle: [], left: self, right: tree)
    }

    var measure: TAnnotation {
        switch self {
        case .Empty:
            return TAnnotation.identity
        case let .Single(a):
            return a.measure
        case let .Deep(_, _, _, annotation):
            return annotation
        }
    }

    func generate() -> AnyGenerator<Element> {
        switch self {
        case .Empty:
            return AnyGenerator(EmptyGenerator())
        case let .Single(a):
            return AnyGenerator(GeneratorOfOne(a))
        case let .Deep(prefix, deeper, suffix, _):
            var (prefixGen, deeperGen, suffixGen) = (
                prefix.generate(),
                deeper.generate(),
                suffix.generate()
            )

            var nodeGen = deeperGen.next()?.node!.generate()

            return AnyGenerator {
                if let value = prefixGen.next() {
                    return value
                }

                repeat {
                    if let value = nodeGen?.next() {
                        return value
                    }

                    nodeGen = deeperGen.next()?.node!.generate()
                } while nodeGen != nil

                if let value = suffixGen.next() {
                    return value
                }

                return nil
            }
        }
    }

    func reverse() -> AnyGenerator<Element> {
        switch self {
        case .Empty:
            return AnyGenerator(EmptyGenerator())
        case let .Single(a):
            return AnyGenerator(GeneratorOfOne(a))
        case let .Deep(prefix, deeper, suffix, _):
            var (prefixGen, deeperGen, suffixGen) = (
                prefix.reverse().generate(),
                deeper.reverse(),
                suffix.reverse().generate()
            )

            var nodeGen = deeperGen.next()?.node!.generate()

            return AnyGenerator {
                if let value = suffixGen.next() {
                    return value
                }

                repeat {
                    if let value = nodeGen?.next() {
                        return value
                    }

                    nodeGen = deeperGen.next()?.node!.generate()
                } while nodeGen != nil


                return prefixGen.next()
            }
        }
    }
}
