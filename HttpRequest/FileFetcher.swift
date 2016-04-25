//
//  FileFetcher.swift
//  HttpRequest
//
//  Created by Kok Chung Law on 24/4/16.
//  Copyright © 2016 Lomotif Private Limited. All rights reserved.
//

import Foundation
import Haneke

typealias FileCache = Haneke.Cache

// MARK: - FileFetcher class
/**
 Custom fetcher class
 */
class FileFetcher: Fetcher<NSData> {
    
    typealias SuccessHandler = (NSData) -> ()
    typealias FailureHandler = (NSError?) -> ()
    
    // MARK: - Properties
    private(set) var URL: URLStringConvertible?
    private(set) var URLRequest: URLRequestConvertible?
    private(set) var headers: HttpHeaders?
    private(set) var body: HttpBody?
    private(set) var request: Request?
    private(set) var formatName: String!
    
    // MARK: - Initializer
    init(URL: URLStringConvertible, headers: HttpHeaders? = nil, body: HttpBody? = nil, formatName: String = HanekeGlobals.Cache.OriginalFormatName) {
        super.init(key: URL.URLString)
        self.URL = URL
        self.headers = headers
        self.body = body
        self.formatName = formatName
    }
    
    init(request: URLRequestConvertible, formatName: String = HanekeGlobals.Cache.OriginalFormatName) {
        super.init(key: request.URLRequest.URLString)
        self.URLRequest = request
        self.formatName = formatName
    }
    
    // MARK: - Functions
    /**
     Fetching file with alamofire request

     - parameter failure: Failure handler block
     - parameter success: Success handler block
    */
    override func fetch(failure failure: FailureHandler?, success: SuccessHandler?) {
        if URL == nil {
            failure?(nil)
        }
        if URL != nil {
            request = HttpRequest.GET(URL!, headers: headers, body: body)
        } else if URLRequest != nil {
            request = HttpRequest.request(URLRequest!)
        }
        request?.response(completionHandler: { (request, response, data, error) in
            if error != nil {
                failure?(error)
            } else if data != nil {
                Shared.dataCache.set(value: data!, key: self.key, formatName: self.formatName, success: { (data) in
                    success?(data)
                })
            }
        })
    }
    
    /**
     Cancel fetching
     */
    override func cancelFetch() {
        request?.cancel()
    }
    
    /**
     Get fetching progress
     */
    func progress(closure: ((Int64, Int64, Int64) -> Void)?) -> Self {
        request?.progress(closure)
        return self
    }

}

// MARK: Haneke Cache extension
extension Cache {
    
    /**
     Fetch file from url 
     
     - parameter requiredAuthorization: The error object
     - returns: Return true if the request is connection timeout, false otherwise
     */
    func fetchFile(URL: URLStringConvertible, headers: HttpHeaders? = nil, body: HttpBody? = nil, formatName: String, failure: FileFetcher.FailureHandler, success: FileFetcher.SuccessHandler) -> FileFetcher {
        let fetcher = FileFetcher(URL: URL, headers: headers, body: body, formatName: formatName)
        Shared.dataCache.fetch(fetcher: fetcher).onFailure(failure).onSuccess(success)
        return fetcher
    }
    
    func fetchFile(request: URLRequestConvertible, formatName: String, failure: FileFetcher.FailureHandler, success: FileFetcher.SuccessHandler) -> FileFetcher {
        let fetcher = FileFetcher(request: request, formatName: formatName)
        Shared.dataCache.fetch(fetcher: fetcher).onFailure(failure).onSuccess(success)
        return fetcher
    }
    
}
