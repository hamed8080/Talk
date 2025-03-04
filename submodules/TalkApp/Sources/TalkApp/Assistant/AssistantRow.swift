//  AssistantRow.swift
//  Talk
//
//  Created by hamed on 6/27/22.
//

import Chat
import SwiftUI
import TalkUI
import TalkViewModels

struct AssistantRow: View {
    let assistant: Assistant
    @EnvironmentObject var viewModel: AssistantViewModel

    var body: some View {
        Button {} label: {
            if viewModel.isInSelectionMode {
                SelectAssistantRadio(assistant: assistant)
            }
            
            ImageLoaderView(participant: assistant.participant)
                .frame(width: 28, height: 28)
                .background(.blue.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius:(18)))

            Text(assistant.participant?.name ?? "")
                .font(.fCaption)
            if assistant.block == true {
                Spacer()
                Text("General.blocked")
                    .font(.fCaption2)
                    .padding(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
                    .foregroundColor(Color.App.red)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.App.red)
                    )
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            if assistant.block == nil || assistant.block == false {
                Button {
                    viewModel.block(assistant)
                } label: {
                    Label("General.block", systemImage: "hand.raised")
                        .foregroundStyle(.red)
                }
            }

            if assistant.block == true {
                Button {
                    viewModel.unblock(assistant)
                } label: {
                    Label("General.unblock", systemImage: "hand.raised.slash")
                }
            }
        }
    }
}

struct SelectAssistantRadio: View {
    @EnvironmentObject var viewModel: AssistantViewModel
    var isInSelectionMode: Bool { viewModel.isInSelectionMode }
    @State var isSelected = false
    let assistant: Assistant

    var body: some View {
        ZStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .scaleEffect(x: isSelected ? 1 : 0.001, y: isSelected ? 1 : 0.001, anchor: .center)
                .foregroundColor(Color.App.color1)

            Image(systemName: "circle")
                .font(.title)
                .foregroundColor(Color.App.color1)
        }
        .frame(width: isInSelectionMode ? 22 : 0.001, height: isInSelectionMode ? 22 : 0.001, alignment: .center)
        .padding(.trailing, isInSelectionMode ? 8 : 0.001)
        .scaleEffect(x: isInSelectionMode ? 1.0 : 0.001, y: isInSelectionMode ? 1.0 : 0.001, anchor: .center)
        .onTapGesture {
            withAnimation(!isSelected ? .spring(response: 0.4, dampingFraction: 0.3, blendDuration: 0.3) : .linear) {
                isSelected.toggle()
                viewModel.toggleSelectedAssistant(isSelected: isSelected, assistant: assistant)
            }
        }
    }
}

struct AssistantRow_Previews: PreviewProvider {
    static var assistant: Assistant {
        let participant = Participant(name: "Hamed Hosseini")
        let roles: [Roles] = [.addNewUser, .editThread, .editMessageOfOthers]
        return Assistant(id: 1, participant: participant, roles: roles, block: true)
    }

    static var previews: some View {
        AssistantRow(assistant: assistant)
    }
}
