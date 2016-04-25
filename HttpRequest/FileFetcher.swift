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
    private(set) var request: Request?
    
    // MARK: - Initializer
    init(URL: URLStringConvertible) {
        super.init(key: URL.URLString)
        self.URL = URL
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
        request = HttpRequest.GET(URL!).response(completionHandler: { (request, response, data, error) in
            if error != nil {
                failure?(error)
            } else if data != nil {
                Shared.dataCache.set(value: data!, key: self.key)
                success?(data!)
            }
        })
    }
    
    /**
     Get fetching progress
     */
    func fetchProgress(closure: ((Int64, Int64, Int64) -> Void)?) -> Self {
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
    func fetchFile(URL: URLStringConvertible, formatName: String, failure: FileFetcher.FailureHandler, success: FileFetcher.SuccessHandler) -> FileFetcher {
        let fetcher = FileFetcher(URL: URL)
        Shared.dataCache.fetch(fetcher: fetcher).onFailure(failure).onSuccess(success)
        return fetcher
    }
    
}
