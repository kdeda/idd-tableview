//
//  FileClient.swift
//  TCATable
//
//  Created by Klajd Deda on 11/3/22.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import Foundation
import ComposableArchitecture
import XCTestDynamicOverlay

public struct FileClient {
    /**
     Given a url, return all files under it
     Start fetching files under ~/Desktop ...
     This will work because we removed entitlements from this app
     */
    let fetchFiles: (_ url: URL) async -> [File]
}

extension DependencyValues {
    public var fileClient: FileClient {
        get { self[FileClient.self] }
        set { self[FileClient.self] = newValue }
    }
}

extension FileClient: DependencyKey {
    public static let liveValue = Self(
        fetchFiles: { url in
            let files = url
                .contentsOfDirectory
                .enumerated()
                .map { File.init(id: $0.offset, fileURL: $0.element) }

            let fileCount = files.count
            let desiredFinalCount = 100_000 // this is how much we want to end up with
            // as we increase this number things start to lag ...
            let multiplier = 10 //  + desiredFinalCount / fileCount

            // multiply the initial array by x to generate more value for performance testing
            let rv = (0 ..< multiplier).reduce(into: [File]()) { partialResult, nextItem in
                let newValues: [File] = files.map { file in
                    var newCopy = file
                    if nextItem > 0 {
                        newCopy.id = partialResult.count + file.id
                        newCopy.logicalSize += newCopy.logicalSize * Int64(nextItem)
                        newCopy.physicalSize += newCopy.physicalSize * Int64(nextItem)
                    }
                    return newCopy
                }
                partialResult.append(contentsOf: newValues)
            }
            return rv
        }
    )
}

