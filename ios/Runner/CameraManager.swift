import AVFoundation
import UIKit

protocol CameraManagerDelegate: AnyObject {
    func didOutput(sampleBuffer: CMSampleBuffer)
}

final class CameraManager: NSObject {
    static let shared = CameraManager()
    weak var delegate: CameraManagerDelegate?

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.example.stitch_diag_demo.camera.session")
    private let videoOutput = AVCaptureVideoDataOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var configured = false
    private(set) var currentPosition: AVCaptureDevice.Position = .front

    private override init() {
        super.init()
    }

    func attachPreview(to view: UIView) {
        let layer: AVCaptureVideoPreviewLayer
        if let existingLayer = self.previewLayer {
            layer = existingLayer
            if layer.superlayer != view.layer {
                layer.removeFromSuperlayer()
                view.layer.insertSublayer(layer, at: 0)
            }
        } else {
            layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            view.layer.insertSublayer(layer, at: 0)
            self.previewLayer = layer
        }
        layer.frame = view.bounds
    }

    func layoutPreview(in bounds: CGRect) {
        previewLayer?.frame = bounds
    }

    func startSession(isBackCamera: Bool = false, completion: (() -> Void)? = nil) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            let desiredPosition: AVCaptureDevice.Position = isBackCamera ? .back : .front
            
            if self.configured && self.currentPosition != desiredPosition {
                // Camera position changed, need to reconfigure
                self.session.stopRunning()
                self.configured = false
            }
            
            self.currentPosition = desiredPosition
            self.configureSessionIfNeeded()
            
            if self.session.isRunning {
                print("CameraManager: Session already running.")
                if let completion {
                    DispatchQueue.main.async { completion() }
                }
                return
            }
            print("CameraManager: Starting session... (Position: \(self.currentPosition.rawValue))")
            self.session.startRunning()
            print("CameraManager: Session started isRunning=\(self.session.isRunning)")
            if let completion {
                DispatchQueue.main.async { completion() }
            }
        }
    }

    func stopSession(completion: (() -> Void)? = nil) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                print("CameraManager: Session already stopped.")
                if let completion {
                    DispatchQueue.main.async { completion() }
                }
                return
            }
            print("CameraManager: Stopping session...")
            self.session.stopRunning()
            print("CameraManager: Session stopped.")
            if let completion {
                DispatchQueue.main.async { completion() }
            }
        }
    }

    private func configureSessionIfNeeded() {
        guard !configured else { return }

        session.beginConfiguration()
        session.sessionPreset = .high

        defer {
            session.commitConfiguration()
        }

        // Clear existing inputs and outputs to re-configure cleanly
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.currentPosition),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            return
        }

        session.addInput(input)

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
        ]
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)

        guard session.canAddOutput(videoOutput) else {
            return
        }

        session.addOutput(videoOutput)

        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoMirroringSupported {
                // Front camera should be mirrored for 'selfie' look, Back camera (for gestures) should not
                connection.isVideoMirrored = (self.currentPosition == .front)
            }
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }

        configured = true
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        delegate?.didOutput(sampleBuffer: sampleBuffer)
    }
}
