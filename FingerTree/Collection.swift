// Collection.swift
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

public struct ImmutableCollection<T>: CollectionType {
    public typealias Index = Int

    private let tree: FingerTree<Value<T>, Size>

    init(_ tree: FingerTree<Value<T>, Size> = FingerTree()) {
        self.tree = tree
    }

    public let startIndex: Int = 0

    public var endIndex: Int {
        return tree.measure.value
    }

    public subscript(position: Int) -> T {
        let split = try! Split.split(
            predicate: {$0.value > position && position >= 0},
            startAnnotation: Size.identity,
            tree: self.tree
        )
        return split.element.value
    }
}

public struct PriorityQueue<T> {
    
}