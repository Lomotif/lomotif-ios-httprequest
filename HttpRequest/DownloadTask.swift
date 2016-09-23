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
public protocol Downloadable {
    
    /**
     Ask the delegate to provide unique download ID
     
     - returns: Unique download ID
     */
    func downloadID() -> String
    
    /**
     Ask the delegate to provide download URL
     
     - returns: URL to fetch the file
     */
    func downloadUrl() -> URL?
    
    /**
     Ask the delegate to provide download destination URL
     
     - returns: URL on disk to download the file to
     */
    func downloadFilePathUrl() -> URL?
    
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
    @objc optional func downloadTask(_ task: DownloadTask, downloadProgress progress: Float)
    
    /**
     Callback when download has failed
     
     - parameter error: An error instance describing the issue
     */
    @objc optional func downloadTask(_ task: DownloadTask, failedWithError error: Error)
    
    /**
     Callback when download has completed
     
     - parameter url: An URL to the downloaded file if available
     */
    @objc optional func downloadTask(_ task: DownloadTask, completedWithFileUrl url: URL)
    
}

// MARK: - DownloadTask Class
/**
 This class is a wrapper class for Alamofire download request class. When the downloading task is created and start, it will be added to the background task, and be removed when download has failed or completed.
 */
open class DownloadTask: ConcurrentOperation {
    
    // MARK: - Properties
    /**
     ID for download task
     */
    open fileprivate(set) var id: String!
    
    /**
     Identifier for background download task
     */
    open fileprivate(set) var backgroundTaskIdentifier: UIBackgroundTaskIdentifier!
    
    /**
     Source url of the file to be downloaded
     */
    open fileprivate(set) var sourceUrl: URL!
    
    /**
     Destination path on disk where the file should be downloaded to
     */
    open fileprivate(set) var destinationPathUrl: URL!
    
    /**
     Network request instance used for download
     */
    open fileprivate(set) var request: DownloadRequest!
    
    /**
     Flag to check if we should download and overwrite existing file
     */
    open var shouldOverwrite: Bool = false
    
    /**
     The delegate instance for callback
     */
    open weak var delegate: DownloadTaskDelegate?
    
    public init?(downloadable: Downloadable, delegate: DownloadTaskDelegate? = nil) {
        guard let url = downloadable.downloadUrl() else {
            return nil
        }
        super.init()
        self.destinationPathUrl = downloadable.downloadFilePathUrl()
        if self.destinationPathUrl == nil {
            if let destinationUrl = DownloadManager.downloadFolderUrl()?.appendingPathComponent(url.lastPathComponent) {
                self.destinationPathUrl = destinationUrl
            } else {
                return nil
            }
        }
        self.id = downloadable.downloadID()
        self.sourceUrl = url
        self.delegate = delegate
    }
    
    // MARK: - Initializer
    public init(id: String, sourceUrl: URL, destinationPathUrl: URL, delegate: DownloadTaskDelegate?) {
        super.init()
        self.id = id
        self.sourceUrl = sourceUrl
        self.destinationPathUrl = destinationPathUrl
        self.delegate = delegate
    }
    
    // MARK: - Functions
    /**
     Start download task
     */
    open override func start() {
        super.start()
        if FileManager.default.fileExists(atPath: self.destinationPathUrl!.path) && !self.shouldOverwrite {
            self.completeOperation()
            self.delegate?.downloadTask?(self, completedWithFileUrl: self.destinationPathUrl!)
            return
        }
        // start background downloading task
        self.backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: { () -> Void in
            // task expired
            if self.backgroundTaskIdentifier != UIBackgroundTaskInvalid {
                self.endBackgroundTask()
            }
        })
        log.debug("Start download file to path url: \(self.temporaryPathUrl()), destination path url: \(self.destinationPathUrl)")
        self.request = Alamofire.download(self.sourceUrl, to: { (url, response) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
            return (self.temporaryPathUrl(), [.removePreviousFile, .createIntermediateDirectories])
        }).downloadProgress(closure: { [weak self] (progress) in
            let downloadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
            self?.delegate?.downloadTask?(self!, downloadProgress: Float(downloadProgress))
            }).response(completionHandler: downloadCompletionCallback)
    }
    
    open func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier)
        self.backgroundTaskIdentifier = UIBackgroundTaskInvalid
    }
    
    /**
     Temporary path on disk before it is copied over to destination path
     */
    func temporaryPathUrl() -> URL {
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(destinationPathUrl.lastPathComponent)
    }
    
    /**
     Callback when download is completed, whether fail or success
     */
    open func downloadCompletionCallback(response: DefaultDownloadResponse) {
        self.endBackgroundTask()
        self.completeOperation()
        guard let error = response.error else {
            log.debug("File downloaded, moving file from \(self.temporaryPathUrl) to \(self.destinationPathUrl)")
            do {
                if FileManager.default.fileExists(atPath: self.destinationPathUrl.path) {
                    try FileManager.default.removeItem(atPath: self.destinationPathUrl.path)
                }
                try FileManager.default.moveItem(atPath: self.temporaryPathUrl().path, toPath: self.destinationPathUrl.path)
                self.delegate?.downloadTask?(self, completedWithFileUrl: self.destinationPathUrl)
            } catch let error {
                self.delegate?.downloadTask?(self, failedWithError: error as NSError)
            }
            return
        }
        
        log.error("Download file failed with error: \(error)")
        self.delegate?.downloadTask?(self, failedWithError: error)
        do {
            try FileManager.default.removeItem(atPath: self.temporaryPathUrl().path)
        } catch {
        }
    }
    
    /**
     Cancel download task
     */
    open override func cancel() {
        self.delegate = nil
        super.cancel()
        self.request?.cancel()
        self.request = nil
        do {
            try FileManager.default.removeItem(atPath: self.temporaryPathUrl().path)
        } catch {
        }
    }
    
}

