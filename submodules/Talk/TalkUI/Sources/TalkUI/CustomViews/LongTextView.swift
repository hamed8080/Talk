//
//  LongTextView.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 6/7/21.
//

import SwiftUI

public struct LongTextView: View {
    @State private var expanded: Bool = false
    @State private var truncated: Bool = false
    @Namespace var id
    private var text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if expanded {
                Text(self.text)
                    .font(.iransansBody)
                    .matchedGeometryEffect(id: 1, in: id, anchor: .top, isSource: false)
                    .multilineTextAlignment(text.naturalTextAlignment)
                    .lineLimit(nil)
                    .contentShape(Rectangle())
            } else {
                Text(self.text)
                    .font(.iransansBody)
                    .lineLimit(3)
                    .multilineTextAlignment(text.naturalTextAlignment)
                    .matchedGeometryEffect(id: 1, in: id, anchor: .bottom, isSource: true)
                    .contentShape(Rectangle())
                    .background(
                        GeometryReader { geometry in
                            Color.clear.onAppear {
                                self.determineTruncation(geometry.size)
                            }
                        }
                    )
            }
            if self.truncated {
                self.toggleButton
            }
        }
        .contentShape(Rectangle())
        .padding(.bottom, 24)
    }

    private func determineTruncation(_ size: CGSize) {
        Task {
            let total = self.text.boundingRect(
                with: CGSize(
                    width: size.width,
                    height: .greatestFiniteMagnitude
                ),
                options: .usesLineFragmentOrigin,
                attributes: [.font: UIFont.systemFont(ofSize: 16)],
                context: nil
            )
            if total.height > size.height {
                self.truncated = true
            }
        }
    }

    var toggleButton: some View {
        Button {
            withAnimation(.linear){
                self.expanded.toggle()
            }
        } label: {
            Text(self.expanded ? "General.showLess" : "General.showMore")
                .font(.iransansCaption)
        }
        .buttonStyle(.borderless)
    }
}

struct LongTextView_Previews: PreviewProvider {
    static var previews: some View {
        LongTextView("Delap found no trace in employers’ records or in state archives which focused on segregation and detaining people. But she struck gold in The National Archives in Kew with a survey of ‘employment exchanges’ undertaken in 1955 to investigate how people then termed ‘subnormal’ or ‘mentally handicapped’ were being employed. She found further evidence in the inspection records of Trade Boards now held at Warwick University’s Modern Records Centre. In 1909, a complex system of rates and inspection emerged as part of an effort to set minimum wages. This led to the development of ‘exemption permits’ for a range of employees not considered to be worth ‘full’ payment.")
    }
}
