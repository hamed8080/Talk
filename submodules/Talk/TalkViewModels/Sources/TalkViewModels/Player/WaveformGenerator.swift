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

    public init(url: URL, width: CGFloat = 246, height: CGFloat = 32) {
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
                        width: 3,
                        spacing: 4,
                        lineCap: .round
                    )
                ),
                verticalScalingFactor: 1,
                shouldAntialias: true
            ),
            renderer: LinearWaveformRenderer(),
            position: .bottom
        )
    }
}
