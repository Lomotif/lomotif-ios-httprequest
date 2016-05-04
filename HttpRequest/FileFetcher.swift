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
public class FileFetcher: Fetcher<NSData> {
    
    public typealias SuccessHandler = (NSData) -> ()
    public typealias FailureHandler = (NSError?) -> ()
    
    // MARK: - Properties
    public private(set) var URL: URLStringConvertible?
    public private(set) var URLRequest: URLRequestConvertible?
    public private(set) var headers: HttpHeaders?
    public private(set) var body: HttpBody?
    public private(set) var request: Request?
    public private(set) var formatName: String!
    public var successHandler: SuccessHandler?
    public var failureHandler: FailureHandler?
    
    // MARK: - Initializer
    public init(URL: URLStringConvertible, headers: HttpHeaders? = nil, body: HttpBody? = nil, formatName: String = HanekeGlobals.Cache.OriginalFormatName) {
        super.init(key: URL.URLString)
        self.URL = URL
        self.headers = headers
        self.body = body
        self.formatName = formatName
    }
    
    public init(request: URLRequestConvertible, formatName: String = HanekeGlobals.Cache.OriginalFormatName) {
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
    public override func fetch(failure failure: FailureHandler?, success: SuccessHandler?) {
        if URL == nil {
            failure?(nil)
        }
        if URL != nil {
            request = HttpRequest.GET(URL!, headers: headers, body: body)
        } else if URLRequest != nil {
            request = HttpRequest.request(URLRequest!)
        }
        successHandler = success
        failureHandler = failure
        request?.response(completionHandler: { [weak self] (request, response, data, error) in
            if let strongSelf = self {
                if error != nil {
                    strongSelf.failureHandler?(error)
                } else if data != nil {
                    Shared.fileCache.set(value: data!, key: strongSelf.key, formatName: strongSelf.formatName, success: { (data) in
                        strongSelf.successHandler?(data)
                    })
                }
            }
        })
    }
    
    /**
     Cancel fetching
     */
    public override func cancelFetch() {
        request?.cancel()
        successHandler = nil
        failureHandler = nil
    }
    
    /**
     Get fetching progress
     */
    public func progress(closure: ((Int64, Int64, Int64) -> Void)?) -> Self {
        request?.progress(closure)
        return self
    }

}

// MARK: Haneke Cache extension
public extension Cache {
    
    /**
     Fetch file from url 
     
     - parameter URL: URL to fetch the file from
     - parameter headers: Optional request headers
     - parameter body: Optional request body
     - paramater failure: Failure handler block
     - paramater success: Success handler block
     - returns: FileFetcher instance
     */
    public func fetchFile(URL: URLStringConvertible, headers: HttpHeaders? = nil, body: HttpBody? = nil, formatName: String, failure: FileFetcher.FailureHandler, success: FileFetcher.SuccessHandler) -> FileFetcher {
        let fetcher = FileFetcher(URL: URL, headers: headers, body: body, formatName: formatName)
        Shared.fileCache.fetch(fetcher: fetcher).onFailure(failure).onSuccess(success)
        return fetcher
    }
    
    /**
     Fetch file with url request
     
     - parameter request: URL request to fetch the file from
     - paramater failure: Failure handler block
     - paramater success: Success handler block
     - returns: FileFetcher instance
     */
    public func fetchFile(request: URLRequestConvertible, formatName: String, failure: FileFetcher.FailureHandler, success: FileFetcher.SuccessHandler) -> FileFetcher {
        let fetcher = FileFetcher(request: request, formatName: formatName)
        Shared.fileCache.fetch(fetcher: fetcher).onFailure(failure).onSuccess(success)
        return fetcher
    }
    
}

// MARK: Haneke Shared extension
public extension Shared {
    
    // MARK: Shared file cache instance
    public static var fileCache : Cache<NSData> {
        struct Static {
            static let name = "shared-file"
            static let cache = Cache<NSData>(name: name)
        }
        return Static.cache
    }
    
}
