//
//  Sample.swift
//  PipelineTests
//
//  Created by Bradford Dillon on 4/27/18.
//  Copyright © 2018 Possible Mobile. All rights reserved.
//

import Foundation
import Pipeline

struct Message: Decodable {
    let objectID: Int
    let message: String
}

class CreateURLRequest: Pipeline.Pipe {
    enum URLPipeError: Error {
        case couldNotCreateRequest
    }
    
    typealias Input = String
    typealias Output = URLRequest
    
    func begin(with input: String, completion: @escaping ((Result<URLRequest>) -> Void)) -> CancelSignal? {
        if let url = URL(string: input) {
            let urlRequest = URLRequest(url: url)
            completion(.success(urlRequest))
        }
        else {
            completion(.failure(URLPipeError.couldNotCreateRequest))
        }
        
        return nil
    }
}

class FetchData: Pipeline.Pipe {
    enum FetchPipeError: Error {
        case noData
    }
    
    typealias Input = URLRequest
    typealias Output = Data
    
    var completion: ((Result<Data>) -> Void)?
    
    func begin(with input: URLRequest, completion: @escaping ((Result<Data>) -> Void)) -> CancelSignal? {
        self.completion = completion
        let task = URLSession.shared.dataTask(with: input) { (data, response, error) in
            self.finish(with: data, response: response, error: error)
            }
        
        task.resume()
        
        return {
            task.cancel()
        }
    }
    
    func finish(with data: Data?, response: URLResponse?, error: Error?) {
        if let error = error {
            completion?(.failure(error))
        }
        else if let data = data {
            completion?(.success(data))
        }
        else {
            completion?(.failure(FetchPipeError.noData))
        }
    }
}

class ProcessMessages: Pipeline.Pipe {
    typealias Input = Data
    typealias Output = [Message]
    
    func begin(with input: Data, completion: @escaping ((Result<[Message]>) -> Void)) -> CancelSignal? {
        do {
            let messages = try JSONDecoder().decode([Message].self, from: input)
            completion(.success(messages))
        }
        catch {
            completion(.failure(error))
        }
        
        return nil
    }
}

class ConcatenateMessages: Pipeline.Pipe {
    typealias Input = [Message]
    typealias Output = String
    
    func begin(with input: [Message], completion: @escaping ((Result<String>) -> Void)) -> CancelSignal? {
        let output = input.map { $0.message }.joined(separator: " ")
        completion(.success(output))
        
        return nil
    }
}

class AppendsFoo: Pipeline.Pipe {
    func begin(with input: String, completion: @escaping ((Result<String>) -> Void)) -> CancelSignal? {
        completion(.success(input + "Foo"))
        return nil
    }
}

class FailsEveryTime: Pipeline.Pipe {
    enum FailsEveryTimeError: Error {
        case allDayEveryDay
    }
    func begin(with input: String, completion: @escaping ((Result<String>) -> Void)) -> CancelSignal? {
        completion(.failure(FailsEveryTimeError.allDayEveryDay))
        return nil
    }
}
