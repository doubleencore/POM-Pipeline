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
        let exp = XCTestExpectation(description: "Test pipeline")

        let pipe = AnyPipe(CreateURLRequest()) + AnyPipe(FetchData()) + AnyPipe(ProcessMessages()) + AnyPipe(ConcatenateMessages())
        pipe.begin(with: "http://data-live.s3.amazonaws.com/pipeline-test.json") { (result) in
            switch result {
            case let .success(message):
                print("\(message)")
            case let .failure(error):
                XCTFail(error.localizedDescription)
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 10)
    }
    
    func testURLFailure() {
        let exp = XCTestExpectation(description: "Test pipeline")
        
        let pipe = AnyPipe(CreateURLRequest()) + AnyPipe(FetchData()) + AnyPipe(ProcessMessages()) + AnyPipe(ConcatenateMessages())
        pipe.begin(with: "Jimmy") { (result) in
            switch result {
            case .success(_):
                XCTFail("This should have failed")
            case .failure(_):
                break // success
                // TODO: Assert correct error type.
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 10)
    }
}


