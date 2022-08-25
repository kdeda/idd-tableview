//
//  TableViewConfig.swift
//  TableView
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import Foundation

struct TableViewConfig {
    static let shared = TableViewConfig()
    
    let horizontalPadding: CGFloat = 5
    let betweenColumnsPadding: CGFloat = 5
}

