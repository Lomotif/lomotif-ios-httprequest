//
//  HttpRequest.swift
//  HttpRequest
//
//  Created by Kok Chung Law on 22/4/16.
//  Copyright © 2016 Lomotif Private Limited. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - typealias
public typealias HttpHeaders = [String: String]
public typealias HttpBody = [String: AnyObject]
public typealias Request = Alamofire.Request
public typealias Method = Alamofire.Method
public typealias URLStringConvertible = Alamofire.URLStringConvertible

// MARK: - HttpRequest which handles all the http request call
public class HttpRequest: NSObject {
    
    // MARK: - Properties
    public private(set) var authorizationHeaders: HttpHeaders = [:]
    public private(set) var agentHeaders: HttpHeaders = [:]
    public private(set) var refererHeaders: HttpHeaders = [:]
    
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
     - parameter url: Request url
     - parameter parameters: Request body
     - parameter requiredAuthorization: Is the request call authenticated? Default value is false
     - returns: A request instance
     */
    public class func request(method: Method = .GET, _ URLString: URLStringConvertible, headers: HttpHeaders? = nil, body: HttpBody? = nil, requiredAuthorization: Bool = false) -> Request {
        let encoding = method == .GET ? ParameterEncoding.URL : ParameterEncoding.JSON
        var requestHeaders: HttpHeaders = self.buildRequestHeader(requiredAuthorization)
        requestHeaders.append(headers)
        return Alamofire.request(method, URLString, parameters: body, encoding: encoding, headers: requestHeaders)
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
