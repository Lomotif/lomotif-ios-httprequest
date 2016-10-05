//
//  HttpRequest.swift
//  HttpRequest
//
//  Created by Kok Chung Law on 22/4/16.
//  Copyright © 2016 Lomotif Private Limited. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyBeaver

// SwiftyBeaver
let log = SwiftyBeaver.self

// MARK: - HttpRequest which handles all the http request call
open class HttpRequest: NSObject {
    
    // MARK: - Properties
    open var authorizationHeaders: HTTPHeaders = [:]
    open var agentHeaders: HTTPHeaders = [:]
    open var refererHeaders: HTTPHeaders = [:]
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
    open class func shared() -> HttpRequest {
        struct Singleton {
            static let instance = HttpRequest()
        }
        return Singleton.instance
    }
    
    /**
     Set client authorization headers
     */
    open class func setAuthorizationHeader(_ headers: HTTPHeaders) {
        shared().authorizationHeaders = headers
    }
    
    /**
     Set client agent headers headers
     */
    open class func setAgentHeader(_ headers: HTTPHeaders) {
        shared().agentHeaders = headers
    }
    
    /**
     Set client agent headers headers
     */
    open class func setRefererHeader(_ headers: HTTPHeaders) {
        shared().refererHeaders = headers
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
    open class func request(_ method: HTTPMethod = .get, _ URLString: URLConvertible, headers: HTTPHeaders? = nil, body: Parameters? = nil, requiredAuthorization: Bool = false) -> DataRequest {
        let encoding: ParameterEncoding = method == .get ? URLEncoding(destination: .queryString) : JSONEncoding(options: .prettyPrinted)
        var requestHeaders: HTTPHeaders = self.buildRequestHeader(requiredAuthorization)
        requestHeaders.append(headers)
        log.debug("Url: \(URLString), Method: \(method) \nHeader: \(requestHeaders)\nParameters: \(body)")
        return shared().alamofireManager.request(URLString, method: method, parameters: body, encoding: encoding, headers: requestHeaders)
    }
    
    /**
     Make http request
     
     - parameter request: URL request instance
     - returns: A request instance
     */
    open class func request(_ request: URLRequestConvertible) -> DataRequest {
        return shared().alamofireManager.request(request)
    }
    
    /**
     Make GET request with url, headers and body
     
     - parameter URLString: Request url
     - parameter headers: Request headers
     - parameter body: Request body
     - parameter requiredAuthorization: Is the request call authenticated? Default value is false
     - returns: A request instance
     */
    open class func GET(_ URLString: URLConvertible, headers: HTTPHeaders? = nil, body: Parameters? = nil, requiredAuthorization: Bool = false) -> DataRequest {
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
    open class func POST(_ URLString: URLConvertible, headers: HTTPHeaders? = nil, body: Parameters? = nil, requiredAuthorization: Bool = false) -> DataRequest {
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
    open class func PUT(_ URLString: URLConvertible, headers: HTTPHeaders? = nil, body: Parameters? = nil, requiredAuthorization: Bool = false) -> DataRequest {
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
    open class func DELETE(_ URLString: URLConvertible, headers: HTTPHeaders? = nil, body: Parameters? = nil, requiredAuthorization: Bool = false) -> DataRequest {
        return request(.delete, URLString, headers: headers, body: body, requiredAuthorization: requiredAuthorization)
    }
    
    /**
     Build request headers to be used for http request
     
     - parameter requiredAuthorization: Is the request call authenticated? Default value is false
     - returns: The request headers
     */
    open class func buildRequestHeader(_ requiredAuthorization: Bool) -> HTTPHeaders {
        var requestHeaders: HTTPHeaders!
        if requiredAuthorization {
            requestHeaders = shared().authorizationHeaders
            requestHeaders.append(shared().agentHeaders)
            requestHeaders.append(shared().refererHeaders)
        } else {
            requestHeaders = shared().agentHeaders
            requestHeaders.append(shared().refererHeaders)
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
