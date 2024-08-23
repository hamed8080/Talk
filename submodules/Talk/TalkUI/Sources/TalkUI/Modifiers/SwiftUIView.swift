//
//  SwiftUIView.swift
//  
//
//  Created by hamed on 12/3/23.
//

import SwiftUI

public struct ListEmptyBackgroundViewModifier: ViewModifier {
    var show: Bool
    var color: Color

    public init(show: Bool, color: Color) {
        self.show = show
        self.color = color
    }

    public func body(content: Content) -> some View {
        content
            .overlay {
                Color.App.bgPrimary
                    .scaleEffect(x: show ? 1.0 : 0.00001, y: show ? 1.0 : 0.00001, anchor: .top)
                    .ignoresSafeArea()

            }
            .animation(.none, value: show)
    }
}

public extension View {
    func listEmptyBackgroundColor(show: Bool, color: Color = .App.bgPrimary) -> some View {
        modifier(ListEmptyBackgroundViewModifier(show: show, color: color))
    }
}
struct ListEmptyBackgroundViewModifier_Previews: PreviewProvider {
    static var previews: some View {
        List {
            Text("TEST")
        }
        .listEmptyBackgroundColor(show: true, color: .red)
    }
}
