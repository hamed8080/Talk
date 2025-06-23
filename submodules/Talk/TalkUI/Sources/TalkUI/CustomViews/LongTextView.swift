//
//  LongTextView.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 6/7/21.
//

import SwiftUI
public struct LongTextView: View {
    @State private var expanded: Bool = false
    private var text: String
    private let max = 50

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(expanded ? self.text : String(self.text.prefix(max)))
                .font(.fBody)
                .lineLimit(expanded ? nil : 1)
                .multilineTextAlignment(text.naturalTextAlignment)
                .contentShape(Rectangle())
            
            if text.count > 50 {
                self.toggleButton
            }
        }
        .contentShape(Rectangle())
        .padding(.bottom, 24)
    }

    var toggleButton: some View {
        Button {
            withAnimation(.linear){
                self.expanded.toggle()
            }
        } label: {
            Text(self.expanded ? "General.showLess" : "General.showMore")
                .font(.fCaption)
        }
        .buttonStyle(.borderless)
    }
}

struct LongTextView_Previews: PreviewProvider {
    static var previews: some View {
        LongTextView("Delap found no trace in employers’ records or in state archives which focused on segregation and detaining people. But she struck gold in The National Archives in Kew with a survey of ‘employment exchanges’ undertaken in 1955 to investigate how people then termed ‘subnormal’ or ‘mentally handicapped’ were being employed. She found further evidence in the inspection records of Trade Boards now held at Warwick University’s Modern Records Centre. In 1909, a complex system of rates and inspection emerged as part of an effort to set minimum wages. This led to the development of ‘exemption permits’ for a range of employees not considered to be worth ‘full’ payment.")
    }
}
