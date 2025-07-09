//
//  SuggestView.swift
//  LeitnerBox
//
//  Created by Hamed Hosseini on 12/8/24.
//

import SwiftUI
import UIKit

struct AddOrEditQuestionSuggestView: View {
    @State private var suggestIconForeground: Color = .accentColor
    let suggest: String
    let answer: String
    
    var body: some View {
        btnSuggest
    }
    
    private var btnSuggest: some View {
        Button {
           sendSuggestRequest()
        } label: {
            HStack {
                Image(systemName: "icloud.and.arrow.up")
                    .foregroundStyle(suggestIconForeground)
            }
            .padding()
            .clipShape(RoundedCorner(radius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor, lineWidth: 1)
            }
        }
    }
    
    fileprivate struct SuggestRequest: Codable {
        let suggested: String
        let answer: String
    }
    
    private func sendSuggestRequest() {
        guard let token = UserDefaults.standard.string(forKey: "leitner_token") else { return }
        var urlReq = URLRequest(url: URL(string: LeitnerBoxRoutes.suggest)!)
        let req = SuggestRequest(suggested: suggest, answer: answer)
        let data = try? JSONEncoder().encode(req)
        urlReq.httpBody = data
        urlReq.httpMethod = "POST"
        urlReq.allHTTPHeaderFields = ["Content-Type": "application/json", "Authorization": "Bearer \(token)"]
        Task {
            do {
                let resp = try await URLSession.shared.data(for: urlReq)
                await MainActor.run {
                    suggestIconForeground = Color.green
                }
            } catch {
                await MainActor.run {
                    suggestIconForeground = Color.red
                }
            }
        }
    }
}

