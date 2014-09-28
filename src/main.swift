import Foundation


protocol ActualAnyProtocol:
    BooleanLiteralConvertible, StringLiteralConvertible,
    IntegerLiteralConvertible, FloatLiteralConvertible,
    ArrayLiteralConvertible, DictionaryLiteralConvertible {}

public class ActualAny: ActualAnyProtocol, Printable {
    let constant: Any

    public required init(_ constant: Any) {
        self.constant = constant
    }

    public var description: String {
        return "\(self.constant)"
    }

    public class func convertFromBooleanLiteral(value: Bool) -> Self {
        return self(value)
    }

    public class func convertFromStringLiteral(value: String) -> Self {
        return self(value)
    }

    public class func convertFromExtendedGraphemeClusterLiteral(value: Character) -> Self {
        return self(String(value))
    }

    public class func convertFromUnicodeScalarLiteral(value: Character) -> Self {
        return self(String(value))
    }

    public class func convertFromIntegerLiteral(value: Int) -> Self {
        return self(value)
    }

    public class func convertFromFloatLiteral(value: Double) -> Self {
        return self(value)
    }

    public class func convertFromArrayLiteral(elements: AnyObject...) -> Self {
        return self(elements)
    }

    public class func convertFromDictionaryLiteral(elements: (NSObject, AnyObject)...) -> Self {
        var dictionary = [NSObject: AnyObject]()
        for (key, value) in elements {
            dictionary[key] = value
        }
        return self(dictionary)
    }
}

prefix operator * {}
prefix func *(n: Any) -> ActualAny {
    return ActualAny(n)
}

enum Node<A: ActualAny>: Printable {
    case Branch2(A, A)
    case Branch3(A, A, A)

    var toArray: [A] {
        switch self {
        case .Branch2(let a, let b):
            return [a, b]
        case .Branch3(let a, let b, let c):
            return [a, b, c]
        }
    }

    var description : String {
        switch self {
        case .Branch2(let a, let b):
            return "Branch2 \(a) \(b)"
        case .Branch3(let a, let b, let c):
            return "Branch3 \(a) \(b) \(c)"
        }
    }
}

enum Affix<A: ActualAny> {
    case One(A)
    case Two(A, A)
    case Three(A, A, A)
    case Four(A, A, A, A)

    var description : String {
        switch self {
        case .One(let a):
            return "One \(a)"
        case .Two(let a, let b):
            return "Two \(a) \(b)"
        case .Three(let a, let b, let c):
            return "Three \(a) \(b) \(c)"
        case .Four(let a, let b, let c, let d):
            return "Four \(a) \(b) \(c) \(d)"
        }
    }

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

    var toArray: [A] {
        switch self {
        case .One(let a):
            return [a]
        case .Two(let a, let b):
            return [a, b]
        case .Three(let a, let b, let c):
            return [a, b, c]
        case .Four(let a, let b, let c, let d):
            return [a, b, c, d]
        }
    }
}

class FingerTreePointer<A: ActualAny> {
    let tree: FingerTree<A>
    init(_ tree: FingerTree<A>) {
        self.tree = tree
    }
}

enum FingerTree<A: ActualAny>: Printable {
    case Empty
    case Single(A)
    case Deep(
        prefix: Affix<A>,
        deeper: FingerTreePointer<ActualAny>,
        suffix: Affix<A>
    )

    var pointer: FingerTreePointer<A> {
        return FingerTreePointer(self)
    }

    func prepend(element: A) -> FingerTree<A> {
        switch self {
        case .Empty:
            return Single(element)
        case .Single(let a):
            return Deep(
                prefix: Affix.One(element),
                deeper: FingerTree<ActualAny>.Empty.pointer,
                suffix: Affix.One(a)
            )
        case .Deep(.Four(let a, let b, let c, let d), let deeper, let suffix):
            return Deep(
                prefix: Affix.Two(element, a),
                deeper: deeper.tree.prepend(*Node.Branch3(b, c, d)).pointer,
                suffix: suffix
            )
        case .Deep(let prefix, let deeper, let suffix):
            return .Deep(
                prefix: prefix.prepend(element)!,
                deeper: deeper,
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
                deeper: FingerTree<ActualAny>.Empty.pointer,
                suffix: Affix.One(element)
            )
        case .Deep(let prefix, let deeper, .Four(let a, let b, let c, let d)):
            return Deep(
                prefix: prefix,
                deeper: deeper.tree.append(*Node.Branch3(a, b, c)).pointer,
                suffix: Affix.Two(d, element)
            )
        case .Deep(let prefix, let deeper, let suffix):
            return .Deep(
                prefix: prefix,
                deeper: deeper,
                suffix: suffix.append(element)!
            )
        }
    }

    var toArray: [A] {
        switch self {
        case .Empty:
            return []
        case .Single(let a):
            return [a]
        case .Deep(let prefix, let deeper, let suffix):
            return joinArrays([
                prefix.toArray,
                joinArrays(
                    map(deeper.tree.toArray as [ActualAny]) {
                        return ($0.constant as Node<A>).toArray
                    }
                ),
                suffix.toArray
            ])
        }
    }

    var description: String {
        return "\(self.toArray)"
    }
}

func joinArrays<A>(arrays: [[A]]) -> [A] {
    var joinedArray: [A] = []
    for array in arrays {
        joinedArray += array
    }
    return joinedArray
}