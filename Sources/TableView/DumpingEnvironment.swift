//
//  DumpingEnvironment.swift
//  TableView
//
//  Created by Klajd Deda on 12/28/21.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import Foundation
import SwiftUI
import Log4swift

/// DEDA DEBUG
/// Experimenting with dumping the environment
struct DumpingEnvironment<Content>: View where Content: View {
    @Environment(\.self) var env
    private let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    private func isIncluded(_ row: String) -> Bool {
        row != "["
        && row != "]"
    }
    
    private func tokenize(_ row: String) -> [String: String]? {
        var tokens = row.components(separatedBy: " = ")

        tokens.removeAll(where: { $0 == "nil" })
        if tokens.count < 2 {
            return nil
        }
        let keyName = tokens[0].description.replacingOccurrences(of: "<", with: "").replacingOccurrences(of: ">", with: "")
        tokens.remove(at: 0)
        let value = tokens.joined(separator: " = ")
        return [keyName: value]
    }

    var body: some View {
        // EnvironmentValues
        var debugString = env.description
            .replacingOccurrences(of: "EnvironmentPropertyKey", with: "\n")
            .components(separatedBy: "\n")
            .filter(isIncluded)
            .map { $0.replacingOccurrences(of: ", ", with: "") }
            .compactMap(tokenize)
            .reduce(into: [String: String]()) { partialResult, next in
                next.forEach { (key: String, value: String) in
                    partialResult[key] = value
                }
            }

        debugString = debugString
            .filter { (_ element: Dictionary<String, String>.Element) in
                !element.key.starts(with: "Accessibility")
            }
            .filter { (_ element: Dictionary<String, String>.Element) in
                element.key != "XXXX"
                && element.key != "AppNavigationAuthorityKey"
                && element.key != "AllControlsNavigableKey"
                && element.key != "BackgroundInfoKey"
                && element.key != "BackgroundInfoKey"
                && element.key != "CalendarKey"
                && element.key != "ColorSchemeContrastKey"
                && element.key != "ColorSchemeKey"
                && element.key != "ControlActiveKey"
                && element.key != "DisplayGamutKey"
                && element.key != "DisplayScaleKey"
                && element.key != "EnabledTechnologiesKey"
//                && element.key != "EmphasizedKey"
                && element.key != "FocusBridgeKey"
                && element.key != "FocusSystemKey"
                && element.key != "InTouchBarKey"
                && element.key != "LayoutDirectionKey"
                && element.key != "LocaleKey"
                && element.key != "PresentationModeKey"
                && element.key != "PresentedWindowStyleKey"
                && element.key != "PresentedWindowToolbarStyleKey"
                && element.key != "ReduceDesktopTintingKey"
                && element.key != "ResetFocusKey"
                && element.key != "ScenePhaseKey"
                && element.key != "SceneStorageValuesKey"
                && element.key != "StateRestorationContextIDKey"
                && element.key != "StoreKeySceneBridge"
                && element.key != "StoreKeyStoreObservableObjectAppSettingsTabAppSettingsAction"
                && element.key != "StoreKeyStoreObservableObjectAppSettingsTabAppSettingsAction"
                && element.key != "SystemAccentValueKey"
                && element.key != "TimeZoneKey"
                && element.key != "UndoManagerKey"
                && element.key != "WindowRoleKey"
                && element.key != "WindowsControllerKey"
            }
        let view = content()
        let viewDescription = "\(view)"
        
//        if viewDescription.range(of: "minWidth: Optional(80.0") != nil {
//            Log4swift["DumpingEnvironment"].info("--------------------------------------")
//            Log4swift["DumpingEnvironment"].info("\(debugString)")
//            Log4swift["DumpingEnvironment"].info("\(viewDescription)")
//            Log4swift["DumpingEnvironment"].info("")
//        }
        return view
    }
}
