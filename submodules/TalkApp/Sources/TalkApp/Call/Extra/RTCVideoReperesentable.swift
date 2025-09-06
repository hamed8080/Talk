//
//  RTCVideoReperesentable.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI

struct RTCVideoReperesentable: UIViewRepresentable {
    let rendererView: UIView
    
    func makeUIView(context: Context) -> UIView {
        rendererView.contentMode = .scaleAspectFill
        return rendererView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}
