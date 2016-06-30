//
//  DownloadTask.swift
//  Lomotif
//
//  Created by Kok Chung Law on 22/4/16.
//  Copyright © 2016 Lomotif Private Limited. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Downloadable Protocol
protocol Downloadable {
    
    /**
     Ask the delegate to provide download URL
     
     - returns: URL to fetch the file
     */
    func downloadURL() -> NSURL?
    
    /**
     Ask the delegate to provide download destination URL
     
     - returns: URL on disk to download the file to
     */
    func downloadFilePathURL() -> NSURL?
    
}

// MARK: - DownloadTaskDelegate Protocol
/**
This is a protocol for download task delegate
*/
@objc public protocol DownloadTaskDelegate: class {
    
    /**
    Callback when download received progress
    
    - parameter progress: Download progress with scale from 0 to 1
    */
    optional func downloadTask(task: DownloadTask, downloadProgress progress: Float)
    
    /**
    Callback when download has failed
    
    - parameter error: An error instance describing the issue
    */
    optional func downloadTask(task: DownloadTask, failedWithError error: NSError)
    
    /**
    Callback when download has completed
    
    - parameter url: An URL to the downloaded file if available
    */
    optional func downloadTask(task: DownloadTask, completedWithFileURL URL: NSURL)
    
}

// MARK: - DownloadTask Class
/**
This class is a wrapper class for Alamofire download request class. When the downloading task is created and start, it will be added to the background task, and be removed when download has failed or completed.
*/
public class DownloadTask: ConcurrentOperation {
    
    // MARK: - Properties
    /**
    ID for download task
    */
    public private(set) var id: String!
    
    /**
    Identifier for background download task
    */
    public private(set) var backgroundTaskIdentifier: UIBackgroundTaskIdentifier!
    
    /**
    Source url of the file to be downloaded
    */
    public private(set) var sourceUrl: NSURL!
    
    /**
    Destination path on disk where the file should be downloaded to
    */
    public private(set) var destinationPathUrl: NSURL!
    
    /**
    Temporary path on disk before it is copied over to destination path
    */
    private var temporaryPathUrl: NSURL!
    
    /**
    Network request instance used for download
    */
    public private(set) var request: Request!
    
    /**
    The delegate instance for callback
    */
    public weak var delegate: DownloadTaskDelegate?
    
    // MARK: - Initializer
    public init(id: String, sourceUrl: NSURL, destinationPathUrl: NSURL, delegate: DownloadTaskDelegate?) {
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
    public override func start() {
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
                self?.delegate?.downloadTask?(self!, downloadProgress: Float(progress))
                }).response(completionHandler: { [weak self] (request, response, data, error) -> Void in
                    self?.downloadCompletionCallback(request, response: response, result: data, error: error)
                    })
        } catch {
        }
    }
    
    public func endBackgroundTask() {
        UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier)
        self.backgroundTaskIdentifier = UIBackgroundTaskInvalid
    }
    
    /**
    Callback when download is completed, whether fail or success
    */
    public func downloadCompletionCallback(request: NSURLRequest?, response: NSHTTPURLResponse?, result: NSData?, error: NSError?) {
        self.endBackgroundTask()
        self.completeOperation()
        guard let error = error else {
            log.debug("File downloaded, moving file from \(self.temporaryPathUrl) to \(self.destinationPathUrl)")
            do {
                if NSFileManager.defaultManager().fileExistsAtPath(self.destinationPathUrl.path!) {
                    try NSFileManager.defaultManager().removeItemAtPath(self.destinationPathUrl.path!)
                }
                try NSFileManager.defaultManager().moveItemAtPath(self.temporaryPathUrl.path!, toPath: self.destinationPathUrl.path!)
                self.delegate?.downloadTask?(self, completedWithFileURL: self.destinationPathUrl)
            } catch let error {
                self.delegate?.downloadTask?(self, failedWithError: error as NSError)
            }
            return
        }
        
        log.error("Download file failed with error: \(error)")
        self.delegate?.downloadTask?(self, failedWithError: error)
        do {
            try NSFileManager.defaultManager().removeItemAtPath(self.temporaryPathUrl.path!)
        } catch {
        }
    }
    
    /**
    Cancel download task
    */
    public override func cancel() {
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

