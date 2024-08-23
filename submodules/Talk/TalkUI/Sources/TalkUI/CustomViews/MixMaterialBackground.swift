//
//  MixMaterialBackground.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 10/7/21.
//

import SwiftUI

public struct MixMaterialBackground: View {
    let color: Color

    public init(color: Color = Color.App.bgPrimary.opacity(0.5)) {
        self.color = color
    }

    public var body: some View {
        Rectangle()
            .fill(color)
            .background(.regularMaterial)
    }
}

struct MixMaterialBackground_Previews: PreviewProvider {
    static var previews: some View {
        MixMaterialBackground()
    }
}
