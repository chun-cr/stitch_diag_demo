import Foundation
import Flutter
import UIKit
import AVFoundation

protocol CameraManagerDelegate: AnyObject {
    func didOutput(sampleBuffer: CMSampleBuffer)
}

public class CameraManager: NSObject {
    var session: AVCaptureSession?
    weak var delegate: CameraManagerDelegate?
    private(set) var latestSampleBuffer: CMSampleBuffer?
    let isPreviewMirrored = true
    
    // Preview layer for UI
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    func startSession() {
        if session != nil { return }
        let session = AVCaptureSession()
        session.sessionPreset = .vga640x480
        self.session = session
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        session.addInput(input)
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_queue"))
        session.addOutput(output)

        if let connection = output.connection(with: .video) {
            configureCaptureConnection(connection)
        }

        previewLayer?.session = session
        configurePreviewConnection()
        
        session.startRunning()
    }
    
    func stopSession() {
        session?.stopRunning()
        latestSampleBuffer = nil
        previewLayer?.session = nil
        session = nil
    }
    
    func attachPreview(to view: UIView) {
        if previewLayer == nil {
            let layer = AVCaptureVideoPreviewLayer()
            layer.session = session
            layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            previewLayer = layer
        }

        guard let previewLayer = previewLayer else { return }

        if previewLayer.superlayer !== view.layer {
            previewLayer.removeFromSuperlayer()
            view.layer.addSublayer(previewLayer)
        }

        previewLayer.frame = view.bounds
        configurePreviewConnection()
    }

    func layoutPreview(in bounds: CGRect) {
        previewLayer?.frame = bounds
    }

    private func configureCaptureConnection(_ connection: AVCaptureConnection) {
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = false
        }
    }

    private func configurePreviewConnection() {
        guard let connection = previewLayer?.connection else { return }
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = AVCaptureVideoOrientation.portrait
        }
        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = isPreviewMirrored
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        latestSampleBuffer = sampleBuffer
        delegate?.didOutput(sampleBuffer: sampleBuffer)
    }
}

// ── Platform View Implementation ───────────────────────────────────

class CameraPreviewViewFactory: NSObject, FlutterPlatformViewFactory {
    private let cameraManager: CameraManager
    
    init(cameraManager: CameraManager) {
        self.cameraManager = cameraManager
        super.init()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return CameraPreviewView(frame: frame, cameraManager: cameraManager)
    }
}

class CameraPreviewView: NSObject, FlutterPlatformView {
    private let _view: UIView
    
    init(frame: CGRect, cameraManager: CameraManager) {
        _view = PreviewContainerView(frame: frame, cameraManager: cameraManager)
        _view.backgroundColor = .black
        cameraManager.attachPreview(to: _view)
    }

    func view() -> UIView {
        return _view
    }
}

final class PreviewContainerView: UIView {
    private let cameraManager: CameraManager

    init(frame: CGRect, cameraManager: CameraManager) {
        self.cameraManager = cameraManager
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        cameraManager.layoutPreview(in: bounds)
    }
}
