//
//  MacTableApp.swift
//  MacTable
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import SwiftUI
import Log4swift

@main
struct MacTableApp: App {
    init() {
        let IDDLogLogFileName: String? = {
            if UserDefaults.standard.bool(forKey: "standardLog") {
                // Log4swift.getLogger("Application").info("Starting as normal process (not a daemon) ...")
                return nil
            } else {
                // Log4swift.getLogger("Application").info("Starting as daemon ...")
                return URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Logs/MacTableApp.log").path
            }
        }()

        // IDDLogLoadConfigFromPath(Bundle.main.path(forResource: "IDDLog", ofType: "plist"))
        Log4swiftConfig.configureLogs(defaultLogFile: IDDLogLogFileName, lock: "IDDLogLock")
        Log4swift[Self.self].info("Starting ...")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
