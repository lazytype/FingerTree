


enum Node<A> {
    case Branch2(
        @autoclosure () -> A,
        @autoclosure () -> A
    )
    case Branch3(
        @autoclosure () -> A,
        @autoclosure () -> A,
        @autoclosure () -> A
    )
}


enum Affix<A> {
    case One(
        @autoclosure () -> A
    )
    case Two(
        @autoclosure () -> A,
        @autoclosure () -> A
    )
    case Three(
        @autoclosure () -> A,
        @autoclosure () -> A,
        @autoclosure () -> A
    )
    case Four(
        @autoclosure () -> A,
        @autoclosure () -> A,
        @autoclosure () -> A,
        @autoclosure () -> A
    )

    func prepend(element: A) -> Affix? {
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

    func append(element: A) -> Affix? {
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

    var viewFirst: (A, Affix<A>?) {
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

    var viewLast: (Affix<A>?, A) {
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

    var toArray: [A] {
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


enum FingerTree<A> {
    case Empty
    case Single(@autoclosure () -> A)
    case Deep(
        prefix: Affix<A>,
        deeper: @autoclosure () -> FingerTree<Node<A>>,
        suffix: Affix<A>
    )

    func prepend(element: A) -> FingerTree<A> {
        switch self {
        case .Empty:
            return Single(element)
        case .Single(let a):
            return Deep(
                prefix: Affix.One(element),
                deeper: FingerTree<Node<A>>.Empty,
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

    func append(element: A) -> FingerTree<A> {
        switch self {
        case .Empty:
            return Single(element)
        case .Single(let a):
            return Deep(
                prefix: Affix.One(a),
                deeper: FingerTree<Node<A>>.Empty,
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

    private static func nodes(array: [A]) -> [Node<A>]? {
        if array.count <= 1 {
            return nil
        } else if array.count == 2 {
            return [Node<A>.Branch2(array[0], array[1])]
        } else if array.count == 3 {
            return [Node<A>.Branch3(array[0], array[1], array[2])]
        } else {
            var nodeArray = nodes(Array(array[0..<(array.count - 2)]))
            nodeArray!.append(Node<A>.Branch2(
                array[array.count - 2],
                array[array.count - 1]
                ))
            return nodeArray
        }
    }

    private static func joinTwo(
        joiner: [A] = [],
        left: FingerTree<A>,
        right: FingerTree<A>
    ) -> FingerTree<A> {

        switch (joiner, left, right) {
        case (_, .Empty, _) where joiner.isEmpty:
            return right

        case (_, _, .Empty) where joiner.isEmpty:
            return left

        case (_, .Empty, _):
            return joinTwo(
                joiner: Array(joiner[1..<joiner.count]),
                left: FingerTree<A>.Empty,
                right: right
            ).prepend(joiner.first!)

        case (_, _, .Empty):
            return joinTwo(
                joiner: Array(joiner[0..<(joiner.count - 1)]),
                left: left,
                right: FingerTree<A>.Empty
            ).append(joiner.last!)

        case (_, .Single(let a), _):
            return joinTwo(
                joiner: joiner,
                left: FingerTree<A>.Empty,
                right: right
            ).prepend(a())

        case (_, _, .Single(let a)):
            return joinTwo(
                joiner: joiner,
                left: left,
                right: FingerTree<A>.Empty
            ).append(a())

        case (
            _,
            .Deep(let leftPrefix, let leftDeeper, let leftSuffix),
            .Deep(let rightPrefix, let rightDeeper, let rightSuffix)
        ):
            return FingerTree<A>.Deep(
                prefix: leftPrefix,
                deeper: FingerTree<Node<A>>.joinTwo(
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
        sequence: [A] = [],
        trees: FingerTree<A>...
    ) -> FingerTree<A> {

        return trees.reduce(
            FingerTree.Empty,
            {FingerTree.joinTwo(left: $0, right: $1)}
        )
    }

    func extend(tree: FingerTree<A>) -> FingerTree<A> {
        return FingerTree<A>.join(trees: self, tree)
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


enum TreeView<A> {
    case Nil
    case View(
        element: @autoclosure () -> A,
        rest: FingerTree<A>
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

