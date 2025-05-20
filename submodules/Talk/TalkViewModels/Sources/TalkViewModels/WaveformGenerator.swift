//
//  WaveformGenerator.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/19/25.
//

import DSWaveformImage
import Foundation
import UIKit

public actor WaveformGenerator {
    private let url: URL
    private let width: CGFloat
    private let height: CGFloat

    public init(url: URL, width: CGFloat = 246, height: CGFloat = 24) {
        self.url = url
        self.width = width
        self.height = height
    }
    
    public func generate() async throws -> UIImage {
        let waveformImageDrawer = WaveformImageDrawer()
        return try await waveformImageDrawer.waveformImage(
            fromAudioAt: url,
            with: .init(
                size: .init(width: width, height: height),
                style: .striped(
                    .init(
                        color: UIColor.gray,
                        width: 2,
                        spacing: 4,
                        lineCap: .round
                    )
                ),
                shouldAntialias: true
            ),
            renderer: LinearWaveformRenderer()
        )
    }
}
