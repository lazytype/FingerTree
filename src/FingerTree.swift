


enum Node<T> {
    case Branch2(
        @autoclosure () -> T,
        @autoclosure () -> T
    )
    case Branch3(
        @autoclosure () -> T,
        @autoclosure () -> T,
        @autoclosure () -> T
    )
}


enum Affix<T> {
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

    var viewFirst: (T, Affix<T>?) {
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

    var viewLast: (Affix<T>?, T) {
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

    static func fromNode<T>(node: @autoclosure () -> Node<T>) -> Affix<T> {
        switch node() {
        case .Branch2(let a, let b):
            return Affix<T>.Two(a, b)
        case .Branch3(let a, let b, let c):
            return Affix<T>.Three(a, b, c)
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
}


enum FingerTree<T> {
    case Empty
    case Single(@autoclosure () -> T)
    case Deep(
        prefix: Affix<T>,
        deeper: @autoclosure () -> FingerTree<Node<T>>,
        suffix: Affix<T>
    )

    func prepend(element: T) -> FingerTree<T> {
        switch self {
        case .Empty:
            return Single(element)
        case .Single(let a):
            return Deep(
                prefix: Affix.One(element),
                deeper: FingerTree<Node<T>>.Empty,
                suffix: Affix.One(a)
            )
        case .Deep(.Four(let a, let b, let c, let d), let deeper, let suffix):
            return Deep(
                prefix: Affix.Two(element, a),
                deeper: deeper().prepend(Node.Branch3(b, c, d)),
                suffix: suffix
            )
        case .Deep(let prefix, let deeper, let suffix):
            return Deep(
                prefix: prefix.prepend(element)!,
                deeper: deeper(),
                suffix: suffix
            )
        }
    }

    func append(element: T) -> FingerTree<T> {
        switch self {
        case .Empty:
            return Single(element)
        case .Single(let a):
            return Deep(
                prefix: Affix.One(a),
                deeper: FingerTree<Node<T>>.Empty,
                suffix: Affix.One(element)
            )
        case .Deep(let prefix, let deeper, .Four(let a, let b, let c, let d)):
            return Deep(
                prefix: prefix,
                deeper: deeper().append(Node.Branch3(a, b, c)),
                suffix: Affix.Two(d, element)
            )
        case .Deep(let prefix, let deeper, let suffix):
            return Deep(
                prefix: prefix,
                deeper: deeper,
                suffix: suffix.append(element)!
            )
        }
    }

    private static func nodes(array: [T]) -> [Node<T>]? {
        if array.count <= 1 {
            return nil
        } else if array.count == 2 {
            return [Node<T>.Branch2(array[0], array[1])]
        } else if array.count == 3 {
            return [Node<T>.Branch3(array[0], array[1], array[2])]
        } else {
            var nodeArray = nodes(Array(array[0..<(array.count - 2)]))
            nodeArray!.append(Node<T>.Branch2(
                array[array.count - 2],
                array[array.count - 1]
                ))
            return nodeArray
        }
    }

    private static func joinTwo(
        joiner: [T] = [],
        left: FingerTree<T>,
        right: FingerTree<T>
    ) -> FingerTree<T> {

        switch (joiner, left, right) {
        case (_, .Empty, _) where joiner.isEmpty:
            return right

        case (_, _, .Empty) where joiner.isEmpty:
            return left

        case (_, .Empty, _):
            return joinTwo(
                joiner: Array(joiner[1..<joiner.count]),
                left: FingerTree<T>.Empty,
                right: right
            ).prepend(joiner.first!)

        case (_, _, .Empty):
            return joinTwo(
                joiner: Array(joiner[0..<(joiner.count - 1)]),
                left: left,
                right: FingerTree<T>.Empty
            ).append(joiner.last!)

        case (_, .Single(let a), _):
            return joinTwo(
                joiner: joiner,
                left: FingerTree<T>.Empty,
                right: right
            ).prepend(a())

        case (_, _, .Single(let a)):
            return joinTwo(
                joiner: joiner,
                left: left,
                right: FingerTree<T>.Empty
            ).append(a())

        case (
            _,
            .Deep(let leftPrefix, let leftDeeper, let leftSuffix),
            .Deep(let rightPrefix, let rightDeeper, let rightSuffix)
        ):
            return FingerTree<T>.Deep(
                prefix: leftPrefix,
                deeper: FingerTree<Node<T>>.joinTwo(
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
        trees: FingerTree<T>...
    ) -> FingerTree<T> {

        return trees.reduce(
            FingerTree.Empty,
            {FingerTree.joinTwo(left: $0, right: $1)}
        )
    }

    func extend(tree: FingerTree<T>) -> FingerTree<T> {
        return FingerTree<T>.join(trees: self, tree)
    }

    static func fromAffix<T>(affix: Affix<T>) -> FingerTree<T> {
        switch affix {
        case .One(let a):
            return FingerTree<T>.Single(a)
        case .Two(let a, let b):
            return FingerTree<T>.Deep(
                prefix: Affix<T>.One(a),
                deeper: FingerTree<Node<T>>.Empty,
                suffix: Affix<T>.One(b)
            )
        case .Three(let a, let b, let c):
            return FingerTree<T>.Deep(
                prefix: Affix<T>.Two(a, b),
                deeper: FingerTree<Node<T>>.Empty,
                suffix: Affix<T>.One(c)
            )
        case .Four(let a, let b, let c, let d):
            return FingerTree<T>.Deep(
                prefix: Affix<T>.Two(a, b),
                deeper: FingerTree<Node<T>>.Empty,
                suffix: Affix<T>.Two(c, d)
            )
        }
    }
}


enum TreeView<T> {
    case Nil
    case View(
        element: @autoclosure () -> T,
        rest: FingerTree<T>
    )

    static func viewLeft<T>(
        tree: @autoclosure () -> FingerTree<T>
    ) -> TreeView<T> {

        switch tree() {
        case .Empty:
            return TreeView<T>.Nil
        case .Single(let a):
            return TreeView<T>.View(
                element: a,
                rest: FingerTree<T>.Empty
            )
        case .Deep(.One(let a), let deeper, let suffix):
            var rest: FingerTree<T>

            switch TreeView<Node<T>>.viewLeft(deeper) {
            case .View(let element, let deepRest):
                rest = FingerTree<T>.Deep(
                    prefix: Affix<T>.fromNode(element),
                    deeper: deepRest,
                    suffix: suffix
                )
            case .Nil:
                rest = FingerTree<T>.fromAffix(suffix)
            }

            return TreeView<T>.View(
                element: a,
                rest: rest
            )
        case .Deep(let prefix, let deeper, let suffix):
            let (first, rest) = prefix.viewFirst

            return TreeView<T>.View(
                element: first,
                rest: FingerTree<T>.Deep(
                    prefix: rest!,
                    deeper: deeper,
                    suffix: suffix
                )
            )
        }
    }

    static func viewRight<T>(
        tree: @autoclosure () -> FingerTree<T>
    ) -> TreeView<T> {

        switch tree() {
        case .Empty:
            return TreeView<T>.Nil
        case .Single(let a):
            return TreeView<T>.View(
                element: a,
                rest: FingerTree<T>.Empty
            )
        case .Deep(let prefix, let deeper, .One(let a)):
            var rest: FingerTree<T>

            switch TreeView<Node<T>>.viewRight(deeper) {
            case .View(let element, let deepRest):
                rest = FingerTree<T>.Deep(
                    prefix: prefix,
                    deeper: deepRest,
                    suffix: Affix<T>.fromNode(element)
                )
            case .Nil:
                rest = FingerTree<T>.fromAffix(prefix)
            }

            return TreeView<T>.View(
                element: a,
                rest: rest
            )
        case .Deep(let prefix, let deeper, let suffix):
            let (rest, last) = prefix.viewLast

            return TreeView<T>.View(
                element: last,
                rest: FingerTree<T>.Deep(
                    prefix: prefix,
                    deeper: deeper,
                    suffix: rest!
                )
            )
        }
    }
}

