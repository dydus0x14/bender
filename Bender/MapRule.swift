//
//  MapRule.swift
//  Bender
//
//  Created by Anton Davydov on 23.09.18.
//  Original work Copyright © 2018 Evgenii Kamyshanov
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
 Validator for dictionaries with unknown keys like { "<id1>": value1, "<id2>": value2 }
 Output structure is array of objects. Item's order is not guarantee.
 This rule provides a way to bind keys to items via 'validateKey' and 'dumpKey' closures.
 */
public class MapRule<R: Rule>: Rule {
    public typealias V = [R.V]
    public typealias ValidateKeyType = (inout R.V, String) throws ->Void
    public typealias DumpKeyType = (R.V) throws ->String
    private let itemRule: R
    private let validateKey: ValidateKeyType
    private let dumpKey: DumpKeyType
    
    public init(itemRule: R, validateKey: @escaping ValidateKeyType, dumpKey: @escaping DumpKeyType) {
        self.itemRule = itemRule
        self.validateKey = validateKey
        self.dumpKey = dumpKey
    }
    
    public func validate(_ jsonValue: AnyObject) throws -> V {
        guard let dictionary = jsonValue as? [String: AnyObject] else {
            throw RuleError.invalidJSONType("Cannot validate \(jsonValue): expected dictionary of items", nil)
        }
        
        var result = [R.V]()
        for (key, value) in dictionary {
            var item = try itemRule.validate(value)
            try validateKey(&item, key)
            result.append(item)
        }
        
        return result
    }
    
    public func dump(_ value: V) throws -> AnyObject {
        var result = [String: AnyObject]()
        
        for item in value {
            let key = try dumpKey(item)
            let value = try itemRule.dump(item)
            result[key] = value
        }
        
        return result as AnyObject
    }
}
