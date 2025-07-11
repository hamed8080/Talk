//
//  ObservableObject.Name+.swift
//  TalkExtensions
//
//  Created by hamed on 2/27/23.
//

import Foundation
import Combine
import SwiftUI

@MainActor
public extension ObservableObject where Self.ObjectWillChangePublisher == ObservableObjectPublisher {

    func animateObjectWillChange() {
        Task { [weak self] in
            await self?.animate()
        }
    }
    
    func asyncAnimateObjectWillChange() async {
        await animate()
    }
    
    private func animate() {
        withAnimation {
            objectWillChange.send()
        }
    }
}
