//
//  ThreadsSaveScrollPositionViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 6/1/25.
//

import Foundation
import Combine
import Chat
import TalkExtensions

public struct SaveScrollPositionModel: Codable {
    let message: Message
    let topOffset: CGFloat
    
    public init(message: Message, topOffset: CGFloat) {
        self.message = message
        self.topOffset = topOffset
    }
}

@MainActor
public class ThreadsSaveScrollPositionViewModel: ObservableObject {
    private var threads: [Int: SaveScrollPositionModel] = [:]
    private let SCROLL_KEY = "SCROLL_POSITIONS_KEY"
    private var cancellable: AnyCancellable?
    
    /// Save scroll position in UserDefaults
    /// A cached version variable to reduce number of I/O
    public var isSaveScrollPosition = false
    
    public init() {
        load()
        isSaveScrollPosition = AppSettingsModel.restore().isSaveScrollPosition == true
        register()
    }
    
    private func register() {
        cancellable = NotificationCenter.appSettingsModel.publisher(for: .appSettingsModel).sink { [weak self] notif in
            if let model = notif.object as? AppSettingsModel {
                self?.isSaveScrollPosition = model.isSaveScrollPosition == true
            }
        }
    }
    
    private func load() {
        threads = UserDefaults.standard.value(forKey: SCROLL_KEY) as? [Int: SaveScrollPositionModel] ?? [:]
    }
    
    public func saveScrollPosition(threadId: Int, message: Message, topOffset: CGFloat) {
        guard isSaveScrollPosition else { return }
//        saveInUserDefaults(message)
        threads[threadId] = .init(message: message, topOffset: topOffset)
    }
    
    private func saveInUserDefaults(_ message: Message) {
        guard let data = try? JSONEncoder.instance.encode(message) else { return }
        UserDefaults.standard.set(data, forKey: SCROLL_KEY)
    }
    
    public func hasSavedScroll(for threadId: Int) -> Bool {
        threads.keys.contains(where: { $0 == threadId })
    }
    
    public func savedPosition(_ threadId: Int) -> SaveScrollPositionModel? {
        if !isSaveScrollPosition { return nil }
        return threads[threadId]
    }
    
    public func remove(_ threadId: Int) {
        threads.removeValue(forKey: threadId)
    }
    
    public func clear() {
        threads = [:]
        UserDefaults.standard.removeObject(forKey: SCROLL_KEY)
    }
}
