//
//  TCATableApp.swift
//  TCATable
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import SwiftUI
import Log4swift
import ComposableArchitecture

@main
struct TCATableApp: App {
    let store: StoreOf<AppRoot>

    init() {
        let IDDLogLogFileName: String? = {
            if UserDefaults.standard.bool(forKey: "standardLog") {
                // Log4swift.getLogger("Application").info("Starting as normal process (not a daemon) ...")
                return nil
            } else {
                // Log4swift.getLogger("Application").info("Starting as daemon ...")
                return URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Logs/TCATableApp.log").path
            }
        }()

        // IDDLogLoadConfigFromPath(Bundle.main.path(forResource: "IDDLog", ofType: "plist"))
        Log4swiftConfig.configureLogs(defaultLogFile: IDDLogLogFileName, lock: "IDDLogLock")
        Log4swift[Self.self].info("Starting ...")
        self.store = Store(
            initialState: AppRoot.State(),
            reducer: AppRoot()
        )
    }
    
    var body: some Scene {
        WindowGroup {
            AppRootView(store: store)
        }
    }
}
