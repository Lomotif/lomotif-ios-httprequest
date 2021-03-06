//
//  DictionaryExtension.swift
//  HttpRequest
//
//  Created by Kok Chung Law on 22/4/16.
//  Copyright © 2016 Lomotif Private Limited. All rights reserved.
//

import Foundation

public extension Dictionary {
    
    mutating func append(_ dictionary: Dictionary?) {
        if dictionary == nil {
            return
        }
        for (key, value) in dictionary! {
            self.updateValue(value, forKey: key)
        }
    }
    
}
