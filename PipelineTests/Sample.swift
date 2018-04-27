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
    
    func begin(with input: String, completion: @escaping ((Result<URLRequest>) -> Void)) {
        if let url = URL(string: input) {
            let urlRequest = URLRequest(url: url)
            completion(.success(urlRequest))
        }
        else {
            completion(.failure(URLPipeError.couldNotCreateRequest))
        }
    }
}

class FetchData: Pipeline.Pipe {
    enum FetchPipeError: Error {
        case noData
    }
    
    typealias Input = URLRequest
    typealias Output = Data
    
    var completion: ((Result<Data>) -> Void)?
    
    func begin(with input: URLRequest, completion: @escaping ((Result<Data>) -> Void)) {
        self.completion = completion
        URLSession.shared.dataTask(with: input) { (data, response, error) in
            self.finish(with: data, response: response, error: error)
            }.resume()
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
    
    func begin(with input: Data, completion: @escaping ((Result<[Message]>) -> Void)) {
        do {
            let messages = try JSONDecoder().decode([Message].self, from: input)
            completion(.success(messages))
        }
        catch {
            completion(.failure(error))
        }
    }
}

class ConcatenateMessages: Pipeline.Pipe {
    typealias Input = [Message]
    typealias Output = String
    
    func begin(with input: [Message], completion: @escaping ((Result<String>) -> Void)) {
        let output = input.map { $0.message }.joined(separator: " ")
        completion(.success(output))
    }
}
