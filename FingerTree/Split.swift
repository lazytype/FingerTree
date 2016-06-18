// Split.swift
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

enum SplitError: ErrorProtocol {
  case notFound
}

extension FingerTree {
  func split(
    predicate: (TAnnotation) -> Bool,
    startAnnotation: TAnnotation
  ) throws -> (FingerTree, FingerTree) {
    switch self {
    case .empty:
      break
    case .single:
      if predicate(startAnnotation <> measure) {
        return (FingerTree.empty, self)
      }
    case let .deep(prefix, deeper, suffix, _):
      if !predicate(startAnnotation <> measure) {
        throw SplitError.notFound
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
            left = affix.makeFingerTree()
          } else {
            left = FingerTree.empty
          }

          return (left, FingerTree.createDeep(prefix: after, deeper: deeper, suffix: suffix))
        }
      } else if predicate(startToPrefix <> deeper.measure) {
        let (left, right) = try! deeper.split(predicate: predicate, startAnnotation: startToPrefix)
        let (element, rest) = right.viewLeft!

        if let (beforeNode, afterNode) = FingerTree.splitList(
          predicate: predicate,
          startAnnotation: startToPrefix <> left.measure,
          values: element.node!.makeAffix()
        ) {
          return (
            FingerTree.createDeep(prefix: prefix, deeper: left, suffix: beforeNode),
            FingerTree.createDeep(prefix: afterNode, deeper: rest, suffix: suffix)
          )
        }
      } else if let (before, after) = FingerTree.splitList(
        predicate: predicate,
        startAnnotation: startToPrefix <> deeper.measure,
        values: suffix
      ) {
        return (
          FingerTree.createDeep(prefix: prefix, deeper: deeper, suffix: before),
          after.makeFingerTree()
        )
      }
    }

    throw SplitError.notFound
  }

  private static func splitList(
    predicate: (TAnnotation) -> Bool,
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
        return (Affix.one(first), after)
      }

      return (try! before!.preface(first), after)
    }

    return nil
  }
}
