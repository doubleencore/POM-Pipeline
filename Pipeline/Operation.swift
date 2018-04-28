//
//  Operation.swift
//  Pipeline
//
//  Created by Bradford Dillon on 4/28/18.
//  Copyright © 2018 Possible Mobile. All rights reserved.
//

import Foundation

class PipeOperation<I, O>: Operation {
    enum PipeOperationError: Error {
        case noInput
    }
    
    var pipe: AnyPipe<I, O>
    init<P: Pipe>(_ pipe: P) where P.Input == I, P.Output == O {
        self.pipe = AnyPipe(pipe)
    }
    
    var input: I?
    var output: Result<O>?
    
    override func start() {
        guard let input = input else { output = .failure(PipeOperationError.noInput) ; return }
        
        pipe.begin(with: input) { (output) in
            self.output = output
        }
    }
    
    // TODO: All the operation state stuff to make it actually work correctly.
}

class JointOperation<I, M, O>: Operation {
    enum JointOperationError: Error {
        case noOutputFromLeftOperation
    }
    
    typealias PipeA = PipeOperation<I, M>
    typealias PipeB = PipeOperation<M, O>
    
    var a: PipeA
    var b: PipeB
    var output: Result<M>? // Type is M because we'll really only be reporting errors from the first op here.
    
    var execute: (() -> ())?
    init(joining a: PipeA, with b: PipeB) {
        self.a = a
        self.b = b
        
        super.init()
        
        self.addDependency(a)
        b.addDependency(self)
    }
    
    override func start() {
        guard let output = a.output else { fatalError("This should be a Result.failure(error) instead") }
        
        switch output {
        case let .success(nextInput):
            b.input = nextInput
        case .failure(_):
            self.output = output
        }
    }
    
    // TODO: All the operation state stuff to make it actually work correctly.
}

// What I want to do but can't...
//extension OperationQueue {
//    func addPipeOperations(_ ops: PipeOperation...) {
//
//    }
//}
