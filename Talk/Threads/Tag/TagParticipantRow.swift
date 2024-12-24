//
//  TagRow.swift
//  TagParticipantRow
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import SwiftUI
import TalkUI
import TalkViewModels

struct TagParticipantRow: View {
    var tag: Tag
    var tagParticipant: TagParticipant
    @StateObject var viewModel: TagsViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if let conversation = tagParticipant.conversation {
                        ImageLoaderView(conversation: conversation)
                            .id("\(tagParticipant.conversation?.computedImageURL ?? "")\(tagParticipant.conversation?.id ?? 0)")
                            .font(.system(size: 16).weight(.heavy))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color(uiColor: String.getMaterialColorByCharCode(str: tagParticipant.conversation?.title ?? "")))
                            .clipShape(RoundedRectangle(cornerRadius:(14)))
                        VStack(alignment: .leading) {
                            Text(conversation.title ?? "")
                                .font(.iransansBody)
                                .foregroundColor(Color.App.textSecondary)
                        }
                        Spacer()
                    }
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .padding(EdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 4))
    }
}

struct TagParticipantRow_Previews: PreviewProvider {
    static var previews: some View {
        TagParticipantRow(tag: MockData.tag, tagParticipant: MockData.tag.tagParticipants!.first!, viewModel: TagsViewModel())
    }
}
