//
//  MacTableApp.swift
//  MacTable
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import SwiftUI
import Log4swift
import Logging

@main
struct MacTableApp: App {
    init() {
        Log4swift.configure(appName: "MacTableApp")
        Log4swift[Self.self].info("Starting ...")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
