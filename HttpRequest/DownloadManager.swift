//
//  DownloadManager.swift
//  HttpRequest
//
//  Created by Kok Chung Law on 22/4/16.
//  Copyright © 2016 Lomotif Private Limited. All rights reserved.
//

import Foundation

// MARK: - DownloadManager class, handle all background downloads
open class DownloadManager: NSObject {
    
    // MARK: - Properties
    /**
     Network request queue
     */
    open dynamic fileprivate(set) lazy var queue: OperationQueue = {
        let maxOperationCount = 5
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = maxOperationCount
        return queue
    }()
    
    // MARK: - Initializer
    public override init() {
        super.init()
        self.addObserver(self, forKeyPath: "queue.operations", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    /**
     Start a download task
     */
    open func startDownloadTask(_ task: DownloadTask) {
        self.queue.addOperation(task)
    }
    
    /**
     Cancel all download tasks
     */
    open func cancelAllDownloadTasks() {
        self.queue.cancelAllOperations()
    }
    
    deinit {
        self.removeObserver(self, forKeyPath: "queue.operations")
    }
    
    // MARK: - Key-value Observer
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "queue.operations" {
            log.debug("Number of downloading task: \(self.queue.operations.count)")
        }
    }
    
    /**
     HttpRequest shared instance
     */
    open class func sharedInstance() -> DownloadManager {
        struct Singleton {
            static let instance = DownloadManager()
        }
        return Singleton.instance
    }
    
    /**
     Get temporary download folder url
     */
    open class func downloadFolderUrl() -> URL? {
        let folderPathUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("download")
        
        // create folder if it does not exist yet
        if !FileManager.default.fileExists(atPath: folderPathUrl.path) {
            do {
                try FileManager.default.createDirectory(at: folderPathUrl, withIntermediateDirectories: true, attributes: nil)
            } catch {
                log.error("Create folder failed at path: \(folderPathUrl.path)")
                return nil
            }
        }
        return folderPathUrl
    }
    
}
