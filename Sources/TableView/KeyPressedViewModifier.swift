//
//  KeyPressedViewModifier.swift
//  TableView
//
//  Created by Klajd Deda on 12/1/22.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import SwiftUI
import Log4swift

/**
 Modeled after NSEvent.h.
 public var NSUpArrowFunctionKey: Int { get }
 etc
 */
public enum NSEventKeyType: Int {
    case none
    case upArrow
    case downArrow
    case leftArrow
    case rightArrow
}

extension NSEvent {
    private var keyTypeRawValue: Int {
        guard let chars = charactersIgnoringModifiers
        else { return 0 }

        return Int(chars.utf16[String.UTF16View.Index(utf16Offset: 0, in: chars)])
    }

    public var keyType: NSEventKeyType {
        switch keyTypeRawValue {
        case NSUpArrowFunctionKey:    return .upArrow
        case NSDownArrowFunctionKey:  return .downArrow
        case NSLeftArrowFunctionKey:  return .leftArrow
        case NSRightArrowFunctionKey: return .rightArrow

        default:
            Log4swift[Self.self].error("unhandled chars: '\(charactersIgnoringModifiers ?? "unknown")' event: '\(self)'")
            return .none
        }
    }
}

/**
 Another more modern way to handle these is
 https://stackoverflow.com/questions/61260367/swiftui-how-to-change-state-on-keyup-macos-event

 https://stackoverflow.com/questions/61153562/how-to-detect-keyboard-events-in-swiftui-on-macos

 */
struct KeyPressedViewModifier: ViewModifier {
    let keyPressed: (NSEvent) -> Bool

    init(_ keyPressed: @escaping (NSEvent) -> Bool) {
        self.keyPressed = keyPressed
    }

    func body(content: Content) -> some View {
        content.background(
            Representable(keyPressed: keyPressed)
        )
    }

    private struct Representable: NSViewRepresentable {
        let keyPressed: (NSEvent) -> Bool

        func makeNSView(context: Context) -> KeyPressedNSView {
            KeyPressedNSView(keyPressed: keyPressed)
        }

        func updateNSView(_ nsView: KeyPressedNSView, context: Context) {
            // Log4swift[Self.self].info("")
            // this is vital, since the underlying view on makeNSView is created but once
            // and the parent view manytimes, we need to readjust this function
            nsView.keyPressed = keyPressed
        }
    }
}

extension View {
    public func onKeyPressed(_ keyPressed: @escaping (NSEvent) -> Bool) -> some View {
        modifier(KeyPressedViewModifier(keyPressed))
    }
}

/**
 Helper view to push key events up the swift ui view chain.
 */
fileprivate final class KeyPressedNSView: NSView {
    var keyPressed: (NSEvent) -> Bool

    init(keyPressed: @escaping (NSEvent) -> Bool) {
        self.keyPressed = keyPressed
        super.init(frame: NSRect(x: 0, y: 0, width: 10, height: 10))

        /**
         Registering for the events this way is much more reliable than the responder chain,
         which seems all messed up on SwiftUI macOS
         */
        NSEvent.addLocalMonitorForEvents(matching: .keyUp) { event in
            // Log4swift[Self.self].info("event: '\(event)'")
            let rv = self.keyPressed(event)
            return rv ? nil : event
        }

        // https://stackoverflow.com/questions/24870322/handling-keyboard-events-in-appkit-with-swift
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Log4swift[Self.self].info("event: '\(event)'")
            let rv = self.keyPressed(event)
            return rv ? nil : event
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func becomeFirstResponder() -> Bool {
        true
    }

    override func resignFirstResponder() -> Bool {
        true
    }

//    override func keyUp(with event: NSEvent) {
//        // Log4swift[Self.self].info("event: '\(event)'")
//        keyPressed(.keyUp(event))
//        super.keyUp(with: event)
//    }
//
//    override func keyDown(with event: NSEvent) {
//        // Log4swift[Self.self].info("event: '\(event)'")
//        keyPressed(.keyDown(event))
//        super.keyDown(with: event)
//    }
//
//    override func moveUp(_ sender: Any?) {
//        guard let event = NSApp.currentEvent
//        else {
//            Log4swift[Self.self].info("sender: '\(sender ?? "none")' NSApp.currentEvent is not there !!!")
//            return
//        }
//        keyPressed(.moveUp(event))
//    }
//
//    override func moveDown(_ sender: Any?) {
//        guard let event = NSApp.currentEvent
//        else {
//            Log4swift[Self.self].info("sender: '\(sender ?? "none")' NSApp.currentEvent is not there !!!")
//            return
//        }
//        keyPressed(.moveDown(event))
//    }
}
