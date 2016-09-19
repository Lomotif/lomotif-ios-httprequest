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
public typealias Method = Alamofire.HTTPMethod
public typealias URLConvertible = Alamofire.URLConvertible
public typealias URLRequestConvertible = Alamofire.URLRequestConvertible

// XCGLogger
let log: XCGLogger = {
    let instance = XCGLogger.default
// Plug-ins do not work in Xcode 8
//    instance.xcodeColorsEnabled = true // Or set the XcodeColors environment variable in your scheme to YES
//    instance.xcodeColors = [
//        .verbose: .lightGrey,
//        .debug: .darkGrey,
//        .info: .darkGreen,
//        .warning: .orange,
//        .error: XCGLogger.XcodeColor(fg: UIColor.red), // Optionally use a UIColor
//        .severe: XCGLogger.XcodeColor(fg: (255, 255, 255), bg: (255, 0, 0)) // Optionally use RGB values directly
//    ]
    return instance
}()

// MARK: - HttpRequest which handles all the http request call
open class HttpRequest: NSObject {
    
    // MARK: - Properties
    open var authorizationHeaders: HttpHeaders = [:]
    open var agentHeaders: HttpHeaders = [:]
    open var refererHeaders: HttpHeaders = [:]
    open var alamofireManager: SessionManager!
    open var timeoutInterval: TimeInterval = 30 {
        didSet {
            alamofireManager = Alamofire.SessionManager(configuration: HttpRequest.configurationWithTimeoutInterval(timeoutInterval))
        }
    }
    
    // MARK: - Initializer
    public override init() {
        super.init()
        alamofireManager = Alamofire.SessionManager(configuration: HttpRequest.configurationWithTimeoutInterval(timeoutInterval))
    }
    
    // MARK: - Functions
    /**
     HttpRequest shared instance
     */
    open class func sharedInstance() -> HttpRequest {
        struct Singleton {
            static let instance = HttpRequest()
        }
        return Singleton.instance
    }
    
    /**
     Set client authorization headers
     */
    open class func setAuthorizationHeader(_ headers: HttpHeaders) {
        sharedInstance().authorizationHeaders = headers
    }
    
    /**
     Set client agent headers headers
     */
    open class func setAgentHeader(_ headers: HttpHeaders) {
        sharedInstance().agentHeaders = headers
    }
    
    /**
     Set client agent headers headers
     */
    open class func setRefererHeader(_ headers: HttpHeaders) {
        sharedInstance().refererHeaders = headers
    }
    
    /**
     Make http request
     
     - parameter method: Request method
     - parameter URLString: Request url
     - parameter headers: Request headers
     - parameter body: Request body
     - parameter requiredAuthorization: Is the request call authenticated? Default value is false
     - returns: A request instance
     */
    open class func request(_ method: Method = .get, _ URLString: URLConvertible, headers: HttpHeaders? = nil, body: HttpBody? = nil, requiredAuthorization: Bool = false) -> DataRequest {
        let encoding: ParameterEncoding = method == .get ? URLEncoding(destination: .httpBody) : JSONEncoding(options: .prettyPrinted)
        var requestHeaders: HttpHeaders = self.buildRequestHeader(requiredAuthorization)
        requestHeaders.append(headers)
        log.debug("Url: \(URLString), Method: \(method) \nHeader: \(requestHeaders)\nParameters: \(body)")
        return sharedInstance().alamofireManager.request(URLString, method: method, parameters: body, encoding: encoding, headers: requestHeaders)
    }
    
    /**
     Make http request
     
     - parameter request: URL request instance
     - returns: A request instance
     */
    open class func request(_ request: URLRequestConvertible) -> DataRequest {
        return sharedInstance().alamofireManager.request(request)
    }
    
    /**
     Make GET request with url, headers and body
     
     - parameter URLString: Request url
     - parameter headers: Request headers
     - parameter body: Request body
     - parameter requiredAuthorization: Is the request call authenticated? Default value is false
     - returns: A request instance
     */
    open class func GET(_ URLString: URLConvertible, headers: HttpHeaders? = nil, body: HttpBody? = nil, requiredAuthorization: Bool = false) -> DataRequest {
        return request(.get, URLString, headers: headers, body: body, requiredAuthorization: requiredAuthorization)
    }
    
    /**
     Make POST request with url, headers and body
     
     - parameter URLString: Request url
     - parameter headers: Request headers
     - parameter body: Request body
     - parameter requiredAuthorization: Is the request call authenticated? Default value is false
     - returns: A request instance
     */
    open class func POST(_ URLString: URLConvertible, headers: HttpHeaders? = nil, body: HttpBody? = nil, requiredAuthorization: Bool = false) -> DataRequest {
        return request(.post, URLString, headers: headers, body: body, requiredAuthorization: requiredAuthorization)
    }
    
    /**
     Make PUT request with url, headers and body
     
     - parameter URLString: Request url
     - parameter headers: Request headers
     - parameter body: Request body
     - parameter requiredAuthorization: Is the request call authenticated? Default value is false
     - returns: A request instance
     */
    open class func PUT(_ URLString: URLConvertible, headers: HttpHeaders? = nil, body: HttpBody? = nil, requiredAuthorization: Bool = false) -> DataRequest {
        return request(.put, URLString, headers: headers, body: body, requiredAuthorization: requiredAuthorization)
    }
    
    /**
     Make DELETE request with url, headers and body
     
     - parameter URLString: Request url
     - parameter headers: Request headers
     - parameter body: Request body
     - parameter requiredAuthorization: Is the request call authenticated? Default value is false
     - returns: A request instance
     */
    open class func DELETE(_ URLString: URLConvertible, headers: HttpHeaders? = nil, body: HttpBody? = nil, requiredAuthorization: Bool = false) -> DataRequest {
        return request(.delete, URLString, headers: headers, body: body, requiredAuthorization: requiredAuthorization)
    }
    
    /**
     Build request headers to be used for http request
     
     - parameter requiredAuthorization: Is the request call authenticated? Default value is false
     - returns: The request headers
     */
    open class func buildRequestHeader(_ requiredAuthorization: Bool) -> HttpHeaders {
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
    
    /**
     Build URL session configuration with given timeout interval value
     
     - parameter timeoutInterval: timeout interval for network request
     - returns: The URL session configuration instance
     */
    open class func configurationWithTimeoutInterval(_ timeoutInterval: TimeInterval) -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeoutInterval
        return configuration
    }
    
}

// MARK: - Alamofire Request extension
extension Request {
    
    /**
     Check if the error is connection timeout
     
     - parameter error: The error object
     - returns: Return true if the request is connection timeout, false otherwise
     */
    public func isConnectionTimeoutError(_ error: NSError) -> Bool {
        return error.isConnectionTimeoutError()
    }
    
}

// MARK: - NSError extension
public extension NSError {
    
    /**
     Check if the error is connection timeout
     
     - returns: Return true if the request is connection timeout, false otherwise
     */
    public func isConnectionTimeoutError() -> Bool {
        return domain == "NSURLErrorDomain" && code == -1001
    }
    
    /**
     Check if the error is request cancelled
     
     - returns: Return true if the request is cancelled, false otherwise
     */
    public func isRequestCancelledError() -> Bool {
        return domain == "NSURLErrorDomain" && code == -999
    }
    
}
