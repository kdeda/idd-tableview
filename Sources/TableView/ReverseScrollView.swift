//
//  ReverseScrollView.swift
//  TableView
//
//  Created by Klajd Deda on 3/3/22.
//  Copyright (C) 1997-2022 id-design, inc. All rights reserved.
//

import SwiftUI
import Log4swift

struct ReverseScrollView<Content>: View where Content: View {
    @State private var contentHeight: CGFloat = CGFloat.zero
    @State private var scrollOffset: CGFloat = CGFloat.zero
    @State private var currentOffset: CGFloat = CGFloat.zero
    
    var content: () -> Content
    
    // Calculate content offset
    func offset(outerheight: CGFloat, innerheight: CGFloat) -> CGFloat {
        //Log4swift["ReverseScrollView"].info("outerheight: \(outerheight) innerheight: \(innerheight)")
        
        let totalOffset = currentOffset + scrollOffset
        return -((innerheight/2 - outerheight/2) - totalOffset)
        // return -(totalOffset - (innerheight/2 - outerheight/2))
    }
    
    var body: some View {
        GeometryReader { outerGeometry in
            // Render the content
            //  ... and set its sizing inside the parent
            self.content()
                .modifier(ViewHeightKey())
                .onPreferenceChange(ViewHeightKey.self) { self.contentHeight = $0 }
                .frame(height: outerGeometry.size.height)
                .offset(y: self.offset(outerheight: outerGeometry.size.height, innerheight: self.contentHeight))
                .clipped()
                .animation(.easeInOut)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged({ self.onDragChanged($0) })
                        .onEnded({ self.onDragEnded($0, outerHeight: outerGeometry.size.height)}))
        }
    }
    
    func onDragChanged(_ value: DragGesture.Value) {
        // Update rendered offset
        Log4swift["ReverseScrollView"].info("Start: \(value.startLocation.y)")
        //Log4swift["ReverseScrollView"].info("Start: \(value.location.y)")
        self.scrollOffset = (value.location.y - value.startLocation.y)
        //Log4swift["ReverseScrollView"].info("Scrolloffset: \(self.scrollOffset)")
    }
    
    func onDragEnded(_ value: DragGesture.Value, outerHeight: CGFloat) {
        // Update view to target position based on drag position
        let scrollOffset = value.location.y - value.startLocation.y
        //Log4swift["ReverseScrollView"].info("Ended currentOffset=\(self.currentOffset) scrollOffset=\(scrollOffset)")
        
        let topLimit = self.contentHeight - outerHeight
        //Log4swift["ReverseScrollView"].info("toplimit: \(topLimit)")
        
        // Negative topLimit => Content is smaller than screen size. We reset the scroll position on drag end:
        if topLimit < 0 {
            self.currentOffset = 0
        } else {
            // We cannot pass bottom limit (negative scroll)
            if self.currentOffset + scrollOffset < 0 {
                self.currentOffset = 0
            } else if self.currentOffset + scrollOffset > topLimit {
                self.currentOffset = topLimit
            } else {
                self.currentOffset += scrollOffset
            }
        }
        Log4swift["ReverseScrollView"].info("new currentOffset=\(self.currentOffset)")
        self.scrollOffset = 0
    }
}

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = value + nextValue()
    }
}

extension ViewHeightKey: ViewModifier {
    func body(content: Content) -> some View {
        return content.background(GeometryReader { proxy in
            Color.clear.preference(key: Self.self, value: proxy.size.height)
        })
    }
}
//
//struct ReverseScrollView_Previews: PreviewProvider {
//    static var previews: some View {
//        ReverseScrollView {
//            VStack {
//                ForEach(demoConversation.messages) { message in
//                    BubbleView(message: message.body)
//                }
//            }
//        }
//        .previewLayout(.sizeThatFits)
//    }
//}
