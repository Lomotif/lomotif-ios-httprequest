//
//  UploadTask.swift
//  HttpRequest
//
//  Created by Kok Chung Law on 21/11/16.
//  Copyright © 2016 Lomotif Private Limited. All rights reserved.
//

import UIKit
import Alamofire

// MARK: - Uploadable Protocol
public protocol Uploadable {
    
    /// Ask the delegate to provide unique upload ID
    ///
    /// - Returns: Unique upload ID
    func uploadID() -> String
    
    /// Ask the delegate to provide upload destination URL
    ///
    /// - Returns: URL to upload the file to
    func destinationUrl() -> URL?
    
    /// Ask the delegate to provide file url
    ///
    /// - Returns: URL on disk to upload the file from
    func fileUrl() -> URL?
    
}

// MARK: - DownloadTaskDelegate Protocol
/// This is a protocol for upload task delegate
@objc public protocol UploadTaskDelegate: class {
    
    /// Callback when upload received progress
    ///
    /// - Parameters:
    ///   - task: The upload task instance
    ///   - progress: Upload progress with scale from 0 to 1
    @objc optional func uploadTask(_ task: UploadTask, uploadProgress progress: Float)
    
    /// Callback when upload has failed
    ///
    /// - Parameters:
    ///   - task: The upload task instance
    ///   - error: An error instance describing the issue
    @objc optional func uploadTask(_ task: UploadTask, failedWithError error: Error)
    
    /// Callback when upload has completed
    ///
    /// - Parameters:
    ///   - task: The upload task instance
    ///   - result: Result if any
    @objc optional func uploadTask(_ task: UploadTask, completionWithResult result: Any?)

}

public class UploadTask: ConcurrentOperation {
    
    // MARK: - Properties
    /// ID for upload task
    open fileprivate(set) var id: String!
    
    /// Identifier for background download task
    open fileprivate(set) var backgroundTaskIdentifier: UIBackgroundTaskIdentifier!
    
    /// Url of the file to be uploaded
    open fileprivate(set) var fileUrl: URL!
    
    /// Destination path of where the file should be uploaded to
    open fileprivate(set) var destinationUrl: URL!
    
    /// Network request instance used for Upload
    open fileprivate(set) var request: UploadRequest!
    
    /**
     The delegate instance for callback
     */
    open weak var delegate: UploadTaskDelegate?
    
    public init?(uploadable: Uploadable, delegate: UploadTaskDelegate) {
        guard let fileUrl = uploadable.fileUrl(),
            let destinationUrl = uploadable.destinationUrl() else {
            return nil
        }
        super.init()
        self.fileUrl = fileUrl
        self.destinationUrl = destinationUrl
        self.id = uploadable.uploadID()
        self.delegate = delegate
    }
    
    // MARK: - Initializer
    public init(id: String, fileUrl: URL, destinationUrl: URL, delegate: UploadTaskDelegate?) {
        super.init()
        self.id = id
        self.fileUrl = fileUrl
        self.destinationUrl = destinationUrl
        self.delegate = delegate
    }
    // MARK: - Functions
    
    /// Start download task
    open override func start() {
        super.start()
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: { () -> Void in
            // task expired
            if self.backgroundTaskIdentifier != UIBackgroundTaskInvalid {
                self.endBackgroundTask()
            }
        })
        Alamofire.upload(fileUrl, to: destinationUrl).uploadProgress(closure: { (progress) in
            self.delegate?.uploadTask?(self, uploadProgress: Float(progress.fractionCompleted))
        }).response { (response) in
            guard let error = response.error else {
                self.delegate?.uploadTask?(self, completionWithResult: nil)
                return
            }
            self.delegate?.uploadTask?(self, failedWithError: error)
        }
    }
    
    /// End background task
    open func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
        backgroundTaskIdentifier = UIBackgroundTaskInvalid
    }
    
    /// Cancel upload task
    open override func cancel() {
        delegate = nil
        super.cancel()
        request?.cancel()
        request = nil
    }
    
}
