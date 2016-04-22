//
//  DownloadTask.swift
//  Lomotif
//
//  Created by Kok Chung Law on 2015/10/20.
//  Copyright © 2015年 Lomotif. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - DownloadTaskDelegate Protocol
/**
This is a protocol for download task delegate
*/
protocol DownloadTaskDelegate: class {
    
    /**
    Callback when upload received progress
    
    - parameter progress: Download progress with scale from 0 to 1
    */
    func downloadTaskDownloadProgress(progress: Float)
    
    /**
    Callback when upload has failed
    
    - parameter error: An error instance describing the issue
    */
    func downloadTaskFailedWithError(error: NSError!)
    
    /**
    Callback when upload has complated
    
    - parameter url: An URL to the downloaded file if available
    */
    func downloadTaskCompletedWithUrl(url: NSURL!)
    
}

// MARK: - DownloadTask Class
/**
This class is a wrapper class for Alamofire download request class. When the downloading task is created and start, it will be added to the background task, and be removed when download has failed or completed.
*/
class DownloadTask: ConcurrentOperation {
    
    // MARK: - Properties
    /**
    ID for download task
    */
    private(set) var id: String!
    
    /**
    Identifier for background download task
    */
    private(set) var backgroundTaskIdentifier: UIBackgroundTaskIdentifier!
    
    /**
    Source url of the file to be downloaded
    */
    private(set) var sourceUrl: NSURL!
    
    /**
    Destination path on disk where the file should be downloaded to
    */
    private(set) var destinationPathUrl: NSURL!
    
    /**
    Temporary path on disk before it is copied over to destination path
    */
    private var temporaryPathUrl: NSURL!
    
    /**
    Network request instance used for download
    */
    private(set) var request: Request!
    
    /**
    The delegate instance for callback
    */
    weak var delegate: DownloadTaskDelegate?
    
    // MARK: - Initializer
    init(id: String, sourceUrl: NSURL, destinationPathUrl: NSURL, delegate: DownloadTaskDelegate?) {
        super.init()
        self.id = id
        self.sourceUrl = sourceUrl
        self.destinationPathUrl = destinationPathUrl
        
        if let tempFolder = DownloadManager.downloadFolderUrl() {
            self.temporaryPathUrl = tempFolder.URLByAppendingPathComponent(destinationPathUrl.lastPathComponent!)
            self.delegate = delegate
        }
    }
    
    // MARK: - Functions
    /**
    Start download task
    */
    override func start() {
        super.start()
        // start background downloading task
        self.backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({ () -> Void in
            // task expired
            if self.backgroundTaskIdentifier != UIBackgroundTaskInvalid {
                self.endBackgroundTask()
            }
        })
        do {
            if NSFileManager.defaultManager().fileExistsAtPath(self.temporaryPathUrl.path!) {
                try NSFileManager.defaultManager().removeItemAtPath(self.temporaryPathUrl.path!)
            }
            log.debug("Start download file to path url: \(self.temporaryPathUrl), destination path url: \(self.destinationPathUrl)")
            self.request = Alamofire.download(Method.GET, self.sourceUrl, destination: { (url, response) -> NSURL in
                return self.temporaryPathUrl
            }).progress({ [weak self] (bytesRead, totalBytesRead, totalBytesExpectedToRead) -> Void in
                let progress = Double(totalBytesRead) / Double(totalBytesExpectedToRead)
                self?.delegate?.downloadTaskDownloadProgress(Float(progress))
                }).response(completionHandler: { [weak self] (request, response, data, error) -> Void in
                    self?.downloadCompletionCallback(request, response: response, result: data, error: error)
                    })
        } catch {
        }
    }
    
    func endBackgroundTask() {
        UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier)
        self.backgroundTaskIdentifier = UIBackgroundTaskInvalid
    }
    
    /**
    Callback when download is completed, whether fail or success
    */
    func downloadCompletionCallback(request: NSURLRequest?, response: NSHTTPURLResponse?, result: NSData?, error: NSError?) {
        self.endBackgroundTask()
        self.completeOperation()
        guard let error = error else {
            log.debug("File downloaded, moving file from \(self.temporaryPathUrl) to \(self.destinationPathUrl)")
            do {
                if NSFileManager.defaultManager().fileExistsAtPath(self.destinationPathUrl.path!) {
                    try NSFileManager.defaultManager().removeItemAtPath(self.destinationPathUrl.path!)
                }
                try NSFileManager.defaultManager().moveItemAtPath(self.temporaryPathUrl.path!, toPath: self.destinationPathUrl.path!)
                self.delegate?.downloadTaskCompletedWithUrl(self.destinationPathUrl)
            } catch let error {
                self.delegate?.downloadTaskFailedWithError(error as NSError)
            }
            return
        }
        
        log.error("Download file failed with error: \(error)")
        self.delegate?.downloadTaskFailedWithError(error)
        do {
            try NSFileManager.defaultManager().removeItemAtPath(self.temporaryPathUrl.path!)
        } catch {
        }
    }
    
    /**
    Cancel download task
    */
    override func cancel() {
        self.delegate = nil
        super.cancel()
        self.request?.cancel()
        self.request = nil
        do {
            try NSFileManager.defaultManager().removeItemAtPath(self.temporaryPathUrl.path!)
        } catch {
        }
    }
    
}

