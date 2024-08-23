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

    func animateObjectWillChange() {
        Task { [weak self] in
            await MainActor.run { [weak self] in
                withAnimation {
                    self?.objectWillChange.send()
                }
            }
        }
    }

    func asyncAnimateObjectWillChange() async {
        await MainActor.run { [weak self] in
            withAnimation {
                self?.objectWillChange.send()
            }
        }
    }
}
