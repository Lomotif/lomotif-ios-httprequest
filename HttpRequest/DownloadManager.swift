//
//  DownloadManager.swift
//  HttpRequest
//
//  Created by Kok Chung Law on 22/4/16.
//  Copyright © 2016 Lomotif Private Limited. All rights reserved.
//

import Foundation

class DownloadManager: NSObject {

    class func downloadFolderUrl() -> NSURL? {
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
