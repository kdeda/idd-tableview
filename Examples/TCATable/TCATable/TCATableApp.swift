//
//  TCATableApp.swift
//  TCATable
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import SwiftUI
import StoreKit

@main
struct TCATableApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(store: AppState.liveStore)
        }
    }
}
