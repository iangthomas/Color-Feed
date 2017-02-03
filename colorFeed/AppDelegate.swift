//
//  AppDelegate.swift
//  colorFeed
//
//  Created by Ian Thomas on 2/2/17.
//  Copyright © 2017 Geodex Systems. All rights reserved.
//

import UIKit
import SwiftyJSON


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.tableViewReadyForData(_:)), name: NSNotification.Name (rawValue: "pleaseSendData"), object: nil)
        
        return true
    }
    
    
    // get the JSON data and parse it
    func tableViewReadyForData(_ theNotification: NSNotification)  {
        
        var testData: Data!
        
        if let file = Bundle(for:feedTableViewController.self).path(forResource: "data", ofType: "json") {
            testData = try? Data(contentsOf: URL(fileURLWithPath: file))
            
            let json = JSON(data: testData)
            let arrayOfConfessions = json.array
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "dataReady"), object: arrayOfConfessions)
        }
    }
}
