//
//  Pipe.swift
//  Pipeline
//

import Foundation

public enum Result<T> {
    case success(T)
    case failure(Error)
}

//  MARK: - Pipe
//  Pipe defines the protocol of an object that takes an input and produces
//  (asynchronously) an output.

public protocol Pipe {
    associatedtype Input
    associatedtype Output
    
    typealias PipeCompletion = ((Result<Output>) -> Void)

    func begin(with input: Input, completion: @escaping PipeCompletion)
}

//  MARK: - Block Pipe
//  Single-use pipe that executes a provided closure. Similar to BlockOperation.

public final class BlockPipe<I, O>: Pipe {
    public typealias Input = I
    public typealias Output = O
    public typealias Block = ((I, @escaping PipeCompletion) -> Void)
    
    let block: Block
    init(_ block: @escaping Block) {
        self.block = block
    }
    
    public func begin(with input: I, completion: @escaping PipeCompletion) {
        block(input, completion)
    }
}
