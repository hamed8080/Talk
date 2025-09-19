//
//  AudioRecordingContainerView.swift
//  TalkUI
//
//  Created by hamed on 10/22/22.
//

import SwiftUI
import TalkViewModels
import DSWaveformImage
import Combine
import TalkUI

public final class AudioRecordingContainerView: UIStackView {
    private let recordedAudioView: RecordedAudioView
    private let inRecordingAudioView: InRecordingAudioView
    private weak var viewModel: ThreadViewModel?
    static let height: CGFloat = 36

    public init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        recordedAudioView = RecordedAudioView(viewModel: viewModel)
        recordedAudioView.accessibilityIdentifier = "recordedAudioViewAudioRecordingView"
        inRecordingAudioView = InRecordingAudioView(viewModel: viewModel?.audioRecoderVM)
        inRecordingAudioView.accessibilityIdentifier = "inRecordingAudioViewAudioRecordingView"
        super.init(frame: .zero)
        configureView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        axis = .vertical
        spacing = 0
        
        recordedAudioView.setIsHidden(false)
        inRecordingAudioView.setIsHidden(false)
        addArrangedSubview(recordedAudioView)
        addArrangedSubview(inRecordingAudioView)

        inRecordingAudioView.onSubmitRecord = { [weak self] fileURL in
            self?.recordedAudioView.fileURL = fileURL
            self?.onSubmitRecord()
        }

        recordedAudioView.onSendOrClose = { [weak self] in
            guard let self = self else { return }
            recordedAudioView.setIsHidden(true)
            inRecordingAudioView.setIsHidden(true)
            viewModel?.delegate?.showRecording(false)
        }
    
        viewModel?.audioRecoderVM.onRejectPermission = { [weak self] in
            guard let self = self else { return }
            recordedAudioView.setIsHidden(true)
            inRecordingAudioView.setIsHidden(true)
            viewModel?.delegate?.showRecording(false)
        }
    }

    public func show(_ show: Bool, stack: UIStackView) {
        recordedAudioView.setIsHidden(true)
        inRecordingAudioView.setIsHidden(!show)
        inRecordingAudioView.alpha = 1.0
        recordedAudioView.alpha = 0.0
        recordedAudioView.clear()
        if !show {
            removeFromSuperViewWithAnimation()
        } else if superview == nil {
            alpha = 0.0
            if stack.arrangedSubviews.contains(where: {$0 is ReplyPrivatelyMessagePlaceholderView || $0 is ReplyMessagePlaceholderView })  {
                stack.insertArrangedSubview(self, at: 1)
            } else {
                stack.insertArrangedSubview(self, at: 0)
            }
            UIView.animate(withDuration: 0.2) {
                self.alpha = 1.0
            }
            // We have to be in showing mode to setup recording unless we will end up toggle isRecording inside the setupRecording method.
            viewModel?.setupRecording()
            inRecordingAudioView.startCircleAnimation()
        }
    }

    public func onSubmitRecord() {
        UIView.animate(withDuration: 0.2) {
            self.inRecordingAudioView.alpha = 0.0
            self.inRecordingAudioView.setIsHidden(true)
            self.recordedAudioView.alpha = 1.0
            self.recordedAudioView.setIsHidden(false)
            Task { [weak self] in
                guard let self = self else { return }
                try? await self.recordedAudioView.setup()
            }
        }
    }

    private func onCancelRecording() {
        UIView.animate(withDuration: 0.2) {
            self.inRecordingAudioView.alpha = 0.0
            self.inRecordingAudioView.setIsHidden(true)
            self.recordedAudioView.alpha = 0.0
            self.recordedAudioView.setIsHidden(true)
        }
    }
}
