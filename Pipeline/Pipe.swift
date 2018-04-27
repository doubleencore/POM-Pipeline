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
