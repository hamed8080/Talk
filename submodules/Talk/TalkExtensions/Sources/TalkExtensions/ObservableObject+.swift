//
//  ObservableObject.Name+.swift
//  TalkExtensions
//
//  Created by hamed on 2/27/23.
//

import Foundation
import Combine
import SwiftUI

public extension ObservableObject where Self.ObjectWillChangePublisher == ObservableObjectPublisher {

    @MainActor
    func animateObjectWillChange() {
        Task { [weak self] in
            await self?.animate()
        }
    }
    
    @MainActor
    func asyncAnimateObjectWillChange() async {
        await animate()
    }
    
    @MainActor
    private func animate() {
        withAnimation {
            objectWillChange.send()
        }
    }
}
