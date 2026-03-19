import AVFoundation
import UIKit

protocol CameraManagerDelegate: AnyObject {
    func didOutput(sampleBuffer: CMSampleBuffer)
}

final class CameraManager: NSObject {
    weak var delegate: CameraManagerDelegate?

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.example.stitch_diag_demo.camera.session")
    private let videoOutput = AVCaptureVideoDataOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var configured = false

    override init() {
        super.init()
    }

    func attachPreview(to view: UIView) {
        let previewLayer: AVCaptureVideoPreviewLayer
        if let existingLayer = self.previewLayer {
            previewLayer = existingLayer
        } else {
            let newLayer = AVCaptureVideoPreviewLayer(session: session)
            newLayer.videoGravity = .resizeAspectFill
            view.layer.insertSublayer(newLayer, at: 0)
            self.previewLayer = newLayer
            previewLayer = newLayer
        }

        previewLayer.frame = view.bounds
    }

    func layoutPreview(in bounds: CGRect) {
        previewLayer?.frame = bounds
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.configureSessionIfNeeded()
            if self.session.isRunning {
                print("CameraManager: Session already running.")
                return
            }
            print("CameraManager: Starting session...")
            self.session.startRunning()
            print("CameraManager: Session started isRunning=\(self.session.isRunning)")
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                print("CameraManager: Session already stopped.")
                return
            }
            print("CameraManager: Stopping session...")
            self.session.stopRunning()
            print("CameraManager: Session stopped.")
        }
    }

    private func configureSessionIfNeeded() {
        guard !configured else { return }

        session.beginConfiguration()
        session.sessionPreset = .high

        defer {
            session.commitConfiguration()
        }

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
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
                connection.isVideoMirrored = true
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
