//
//  Box.swift
//  Pipeline
//

import Foundation

//  MARK: - Pipe Box
//  These three classes serve the purpose of type erasure for Pipe objects.

private class _AnyPipeBase<Input, Output>: Pipe {
    init() {
        guard type(of: self) != _AnyPipeBase.self else {
            fatalError("_AnyPipeBase<Input, Output> instances can not be created; create a subclass instance instead")
        }
    }
    func begin(with input: Input, completion: @escaping PipeCompletion) {
        fatalError("Must override")
    }
}

private final class _AnyPipeBox<Concrete: Pipe>: _AnyPipeBase<Concrete.Input, Concrete.Output> {
    var concrete: Concrete
    init(_ concrete: Concrete) {
        self.concrete = concrete
    }
    
    override func begin(with input: Concrete.Input, completion: @escaping PipeCompletion) {
        self.concrete.begin(with: input, completion: completion)
    }
}

final class AnyPipe<Input, Output>: Pipe {
    private let box: _AnyPipeBase<Input, Output>
    
    init<Concrete: Pipe>(_ concrete: Concrete) where Concrete.Input == Input, Concrete.Output == Output {
        box = _AnyPipeBox(concrete)
    }
    
    func begin(with input: Input, completion: @escaping PipeCompletion) {
        box.begin(with: input, completion: completion)
    }
}

//  MARK: - Joint
//  Joint creates a new pipe from two pipes, whose input matches the first, and
//  output matches the second.

final class Joint<Input, Mutual, Output>: Pipe {
    private let first: _AnyPipeBase<Input, Mutual>
    private let second: _AnyPipeBase<Mutual, Output>
    
    init<First: Pipe, Second: Pipe>(first: First, second: Second) where First.Input == Input, First.Output == Mutual, Second.Input == Mutual, Second.Output == Output {
        self.first = _AnyPipeBox(first)
        self.second = _AnyPipeBox(second)
    }
    
    func begin(with input: Input, completion: @escaping PipeCompletion) {
        first.begin(with: input) { (result) in
            switch result {
            case let .success(output): self.second.begin(with: output, completion: completion)
            case let .failure(error): completion(.failure(error))
            }
        }
    }
}

func join<F: Pipe, S: Pipe>(_ first: F, with second: S) -> Joint<F.Input, F.Output, S.Output> where F.Output == S.Input {
    return Joint(first: first, second: second)
}

func +<F: Pipe, S: Pipe>(lhs: F, rhs: S) -> Joint<F.Input, F.Output, S.Output> where F.Output == S.Input {
    return join(lhs, with: rhs)
}
