//
//  FileClient.swift
//  TCATable
//
//  Created by Klajd Deda on 11/3/22.
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
                .map(File.init)

            let fileCount = files.count
            let desiredFinalCount = 100_000 // this is how much we want to end up with
            // as we increase this number things start to lag ...
            let multiplier = 1 //  + desiredFinalCount / fileCount

            // multiply the initial array by x to generate more value for performance testing
            let rv = (0 ..< multiplier).reduce(into: [File]()) { partialResult, nextItem in
                let newValues: [File] = files.map { file in
                    var newCopy = file
                    if nextItem > 0 {
                        newCopy.filePath = file.id + "\(nextItem)"
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

