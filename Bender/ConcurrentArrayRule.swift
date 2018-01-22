//  ConcurrentArrayRule.swift
//  Bender
//
//  Created by Anton Davydov on 25/10/2017.
//  Original work Copyright © 2017 Anton Davydov
//
//  The MIT License (MIT)
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included
//  in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

/**
    Validator for arrays of items of type T, that should be validated by rule of type R, i.e. where R.V == T.
    This version of ArrayRule validates/dumps array items separately on background thread.
 */
public class ConcurrentArrayRule<T, R: Rule>: Rule where R.V == T {
    public typealias V = [T]
    public typealias InvalidItemHandler = (Int, Error)throws-> Void
    fileprivate let itemRule: R
    fileprivate let invalidItemHandler: InvalidItemHandler?
    
    /**
     Validator initializer
     
     - parameter itemRule: rule for validating array items of type R.V
     - parameter invalidItemHandler: handler closure which is called when the item cannnot be validated.
     Can throw is there is no need to keep checking. The handler is called on background thread.
     */
    public init(itemRule: R, invalidItemHandler: InvalidItemHandler? = nil) {
        self.itemRule = itemRule
        self.invalidItemHandler = invalidItemHandler
    }

    // MARK:- Rule
    /**
     Validates JSON array and returns [T] if succeeded. Validation throws if jsonValue is not a JSON array or if item rule throws for any item.
     
     - parameter jsonValue: JSON array to be validated and converted into [T]
     
     - throws: throws ValidateError
     
     - returns: array of objects of first generic parameter argument if validation was successful
     */
    open func validate(_ jsonValue: AnyObject) throws -> V {
        guard let jsonArray = jsonValue as? NSArray else {
            throw RuleError.invalidJSONType("Value of unexpected type found: \"\(jsonValue)\". Expected array of \(T.self).", nil)
        }
        
        return try self.validate(input: jsonArray)
    }

    /**
     Dumps array of AnyObject type in case of success. Throws if cannot dump any item in source array.
     
     - parameter value: array with items of type T
     
     - throws: throws RuleError if cannot dump any item in source array
     
     - returns: returns array of AnyObject, dumped by item rule
     */
    open func dump(_ value: V) throws -> AnyObject {
        return try self.dump(input: value)
    }
}

extension ConcurrentArrayRule {
    
    fileprivate func validate(input: NSArray) throws -> V {
        let operationQueue = DispatchQueue(label: "", qos: .userInteractive, attributes: .concurrent)
        let semaphore = DispatchSemaphore(value: 1)
        let dispatchGroups = [DispatchGroup].init(repeating: DispatchGroup(), count: input.count)
        var result = V()
        var resultError: Error?
        
        for (index, object) in input.enumerated() {
            dispatchGroups[index].enter()
            
            operationQueue.async {
                do {
                    let value = try self.itemRule.validate(object as AnyObject)
                    
                    semaphore.wait()
                    result.append(value)
                    semaphore.signal()
                } catch let error {
                    do {
                        try self.invalidItemHandler?(index, error)
                    } catch let itemHandlerError {
                        resultError = itemHandlerError
                    }
                }
                dispatchGroups[index].leave()
            }
        }
        
        dispatchGroups.forEach { $0.wait() }
        if let resultError = resultError {
            throw resultError
        }
        return result
    }
    
    fileprivate func dump(input: V) throws -> NSArray {
        let operationQueue = DispatchQueue(label: "", qos: .userInteractive, attributes: .concurrent)
        let semaphore = DispatchSemaphore(value: 1)
        let dispatchGroups = [DispatchGroup].init(repeating: DispatchGroup(), count: input.count)
        let result = NSMutableArray.init(capacity: input.count)
        var resultError: Error?
        
        for (index, object) in input.enumerated() {
            dispatchGroups[index].enter()
            
            operationQueue.async {
                do {
                    let value = try self.itemRule.dump(object)
                    
                    semaphore.wait()
                    result.adding(value)
                    semaphore.signal()
                } catch let error {
                    do {
                        try self.invalidItemHandler?(index, error)
                    } catch let itemHandlerError {
                        resultError = itemHandlerError
                    }
                }
                dispatchGroups[index].leave()
            }
        }
        
        dispatchGroups.forEach { $0.wait() }
        if let resultError = resultError {
            throw resultError
        }
        return result
    }
}
