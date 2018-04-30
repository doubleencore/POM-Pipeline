//
//  Operation.swift
//  Pipeline
//
//  Created by Bradford Dillon on 4/28/18.
//  Copyright © 2018 Possible Mobile. All rights reserved.
//

import Foundation

public class PipeOperation<I, O>: AsynchronousOperation {
    public enum PipeOperationError: Error {
        case noInput
    }
    
    var pipe: AnyPipe<I, O>
    public init<P: Pipe>(_ pipe: P) where P.Input == I, P.Output == O {
        self.pipe = AnyPipe(pipe)
    }
    
    // Should I be Result<I> to pass previous result in?
    // Result could have an additional state of .initial(T).
    public var input: I?
    public var output: Result<O>?
    
    public override func execute() {
        guard let input = input else { output = .failure(PipeOperationError.noInput) ; return }
        
        pipe.begin(with: input) { (output) in
            self.output = output
            self.finish()
        }
    }
    
    private var joint: (() -> ())?
    @discardableResult fileprivate func _join<O2>(_ other: PipeOperation<O, O2>) -> PipeOperation<O, O2> {
        other.addDependency(self)
        
        self.joint = { [weak self, weak other] in
            guard let weakSelf = self,
                let weakOther = other,
                let output = weakSelf.output else { return }
            
            if case let .success(nextInput) = output {
                weakOther.input = nextInput
            }
            
            // TODO: Failure of this operation (no output) will result in the next operation failing due to .noInput.
            // Maybe that's ok? Only if we aggregate errors instead of just reporting one.
            // Can't bubble up the originating error because of type mismatch, but aggregation should be fine.
        }
        
        return other
    }
    
    public final override func cleanUp() {
        self.joint?()
    }
}

protocol Joining {
    associatedtype O
    func into<O2>(_ next: PipeOperation<O, O2>) -> Pipeline<O, O2>
}

extension PipeOperation: Joining {
    @discardableResult func into<O2>(_ next: PipeOperation<O, O2>) -> Pipeline<O, O2> {
        self._join(next)
        return Pipeline(head: next, tail: [self, next])
    }
}

struct Pipeline<I, O>: Joining {
    let head: PipeOperation<I, O>
    let tail: [Operation]

    func into<O2>(_ next: PipeOperation<O, O2>) -> Pipeline<O, O2> {
        head.into(next)
        var newTail = tail
        newTail.append(next)
        return Pipeline<O, O2>(head: next, tail: newTail)
    }
}





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
    
    /// Provides an opportunity to clean anything up immediately before finish()
    open func cleanUp() {
    }
    
    /// Call this function after any work is done or after a call to `cancel()`
    /// to move the operation into a completed state.
    public final func finish() {
        cleanUp()
        state = .finished
    }
}

@objc private enum OperationState: Int {
    case ready
    case executing
    case finished
}

