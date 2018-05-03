//
//  PipelineTests.swift
//  PipelineTests
//
//  Created by Bradford Dillon on 4/27/18.
//  Copyright © 2018 Possible Mobile. All rights reserved.
//

import XCTest
@testable import Pipeline

class PipelineTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSuccess() {
    }
    
    func testURLFailure() {
    }
    
    func testOperations() {
        let exp = XCTestExpectation(description: "Test pipeline")

        let a = PipeOperation(CreateURLRequest())
        let b = PipeOperation(FetchData())
        let c = PipeOperation(ProcessMessages())
        let d = PipeOperation(ConcatenateMessages())
        let e = PipeOperation(BlockPipe { (input, completion) in
            completion(Result.success(input + "!"))
        })
        
        let pipeline = a.into(b).into(c).into(d).into(e)

        pipeline.head.completionBlock = {
            guard let output = pipeline.head.output else { XCTFail() ; return }
            switch output {
            case let .success(message):
                XCTAssertEqual(message, "Hello World!!")
            case let .failure(error):
                XCTFail("\(error)")
            }
            
            exp.fulfill()
        }
        
        a.input = "http://data-live.s3.amazonaws.com/pipeline-test.json"
        
        
        let queue = OperationQueue()
        queue.addOperations(pipeline.tail, waitUntilFinished: false)
        
        wait(for: [exp], timeout: 5)
    }
    
    func testCancellationBeforeStart() {
        let exp = XCTestExpectation(description: "Test pipeline")
        
        let a = PipeOperation(CreateURLRequest())
        let b = PipeOperation(FetchData())
        let c = PipeOperation(ProcessMessages())
        
        let pipeline = a.into(b).into(c)
        
        pipeline.head.completionBlock = {
            guard let output = pipeline.head.output else { XCTFail() ; return }
            switch output {
            case .success(_):
                XCTFail()
            case let .failure(error):
                if case PipeOperationError.cancelled = error {
                    // Success
                }
                else {
                    XCTFail()
                }
            }
            
            exp.fulfill()
        }
        
        a.input = "http://data-live.s3.amazonaws.com/pipeline-test.json"
        
        let queue = OperationQueue()
        queue.addOperations(pipeline.tail, waitUntilFinished: false)

        b.cancel()

        wait(for: [exp], timeout: 5)
    }
    
    func testErrorPropagation() {
        let exp = XCTestExpectation(description: "Test pipeline")
        
        let a = PipeOperation(AppendsFoo())
        let b = PipeOperation(AppendsFoo())
        let c = PipeOperation(FailsEveryTime())
        let d = PipeOperation(AppendsFoo())
        let e = PipeOperation(AppendsFoo())
        
        let pipeline = a.into(b).into(c).into(d).into(e)
        
        pipeline.head.completionBlock = {
            guard let output = pipeline.head.output else { XCTFail() ; return }
            switch output {
            case .success(_):
                XCTFail()
            case let .failure(error):
                if case FailsEveryTime.FailsEveryTimeError.allDayEveryDay = error {
                    // Success
                }
                else {
                    XCTFail()
                }
            }
            
            exp.fulfill()
        }
        
        a.input = ""
        
        let queue = OperationQueue()
        queue.addOperations(pipeline.tail, waitUntilFinished: false)
        
        wait(for: [exp], timeout: 5)

    }
}
