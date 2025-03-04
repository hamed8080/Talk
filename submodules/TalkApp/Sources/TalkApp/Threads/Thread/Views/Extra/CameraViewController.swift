//
//  CameraViewController.swift
//  Talk
//
//  Created by hamed on 4/2/24.
//

import Foundation
import UIKit
import AVFoundation
import SwiftUI

@MainActor
public final class CameraViewController: UIViewController {
    private let imageView = UIImageView()
    private let btnClose = UIButton(type: .system)
    private let btnTake = TakeButton()
    private let btnSwitchCamera = UIButton(type: .system)
    private let btnReset = UIButton(type: .system)
    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var imageData: Data?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var captureDevice = AVCaptureDevice.default(for: .video)
    private var isFront = false

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        configureViews()
    }

    private func configureViews() {
        btnTake.translatesAutoresizingMaskIntoConstraints = false
        btnTake.accessibilityIdentifier = "btnTakeCameraViewController"
        btnTake.action = { [weak self] in
            self?.takePhoto()
        }

        btnSwitchCamera.translatesAutoresizingMaskIntoConstraints = false
        btnSwitchCamera.setImage(UIImage(systemName: "arrow.triangle.2.circlepath"), for: .normal)
        btnSwitchCamera.tintColor = UIColor.white
        btnSwitchCamera.accessibilityIdentifier = "btnSwitchCameraCameraViewController"
        btnSwitchCamera.addTarget(self, action: #selector(switchTapped), for: .touchUpInside)

        btnReset.translatesAutoresizingMaskIntoConstraints = false
        btnReset.setImage(UIImage(systemName: "trash"), for: .normal)
        btnReset.tintColor = UIColor.white
        btnReset.accessibilityIdentifier = "btnResetCameraViewController"
        btnReset.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)

        btnClose.translatesAutoresizingMaskIntoConstraints = false
        btnClose.layer.backgroundColor = UIColor(named: "bg_icon")?.cgColor
        btnClose.layer.masksToBounds = true
        btnClose.layer.cornerRadius = 21
        btnClose.setImage(UIImage(systemName: "xmark"), for: .normal)
        btnClose.tintColor = UIColor(named: "accent")
        btnClose.accessibilityIdentifier = "btnCloseCameraViewController"
        btnClose.addTarget(self, action: #selector(dismissVC), for: .touchUpInside)
        view.addSubview(btnClose)


        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.accessibilityIdentifier = "imageViewCameraViewController"
        imageView.contentMode = .scaleAspectFit

        let hStack = UIStackView()
        hStack.translatesAutoresizingMaskIntoConstraints = false
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.distribution = .fill
        hStack.spacing = 48
        hStack.accessibilityIdentifier = "hStackCameraViewController"

        hStack.addArrangedSubview(btnReset)
        hStack.addArrangedSubview(btnTake)
        hStack.addArrangedSubview(btnSwitchCamera)

        view.addSubview(imageView)
        view.addSubview(hStack)

        NSLayoutConstraint.activate([
            hStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            hStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            btnClose.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            btnClose.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            btnClose.widthAnchor.constraint(equalToConstant: 42),
            btnClose.heightAnchor.constraint(equalToConstant: 42),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupCamera() {
        do {
            let videoInput = try AVCaptureDeviceInput(device: captureDevice!)
            captureSession.addInput(videoInput)
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer?.videoGravity = .resizeAspectFill
                previewLayer?.frame = view.frame
                if let previewLayer = previewLayer {
                    view.layer.addSublayer(previewLayer)
                }
                captureSession.startRunning()
            }
        } catch {
#if DEBUG
            print("Error setting up camera input: \(error)")
#endif            
        }
    }

    private func takePhoto() {
        let photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoSettings.flashMode = .auto
        if let previewPhotoPixelFormatType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
        }
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }

    @objc private func switchTapped() {
        let frontCamera = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front).devices.first
        isFront.toggle()
        if isFront, let frontCamera = frontCamera {
            captureDevice = frontCamera
        } else {
            captureDevice = AVCaptureDevice.default(for: .video)
        }

        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        for input in captureSession.inputs {
            if let deviceInput = input as? AVCaptureDeviceInput {
                captureSession.removeInput(deviceInput)
            }
        }
        do {
            let videoInput = try AVCaptureDeviceInput(device: captureDevice!)
            if !captureSession.inputs.contains(videoInput), captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
        } catch {
#if DEBUG
            print("error")
#endif
        }
    }

    @objc private func resetTapped() {
        imageView.image = nil
        previewLayer?.isHidden = false
    }

    @objc private func dismissVC() {
        dismiss(animated: true)
    }
}

extension CameraViewController: @preconcurrency AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation(), let previewImage = photo.previewCGImageRepresentation() {
            self.imageData = data
            imageView.image = UIImage(cgImage: previewImage)
            previewLayer?.isHidden = true
        }
    }
}

public struct CameraViewWrapper: UIViewControllerRepresentable {
    public func makeUIViewController(context: Context) -> some UIViewController {
        let cameraVC = CameraViewController()
        return cameraVC
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
