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
    @discardableResult func begin(with input: Input, completion: @escaping PipeCompletion) -> CancelSignal? {
        fatalError("Must override")
    }
}

private final class _AnyPipeBox<Concrete: Pipe>: _AnyPipeBase<Concrete.Input, Concrete.Output> {
    var concrete: Concrete
    init(_ concrete: Concrete) {
        self.concrete = concrete
    }
    
    override func begin(with input: Concrete.Input, completion: @escaping PipeCompletion) -> CancelSignal? {
        return self.concrete.begin(with: input, completion: completion)
    }
}

public final class AnyPipe<Input, Output>: Pipe {
    private let box: _AnyPipeBase<Input, Output>
    
    init<Concrete: Pipe>(_ concrete: Concrete) where Concrete.Input == Input, Concrete.Output == Output {
        box = _AnyPipeBox(concrete)
    }
    
    public func begin(with input: Input, completion: @escaping PipeCompletion) -> CancelSignal? {
        return box.begin(with: input, completion: completion)
    }
}
