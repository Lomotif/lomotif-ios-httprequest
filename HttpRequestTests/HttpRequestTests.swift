//
//  HttpRequestTests.swift
//  HttpRequestTests
//
//  Created by Kok Chung Law on 22/4/16.
//  Copyright © 2016 Lomotif Private Limited. All rights reserved.
//

import XCTest
@testable import HttpRequest

class HttpRequestTests: XCTestCase {
    
    func testTimeout() {
        HttpRequest.GET("www.google.com").timeout { () -> Void in
        }
    }
    
}
