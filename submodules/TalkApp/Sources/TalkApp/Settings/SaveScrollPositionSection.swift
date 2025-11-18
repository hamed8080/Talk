//
//  SaveScrollPositionSection.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 6/1/25.
//

import Foundation
import SwiftUI

struct SaveScrollPositionSection: View {
    @Environment(\.colorScheme) var currentSystemScheme
    @State var isSaveScrollPosition = AppSettingsModel.restore().isSaveScrollPosition ?? false
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "arrow.up.and.down")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .frame(width: 28, height: 28)
                    .foregroundColor(.white)
                    .background(Color.App.color3)
                    .clipShape(RoundedRectangle(cornerRadius:(8)))
                
                Text("Settings.saveScrollPositionTitle".bundleLocalized())
                    .padding(.leading, 8)
                Spacer()
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            
            Spacer()
            Toggle("", isOn: $isSaveScrollPosition)
                .tint(Color.App.accent)
                .frame(maxWidth: 64)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 36, alignment: .leading)
        .contentShape(Rectangle())
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .listSectionSeparator(.hidden)
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
        .onChange(of: isSaveScrollPosition) { value in
            var model = AppSettingsModel.restore()
            model.isSaveScrollPosition = value
            model.save()
        }
        .onAppear {
            isSaveScrollPosition = AppSettingsModel.restore().isSaveScrollPosition == true
        }
    }
}

#Preview {
    SaveScrollPositionSection()
}
