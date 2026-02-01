//
//  HistoryActor.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation

public actor BackgroundActor {}

@globalActor public actor HistoryActor: GlobalActor {
    public static let shared = BackgroundActor()
}

@globalActor public actor AppBackgroundActor: GlobalActor {
    public static let shared = BackgroundActor()
}
