//
//  DownloadManager.swift
//  HttpRequest
//
//  Created by Kok Chung Law on 22/4/16.
//  Copyright © 2016 Lomotif Private Limited. All rights reserved.
//

import Foundation

// MARK: - DownloadManager class, handle all background downloads
public class DownloadManager: NSObject {
    
    // MARK: - Properties
    /**
     Network request queue
     */
    public dynamic private(set) lazy var queue: NSOperationQueue = {
        let maxOperationCount = 5
        let queue = NSOperationQueue()
        queue.maxConcurrentOperationCount = maxOperationCount
        return queue
    }()
    
    // MARK: - Initializer
    public override init() {
        super.init()
        self.addObserver(self, forKeyPath: "queue.operations", options: NSKeyValueObservingOptions.New, context: nil)
    }
    
    /**
     Start a download task
     */
    public func startDownloadTask(task: DownloadTask) {
        self.queue.addOperation(task)
    }
    
    /**
     Cancel all download tasks
     */
    public func cancelAllDownloadTasks() {
        self.queue.cancelAllOperations()
    }
    
    deinit {
        self.removeObserver(self, forKeyPath: "queue.operations")
    }
    
    // MARK: - Key-value Observer
    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "queue.operations" {
            log.debug("Number of downloading task: \(self.queue.operations.count)")
        }
    }
    
    /**
     HttpRequest shared instance
     */
    public class func sharedInstance() -> DownloadManager {
        struct Singleton {
            static let instance = DownloadManager()
        }
        return Singleton.instance
    }
    
    /**
     Get temporary download folder url
     */
    public class func downloadFolderUrl() -> NSURL? {
        let folderPathUrl = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("download")
        
        // create folder if it does not exist yet
        if !NSFileManager.defaultManager().fileExistsAtPath(folderPathUrl.path!) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtURL(folderPathUrl, withIntermediateDirectories: true, attributes: nil)
            } catch {
                log.error("Create folder failed at path: \(folderPathUrl.path!)")
                return nil
            }
        }
        return folderPathUrl
    }
    
}
