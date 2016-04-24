//
//  HttpRequest.swift
//  HttpRequest
//
//  Created by Kok Chung Law on 22/4/16.
//  Copyright © 2016 Lomotif Private Limited. All rights reserved.
//

import Foundation
import Alamofire
import XCGLogger

// MARK: - typealias
public typealias HttpHeaders = [String: String]
public typealias HttpBody = [String: AnyObject]
public typealias Request = Alamofire.Request
public typealias Method = Alamofire.Method
public typealias URLStringConvertible = Alamofire.URLStringConvertible

// XCGLogger
let log: XCGLogger = {
    let instance = XCGLogger.defaultInstance()
    instance.xcodeColorsEnabled = true // Or set the XcodeColors environment variable in your scheme to YES
    instance.xcodeColors = [
        .Verbose: .lightGrey,
        .Debug: .darkGrey,
        .Info: .darkGreen,
        .Warning: .orange,
        .Error: XCGLogger.XcodeColor(fg: UIColor.redColor()), // Optionally use a UIColor
        .Severe: XCGLogger.XcodeColor(fg: (255, 255, 255), bg: (255, 0, 0)) // Optionally use RGB values directly
    ]
    return instance
}()

// MARK: - HttpRequest which handles all the http request call
public class HttpRequest: NSObject {
    
    // MARK: - Properties
    public var authorizationHeaders: HttpHeaders = [:]
    public var agentHeaders: HttpHeaders = [:]
    public var refererHeaders: HttpHeaders = [:]
    public var alamofireManager: Manager!
    public var timeoutInterval: NSTimeInterval = 30 {
        didSet {
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            configuration.timeoutIntervalForRequest = self.timeoutInterval
            self.alamofireManager = Alamofire.Manager(configuration: configuration)
        }
    }
    
    // MARK: - Functions
    /**
     HttpRequest shared instance
     */
    public class func sharedInstance() -> HttpRequest {
        struct Singleton {
            static let instance = HttpRequest()
        }
        return Singleton.instance
    }
    
    /**
     Set client authorization headers
     */
    public class func setAuthorizationHeader(headers: HttpHeaders) {
        sharedInstance().authorizationHeaders = headers
    }
    
    /**
     Set client agent headers headers
     */
    public class func setAgentHeader(headers: HttpHeaders) {
        sharedInstance().agentHeaders = headers
    }
    
    /**
     Set client agent headers headers
     */
    public class func setRefererHeader(headers: HttpHeaders) {
        sharedInstance().refererHeaders = headers
    }
    
    /**
     Make http request
     
     - parameter method: Request method
     - parameter URLString: Request url
     - parameter headers: Request body
     - parameter body: Request body
     - parameter requiredAuthorization: Is the request call authenticated? Default value is false
     - returns: A request instance
     */
    public class func request(method: Method = .GET, _ URLString: URLStringConvertible, headers: HttpHeaders? = nil, body: HttpBody? = nil, requiredAuthorization: Bool = false) -> Request {
        let encoding = method == .GET ? ParameterEncoding.URL : ParameterEncoding.JSON
        var requestHeaders: HttpHeaders = self.buildRequestHeader(requiredAuthorization)
        requestHeaders.append(headers)
        log.debug("Url: \(URLString), Method: \(method) \nHeader: \(requestHeaders)\nParameters: \(body)")
        return sharedInstance().alamofireManager.request(method, URLString, parameters: body, encoding: encoding, headers: requestHeaders)
    }
    
    /**
     Make GET request with url, headers and body
     
     - parameter URLString: Request url
     - parameter headers: Request body
     - parameter body: Request body
     - parameter requiredAuthorization: Is the request call authenticated? Default value is false
     - returns: A request instance
     */
    public class func GET(URLString: URLStringConvertible, headers: HttpHeaders? = nil, body: HttpBody? = nil, requiredAuthorization: Bool = false) -> Request {
        return request(.GET, URLString, body: body, headers: headers, requiredAuthorization: requiredAuthorization)
    }
    
    /**
     Make POST request with url, headers and body
     
     - parameter URLString: Request url
     - parameter headers: Request body
     - parameter body: Request body
     - parameter requiredAuthorization: Is the request call authenticated? Default value is false
     - returns: A request instance
     */
    public class func POST(URLString: URLStringConvertible, headers: HttpHeaders? = nil, body: HttpBody? = nil, requiredAuthorization: Bool = false) -> Request {
        return request(.POST, URLString, body: body, headers: headers, requiredAuthorization: requiredAuthorization)
    }
    
    /**
     Make PUT request with url, headers and body
     
     - parameter URLString: Request url
     - parameter headers: Request body
     - parameter body: Request body
     - parameter requiredAuthorization: Is the request call authenticated? Default value is false
     - returns: A request instance
     */
    public class func PUT(URLString: URLStringConvertible, headers: HttpHeaders? = nil, body: HttpBody? = nil, requiredAuthorization: Bool = false) -> Request {
        return request(.PUT, URLString, body: body, headers: headers, requiredAuthorization: requiredAuthorization)
    }
    
    /**
     Make DELETE request with url, headers and body
     
     - parameter URLString: Request url
     - parameter headers: Request body
     - parameter body: Request body
     - parameter requiredAuthorization: Is the request call authenticated? Default value is false
     - returns: A request instance
     */
    public class func DELETE(URLString: URLStringConvertible, headers: HttpHeaders? = nil, body: HttpBody? = nil, requiredAuthorization: Bool = false) -> Request {
        return request(.DELETE, URLString, body: body, headers: headers, requiredAuthorization: requiredAuthorization)
    }
    
    /**
     Build request headers to be used for http request
     
     - parameter requiredAuthorization: Is the request call authenticated? Default value is false
     - returns: The request headers
     */
    class func buildRequestHeader(requiredAuthorization: Bool) -> HttpHeaders {
        var requestHeaders: HttpHeaders!
        if requiredAuthorization {
            requestHeaders = sharedInstance().authorizationHeaders
            requestHeaders.append(sharedInstance().agentHeaders)
            requestHeaders.append(sharedInstance().refererHeaders)
        } else {
            requestHeaders = sharedInstance().agentHeaders
            requestHeaders.append(sharedInstance().refererHeaders)
        }
        return requestHeaders
    }
    
}
