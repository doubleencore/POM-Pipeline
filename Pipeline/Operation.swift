//
//  Operation.swift
//  Pipeline
//
//  Created by Bradford Dillon on 4/28/18.
//  Copyright © 2018 Possible Mobile. All rights reserved.
//

import Foundation

class PipeOperation<I, O>: AsynchronousOperation {
    enum PipeOperationError: Error {
        case noInput
    }
    
    var pipe: AnyPipe<I, O>
    init<P: Pipe>(_ pipe: P) where P.Input == I, P.Output == O {
        self.pipe = AnyPipe(pipe)
    }
    
    var input: I?
    var output: Result<O>?
    
    override func execute() {
        guard let input = input else { output = .failure(PipeOperationError.noInput) ; return }
        
        pipe.begin(with: input) { (output) in
            self.output = output
            self.finish()
        }
    }
    
    
}

class JointOperation<I, M, O>: AsynchronousOperation {
    enum JointOperationError: Error {
        case noOutputFromLeftOperation
    }
    
    typealias PipeA = PipeOperation<I, M>
    typealias PipeB = PipeOperation<M, O>
    
    var a: PipeA
    var b: PipeB
    var output: Result<M>? // Type is M because we'll really only be reporting errors from the first op here.
    
    init(joining a: PipeA, with b: PipeB) {
        self.a = a
        self.b = b
        
        super.init()
        
        self.addDependency(a)
        b.addDependency(self)
    }
    
    override func execute() {
        guard let output = a.output else { fatalError("This should be a Result.failure(error) instead") }
        
        switch output {
        case let .success(nextInput):
            b.input = nextInput
        case .failure(_):
            self.output = output
        }
        
        self.finish()
    }
    
    // TODO: All the operation state stuff to make it actually work correctly.
}

// What I want to do but can't...
//extension OperationQueue {
//    func addPipeOperations(_ ops: PipeOperation...) {
//
//    }
//}








// via https://gist.github.com/calebd/93fa347397cec5f88233
// TODO: Rewrite this. Or not?
open class AsynchronousOperation: Operation {
    
    // MARK: - Properties
    private let stateQueue = DispatchQueue(
        label: "com.pipe.operation.state",
        attributes: .concurrent)
    
    private var rawState = OperationState.ready
    
    @objc private dynamic var state: OperationState {
        get {
            return stateQueue.sync(execute: { rawState })
        }
        set {
            willChangeValue(forKey: "state")
            stateQueue.sync(
                flags: .barrier,
                execute: { rawState = newValue })
            didChangeValue(forKey: "state")
        }
    }
    
    public final override var isReady: Bool {
        return state == .ready && super.isReady
    }
    
    public final override var isExecuting: Bool {
        return state == .executing
    }
    
    public final override var isFinished: Bool {
        return state == .finished
    }
    
    public final override var isAsynchronous: Bool {
        return true
    }
    
    
    // MARK: - NSObject
    @objc private dynamic class func keyPathsForValuesAffectingIsReady() -> Set<String> {
        return ["state"]
    }
    
    @objc private dynamic class func keyPathsForValuesAffectingIsExecuting() -> Set<String> {
        return ["state"]
    }
    
    @objc private dynamic class func keyPathsForValuesAffectingIsFinished() -> Set<String> {
        return ["state"]
    }
    
    
    // MARK: - Foundation.Operation
    public override final func start() {
        super.start()
        
        if isCancelled {
            finish()
            return
        }
        
        state = .executing
        execute()
    }
    
    
    // MARK: - Public
    /// Subclasses must implement this to perform their work and they must not
    /// call `super`. The default implementation of this function throws an
    /// exception.
    open func execute() {
        fatalError("Subclasses must implement `execute`.")
    }
    
    /// Call this function after any work is done or after a call to `cancel()`
    /// to move the operation into a completed state.
    public final func finish() {
        state = .finished
    }
}

@objc private enum OperationState: Int {
    case ready
    case executing
    case finished
}

