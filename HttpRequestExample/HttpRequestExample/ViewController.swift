//
//  ViewController.swift
//  HttpRequestExample
//
//  Created by Kok Chung Law on 23/4/16.
//  Copyright © 2016 Lomotif Private Limited. All rights reserved.
//

import UIKit
import HttpRequest

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        HttpRequest.GET("http://www.google.com/").timeout { (url) -> Void in
            log.error("Request time out for url: \(url)")
        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

