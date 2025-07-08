//
// SuggestionsViewModel.swift
// Copyright (c) 2022 LeitnerBox
//
// Created by Hamed Hosseini on 10/28/22.

import Foundation

@MainActor
public class SuggestionsViewModel: ObservableObject {
    public private(set) var suggestions: [Suggestion] = []
    private var count: Int = 20
    private var offset: Int = 0
    @Published public var isLoading: Bool = false
    private var hasMore: Bool = true
    
    init() {
        Task {
            await loadMore()
        }
    }
    
    public func loadMore() async {
        if isLoading || !hasMore { return }
        isLoading = true
        await getSuggestion(offset: offset, count: count)
        offset += 20
    }
    
    private struct SuggestionsRequest: Codable {
        let offset: Int
        let count: Int
    }
    
    private func getSuggestion(offset: Int, count: Int) async {
        guard let token = UserDefaults.standard.string(forKey: "leitner_token") else { return }
        var urlReq = URLRequest(url: URL(string: LeitnerBoxRoutes.suggestions)!)
        let req = SuggestionsRequest(offset: offset, count: count)
        let data = try? JSONEncoder().encode(req)
        urlReq.httpBody = data
        urlReq.httpMethod = "POST"
        urlReq.allHTTPHeaderFields = ["Content-Type": "application/json", "Authorization": "Bearer \(token)"]
        do {
            let resp = try await URLSession.shared.data(for: urlReq)
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let result = try decoder.decode([Suggestion].self, from: resp.0)
            
            await MainActor.run {
                self.hasMore = result.count >= count
                self.isLoading = false
                self.suggestions.append(contentsOf: result)
            }
        } catch {
            isLoading = false
            print("An error occured!")
        }
    }
}

public struct Suggestion: Codable, Identifiable {
    public let id: Int
    public let answer: String
    public let suggested: String
    public let username: String
    public let date: Date
}
