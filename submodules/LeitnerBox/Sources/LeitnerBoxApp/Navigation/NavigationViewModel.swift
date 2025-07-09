//
//  NavigationViewModel.swift
//  LeitnerBoxApp
//
//  Created by Hamed Hosseini on 4/6/25.
//

import SwiftUI
import Combine

@MainActor
public final class NavigationViewModel: ObservableObject {
    @Published public var paths = NavigationPath()
    @Published public var columnVisibility: NavigationSplitViewVisibility = .automatic
    
    @MainActor
    static let shared = NavigationViewModel()
    
    private init() {
    }
    
    func append(leitner: Leitner) {
        columnVisibility = .detailOnly
        paths.append(NavigationType(kind: .level(leitner)))
    }
    
    func appendSetting() {
        columnVisibility = .detailOnly
        paths.append(NavigationType(kind: .settings))
    }
}

@MainActor
struct NavigationType: Hashable, Identifiable{
    var id = UUID()
    var kind: NavKind
    
    @MainActor
    enum NavKind: Hashable {
        case level(Leitner)
        case settings
    }
}
