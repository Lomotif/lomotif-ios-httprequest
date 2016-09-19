//
//  FileFetcher.swift
//  HttpRequest
//
//  Created by Kok Chung Law on 24/4/16.
//  Copyright © 2016 Lomotif Private Limited. All rights reserved.
//

import Foundation
import Haneke
import Alamofire

typealias FileCache = Haneke.Cache

// MARK: - FileFetcher class
/**
 Custom fetcher class
 */
open class FileFetcher: Fetcher<Data> {
    
    public typealias SuccessHandler = (Data) -> ()
    public typealias FailureHandler = (Error?) -> ()
    public typealias ProgressHandler = (Progress) -> ()
    
    // MARK: - Properties
    open var url: URLConvertible?
    open var URLRequest: URLRequestConvertible?
    open var headers: HTTPHeaders?
    open var body: Parameters?
    open var request: DataRequest?
    open var formatName: String!
    open var successHandler: SuccessHandler?
    open var failureHandler: FailureHandler?
    open var progressHandler: ProgressHandler?
    open var cache: Cache<Data> = Shared.fileCache
    
    // MARK: - Initializer
    public init?(key: String? = nil, url: URLConvertible, headers: HTTPHeaders? = nil, body: Parameters? = nil, formatName: String = HanekeGlobals.Cache.OriginalFormatName) {
        var urlString: String!
        do {
            urlString = try url.asURL().absoluteString
        } catch {
            return nil
        }
        super.init(key: key == nil ? urlString : key!)
        self.url = url
        self.headers = headers
        self.body = body
        self.formatName = formatName
    }
    
    public init?(key: String? = nil, request: URLRequestConvertible, formatName: String = HanekeGlobals.Cache.OriginalFormatName) {
        guard let url = request.urlRequest?.url else {
            return nil
        }
        super.init(key: key == nil ? url.absoluteString : key!)
        self.URLRequest = request
        self.formatName = formatName
    }
    
    // MARK: - Functions
    /**
     Fetching file with alamofire request
     
     - parameter failure: Failure handler block
     - parameter success: Success handler block
     */
    open override func fetch(failure: FailureHandler?, success: SuccessHandler?) {
        if url == nil {
            failure?(nil)
        }
        if url != nil {
            request = HttpRequest.GET(url!, headers: headers, body: body)
        } else if URLRequest != nil {
            request = HttpRequest.request(URLRequest!)
        }
        successHandler = success
        failureHandler = failure
        request?.response(completionHandler: { [weak self] (response) in
            if let strongSelf = self {
                guard let data = response.data else {
                    strongSelf.failureHandler?(response.error)
                    strongSelf.request = nil
                    strongSelf.successHandler = nil
                    strongSelf.failureHandler = nil
                    strongSelf.progressHandler = nil
                    return
                }
                strongSelf.cache.set(value: data, key: strongSelf.key, formatName: strongSelf.formatName, success: { (data) in
                    strongSelf.successHandler?(data)
                    strongSelf.request = nil
                    strongSelf.successHandler = nil
                    strongSelf.failureHandler = nil
                    strongSelf.progressHandler = nil
                })
            }
            }).downloadProgress(closure: { [weak self] (progress) in
                self?.progressHandler?(progress)
            })
    }
    
    /**
     Cancel fetching
     */
    open override func cancelFetch() {
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
    public func fetchFile(_ url: URLConvertible, headers: HTTPHeaders? = nil, body: Parameters? = nil, formatName: String, failure: @escaping FileFetcher.FailureHandler, success: @escaping FileFetcher.SuccessHandler) -> FileFetcher? {
        guard let fetcher = FileFetcher(url: url, headers: headers, body: body, formatName: formatName) else {
            return nil
        }
        return fetcher
    }
    
    /**
     Fetch file with url request
     
     - parameter request: URL request to fetch the file from
     - paramater failure: Failure handler block
     - paramater success: Success handler block
     - returns: FileFetcher instance
     */
    public func fetchFile(_ request: URLRequestConvertible, formatName: String, failure: @escaping FileFetcher.FailureHandler, success: @escaping FileFetcher.SuccessHandler) -> FileFetcher? {
        guard let fetcher = FileFetcher(request: request, formatName: formatName) else {
            return nil
        }
        _ = Shared.fileCache.fetch(fetcher: fetcher).onFailure(failure).onSuccess(success)
        return fetcher
    }
    
}

// MARK: Haneke Shared extension
public extension Shared {
    
    // MARK: Shared file cache instance
    public static var fileCache : Cache<Data> {
        struct Static {
            static let name = "shared-file"
            static let cache = Cache<Data>(name: name)
        }
        return Static.cache
    }
    
}
