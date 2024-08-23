//
//  PullToRefresh.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI
protocol PullToRefreshDelegate: AnyObject {
    func refreshed()
}

struct PullToRefresh: View {
    var coordinateSpaceName: String
    var delegate: PullToRefreshDelegate

    @State var needRefresh: Bool = false

    var body: some View {
        GeometryReader { geo in
            if geo.frame(in: .named(coordinateSpaceName)).midY > 50 {
                Spacer()
                    .onAppear {
                        needRefresh = true
                    }
            } else if geo.frame(in: .named(coordinateSpaceName)).maxY < 10 {
                Spacer()
                    .onAppear {
                        if needRefresh {
                            needRefresh = false
                            delegate.refreshed()
                        }
                    }
            }
            HStack {
                Spacer()
                if needRefresh {
                    ProgressView()
                } else {
                    Text("⬇️")
                }
                Spacer()
            }
        }.padding(.top, -50)
    }
}
