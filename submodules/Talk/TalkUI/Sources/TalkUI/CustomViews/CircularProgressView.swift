//
//  CircularProgressView.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 11/27/21.
//

import SwiftUI

public struct CircularProgressView: View {
    @Binding var percent: Int64
    let config: CircleProgressConfig

    public init(percent: Binding<Int64>, config: CircleProgressConfig) {
        self._percent = percent
        self.config = config
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: config.circleLineWidth)
                .foregroundColor(config.dimPathColor)

            Text("\(percent) %")
                .font(config.progressFont)
                .foregroundColor(config.forgroundColor)
                .fontWeight(config.fontWeight)

            Circle()
                .trim(from: 0.0, to: min(Double(percent) / 100, 1.0))
                .stroke(style: StrokeStyle(lineWidth: config.circleLineWidth, lineCap: .round, lineJoin: .round))
                .foregroundColor(config.forgroundColor)
                .rotationEffect(Angle(degrees: 270))
        }
    }
}

struct ProgressView_Previews: PreviewProvider {
    static var previews: some View {
        CircularProgressView(percent: .constant(60), config: .normal)
            .background(Color.App.bgChatMeDark)
    }
}
