//
//  File.swift
//  TCATable
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2021 id-design, inc. All rights reserved.
//

import Foundation
import SwiftCommons

struct File: Equatable {
    static var lastModified: DateFormatter = {
        let rv = DateFormatter.init()
        
        rv.formatterBehavior = .behavior10_4
        rv.dateFormat = "MMM d, yyy 'at' h:mm:ss a"
        return rv
    }()

    let fileURL: URL
    let relativePath: String
    let logicalSize: Int64
    let physicalSize: Int64
    let modificationDate: Date
    let fileName: String
    let filePath: String

    init(_ fileURL: URL) {
        self.fileURL = fileURL
        
        // TODO: figure a better way to display relative paths ...
        self.relativePath = fileURL.path
        self.logicalSize = fileURL.logicalSize
        self.physicalSize = fileURL.physicalSize
        self.modificationDate = fileURL.contentModificationDate
        self.fileName = fileURL.lastPathComponent
        self.filePath = fileURL.path
    }
}

extension File: Identifiable {
    public var id: String {
        self.filePath
    }
}

extension File: Hashable {}

extension URL {
    /// Returns an array of immediate child urls, without recursing deep into the file hierarchy
    var contentsOfDirectory: [URL] {
        (try? FileManager.default.contentsOfDirectory(
            at: self,
            includingPropertiesForKeys: nil,
            options: .producesRelativePathURLs
        )) ?? []
    }
}
