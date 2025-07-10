//
// SuggestionsListView.swift
// Copyright (c) 2022 LeitnerBox
//
// Created by Hamed Hosseini on 10/28/22.


import Foundation
import SwiftUI

public struct SuggestionListView: View {
    @StateObject private var viewModel = SuggestionsViewModel()
    public var completion: (Suggestion) -> Void
    @Environment(\.dismiss) var dismiss
    
    public var body: some View {
        List {
            rows
            loadingView
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 0)
        .background(Color.clear)
        .animation(.easeInOut, value: viewModel.suggestions.count)
        .environmentObject(viewModel)
    }
    
    @ViewBuilder
    private var rows: some View {
        ForEach(viewModel.suggestions) { suggestion in
            Button {
                completion(suggestion)
                dismiss()
            } label: {
                SuggestionRow(suggestion)
            }
            .buttonStyle(.borderless)
            .listRowInsets(.init(top: 16, leading: 8, bottom: 16, trailing: 8))
            .listRowSeparatorTint(Color.gray.opacity(0.4))
            .listRowBackground(Color.clear)
            .onAppear {
                Task {
                    await viewModel.loadMore()
                }
            }
        }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        if viewModel.isLoading {
            ProgressView()
                .progressViewStyle(.circular)
        }
    }
}

public struct SuggestionRow: View {
    public let suggestion: Suggestion
    @EnvironmentObject var viewModel: SuggestionsViewModel
    
    public init(_ suggestion: Suggestion) {
        self.suggestion = suggestion
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.suggested)
                    .font(.body.bold())
                    .padding(.top)
                
                Text(suggestion.answer)
                    .font(.caption.bold())
                    .foregroundColor(.teal)
            }
            
            HStack {
                Text(suggestion.date.formatted(.dateTime))
                    .font(.caption2)
                    .foregroundStyle(.gray)
                Text("by: \(suggestion.username)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.gray)
                Spacer()
            }
            .environment(\.layoutDirection, .leftToRight)
        }
    }
}
