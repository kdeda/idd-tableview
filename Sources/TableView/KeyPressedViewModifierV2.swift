////
////  KeyPressedViewModifier.swift
////  
////
////  Created by Klajd Deda on 12/1/22.
////
//
//import SwiftUI
//import Log4swift
//
//public enum NSViewEvent {
//    case moveUp(NSEvent)
//    case moveDown(NSEvent)
//    case keyUp(NSEvent)
//    case keyDown(NSEvent)
//}
//
///**
// https://swiftui-lab.com/a-powerful-combo/
// */
//public struct KeyPressedView<Content>: View where Content: View {
//    var keyPressed: (NSViewEvent) -> Void
//    let content: () -> Content
//
//    init(keyPressed: @escaping (NSViewEvent) -> Void, @ViewBuilder content: @escaping () -> Content) {
//        self.keyPressed = keyPressed
//        self.content = content
//    }
//
//    public var body: some View {
//        KeyPressedRepresentable(keyPressed: keyPressed, content: self.content())
//            .padding(10)
//            .background(Color.yellow)
//            .border(Color.red)
//    }
//}
//
//struct KeyPressedRepresentable<Content>: NSViewRepresentable where Content: View {
//    let keyPressed: (NSViewEvent) -> Void
//    let content: Content
//
//    func makeNSView(context: Context) -> NSHostingView<Content> {
//        KeyPressedNSHostingView(keyPressed: keyPressed, rootView: self.content)
//    }
//
//    func updateNSView(_ nsView: NSHostingView<Content>, context: Context) {
//    }
//}
//
//final class KeyPressedNSHostingView<Content>: NSHostingView<Content> where Content: View {
//    let keyPressed: (NSViewEvent) -> Void
//
//    init(keyPressed: @escaping (NSViewEvent) -> Void, rootView: Content) {
//        self.keyPressed = keyPressed
//        super.init(rootView: rootView)
//    }
//
//    required init(rootView: Content) {
//        fatalError("init(rootView:) has not been implemented")
//    }
//
//    @objc required dynamic init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override var acceptsFirstResponder: Bool {
//        return true
//    }
//
//    override func becomeFirstResponder() -> Bool {
//        true
//    }
//
//    override func resignFirstResponder() -> Bool {
//        true
//    }
//
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
//            Log4swift[Self.self].info("sender: '\(sender)' NSApp.currentEvent is not there !!!")
//            return
//        }
//        keyPressed(.moveUp(event))
//    }
//
//    override func moveDown(_ sender: Any?) {
//        guard let event = NSApp.currentEvent
//        else {
//            Log4swift[Self.self].info("sender: '\(sender)' NSApp.currentEvent is not there !!!")
//            return
//        }
//        keyPressed(.moveDown(event))
//    }
//}
//
//extension View {
//    func onKeyPressed(_ keyPressed: @escaping (NSViewEvent) -> Void) -> some View {
//        KeyPressedView(keyPressed: keyPressed) {
//            self
//        }
//    }
//}
