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
    public typealias ProgressHandler = ((Int64, Int64, Int64) -> Void)
    
    // MARK: - Properties
    public var URL: URLStringConvertible?
    public var URLRequest: URLRequestConvertible?
    public var headers: HttpHeaders?
    public var body: HttpBody?
    public var request: Request?
    public var formatName: String!
    public var successHandler: SuccessHandler?
    public var failureHandler: FailureHandler?
    public var progressHandler: ProgressHandler?
    public var cache: Cache<NSData> = Shared.fileCache
    
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
                    strongSelf.cache.set(value: data!, key: strongSelf.key, formatName: strongSelf.formatName, success: { (data) in
                        strongSelf.successHandler?(data)
                    })
                }
                strongSelf.request = nil
                strongSelf.successHandler = nil
                strongSelf.failureHandler = nil
                strongSelf.progressHandler = nil
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
        progressHandler = nil
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
