// TreeView.swift
//
// Copyright (c) 2015-Present, Michael Mitchell
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software
// and associated documentation files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or 
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

extension FingerTree {
  var viewLeft: (Element, FingerTree)? {
    switch self {
    case .empty:
      return nil
    case let .single(a):
      return (a, FingerTree.empty)
    case let .deep(.one(a), deeper, suffix, _):
      let rest: FingerTree

      if let (element, deeperRest) = deeper.viewLeft {
        rest = FingerTree.deep(
          prefix: element.node!.makeAffix(),
          deeper: deeperRest,
          suffix: suffix,
          deeper.measure <> suffix.measure
        )
      } else {
        rest = suffix.makeFingerTree()
      }

      return (a, rest)

    case let .deep(prefix, deeper, suffix, _):
      let (first, rest) = prefix.viewFirst
      let annotation = rest!.measure <> deeper.measure <> suffix.measure
      return (first, FingerTree.deep(prefix: rest!, deeper: deeper, suffix: suffix, annotation))
    }
  }

  var viewRight: (FingerTree, Element)? {
    switch self {
    case .empty:
      return nil
    case let .single(a):
      return (FingerTree.empty, a)
    case let .deep(prefix, deeper, .one(a), _):
      let rest: FingerTree

      if let (deeperRest, element) = deeper.viewRight {
        rest = FingerTree.deep(
          prefix: prefix,
          deeper: deeperRest,
          suffix: element.node!.makeAffix(),
          prefix.measure <> deeper.measure
        )
      } else {
        rest = prefix.makeFingerTree()
      }

      return (rest, a)

    case let .deep(prefix, deeper, suffix, _):
      let (rest, last) = suffix.viewLast
      let annotation = prefix.measure <> deeper.measure <> rest!.measure
      return (FingerTree.deep(prefix: prefix, deeper: deeper, suffix: rest!, annotation), last)
    }
  }
}

extension Affix {
  func makeFingerTree() -> FingerTree<TValue, TAnnotation> {
    switch self {
    case let .one(a):
      return FingerTree.single(a)
    case let .two(a, b):
      return FingerTree.deep(
        prefix: Affix.one(a),
        deeper: FingerTree.empty,
        suffix: Affix.one(b),
        a.measure <> b.measure
      )
    case let .three(a, b, c):
      return FingerTree.deep(
        prefix: Affix.two(a, b),
        deeper: FingerTree.empty,
        suffix: Affix.one(c),
        a.measure <> b.measure <> c.measure
      )
    case let .four(a, b, c, d):
      return FingerTree.deep(
        prefix: Affix.two(a, b),
        deeper: FingerTree.empty,
        suffix: Affix.two(c, d),
        a.measure <> b.measure <> c.measure <> d.measure
      )
    }
  }
}

extension Node {
  func makeAffix() -> Affix<TValue, TAnnotation> {
    switch self {
    case let .branch2(a, b, _):
      return Affix.two(a, b)
    case let .branch3(a, b, c, _):
      return Affix.three(a, b, c)
    }
  }
}

extension FingerTree {
  static func createDeep(
    prefix: Affix<TValue, TAnnotation>?,
    deeper: FingerTree,
    suffix: Affix<TValue, TAnnotation>?
  ) -> FingerTree {
    if prefix == nil && suffix == nil {
      if let (element, rest) = deeper.viewLeft {
        return createDeep(prefix: element.node!.makeAffix(), deeper: rest, suffix: nil)
      } else {
        return FingerTree.empty
      }
    } else if prefix == nil {
      if let (rest, element) = deeper.viewRight {
        return createDeep(prefix: element.node!.makeAffix(), deeper: rest, suffix: suffix)
      } else {
        return suffix!.makeFingerTree()
      }
    } else if suffix == nil {
      if let (rest, element) = deeper.viewRight {
        return createDeep(prefix: prefix, deeper: rest, suffix: element.node!.makeAffix())
      } else {
        return prefix!.makeFingerTree()
      }
    } else {
      let annotation = prefix!.measure <> deeper.measure <> suffix!.measure
      return FingerTree.deep(prefix: prefix!, deeper: deeper, suffix: suffix!, annotation)
    }
  }
}
