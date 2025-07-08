//
//  LeitnerNavigationView.swift
//  LeitnerBoxApp
//
//  Created by Hamed Hosseini on 4/6/25.
//
import SwiftUI

@MainActor
struct LeitnerNavigationView: View {
    let type: NavigationType
    @EnvironmentObject var viewModel: LeitnerViewModel
    
    var body: some View {
        navigate(type: type)
    }
    
    @ViewBuilder
    private func navigate(type: NavigationType) -> some View {
        switch type.kind {
        case .level(let leitner):
            if let container = viewModel.selectedObjectContainer {
                LevelsView(container: container)
                    .environmentObject(container.levelsVM)
            }
        case .settings:
            LeitnerAppSettingsView()
        }
    }
}
