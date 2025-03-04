//
//  AudioWaveFormView.swift
//  Talk
//
//  Created by Hamed Hosseini on 1/21/25.
//

import Foundation
import UIKit
import DSWaveformImage
import SwiftUI

public class AudioWaveFormView: UIView {
    // Views
    private let waveImageView = UIImageView()
    private let playbackWaveformImageView = UIImageView()
    private let maskLayer = CAShapeLayer()
    private let prerenderImage = UIImage(named: "waveform")
    
    // Models
    private var isSeeking: Bool = false
    private var seekTimer: Timer? = nil
    public var onSeek: ((Double) -> Void)?
    
    // Sizes
    private let margin: CGFloat = 6
    
    public init() {
        super.init(frame: .zero)
        configureView()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        waveImageView.translatesAutoresizingMaskIntoConstraints = false
        waveImageView.isUserInteractionEnabled = true
        waveImageView.accessibilityIdentifier = "waveImageViewMessageAudioView"
        waveImageView.layer.opacity = 0.2
        waveImageView.contentMode = .scaleAspectFit
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(onDragOverWaveform))
        gesture.maximumNumberOfTouches = 1
        waveImageView.addGestureRecognizer(gesture)
        addSubview(waveImageView)
        
        playbackWaveformImageView.translatesAutoresizingMaskIntoConstraints = false
        playbackWaveformImageView.isUserInteractionEnabled = false
        playbackWaveformImageView.accessibilityIdentifier = "playbackWaveformImageViewMessageAudioView"
        playbackWaveformImageView.tintColor = Color.App.textPrimaryUIColor
        playbackWaveformImageView.layer.mask = maskLayer
        playbackWaveformImageView.contentMode = .scaleAspectFit
        addSubview(playbackWaveformImageView)
        bringSubviewToFront(playbackWaveformImageView)
        
        NSLayoutConstraint.activate([
            waveImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            waveImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            waveImageView.topAnchor.constraint(equalTo: topAnchor),
            waveImageView.heightAnchor.constraint(equalToConstant: 42),
                        
            playbackWaveformImageView.heightAnchor.constraint(equalTo: waveImageView.heightAnchor),
            playbackWaveformImageView.leadingAnchor.constraint(equalTo: waveImageView.leadingAnchor),
            playbackWaveformImageView.trailingAnchor.constraint(equalTo: waveImageView.trailingAnchor),
            playbackWaveformImageView.topAnchor.constraint(equalTo: waveImageView.topAnchor),
        ])
    }
    
    private func animateMaskLayer(newPath: CGPath) {
        
        // Remove any previous animation to avoid stacking issues
        maskLayer.removeAnimation(forKey: "pathAnimation")
        
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = maskLayer.path
        animation.toValue = newPath
        animation.duration = 0.5
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        // Add the animation to the mask layer directly
        maskLayer.add(animation, forKey: "pathAnimation")
        maskLayer.path = newPath
    }
    
    public func setPlaybackProgress(_ progress: Double) {
        if !isSeeking {
            animateMaskLayer(newPath: createPath(progress))
        }
    }
    
    private func createPath(_ progress: Double) -> CGPath {
        let fullRect = playbackWaveformImageView.bounds
        let newWidth = Double(fullRect.size.width) * progress
        let newBounds = CGRect(x: 0.0, y: 0.0, width: newWidth, height: Double(fullRect.size.height))
        return CGPath(rect: newBounds, transform: nil)
    }
    
    @objc private func onDragOverWaveform(_ sender: UIPanGestureRecognizer) {
        let to: Double = sender.location(in: sender.view).x / waveImageView.frame.size.width
        let path = createPath(to)
        
        seekTimer?.invalidate()
        seekTimer = nil
        isSeeking = true
        
        maskLayer.path = path
        onSeek?(to)
        seekTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.isSeeking = false
            }
        }
    }
    
    public func setImage(to image: UIImage?) {
        if let image = image {
            waveImageView.image = image
            playbackWaveformImageView.image = image.withTintColor(.black, renderingMode: .alwaysTemplate)
        } else {
            waveImageView.image = prerenderImage
        }
    }
}
