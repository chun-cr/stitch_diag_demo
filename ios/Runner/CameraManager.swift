import Foundation
import UIKit
import AVFoundation

protocol CameraManagerDelegate: AnyObject {
    func didOutput(sampleBuffer: CMSampleBuffer)
}

public class CameraManager: NSObject {
    var session: AVCaptureSession?
    var mode: String = "none"
    weak var delegate: CameraManagerDelegate?
    
    // Preview layer for UI
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    func startSession() {
        if session != nil { return }
        session = AVCaptureSession()
        session?.sessionPreset = .vga640x480
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        session?.addInput(input)
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_queue"))
        session?.addOutput(output)
        
        session?.startRunning()
    }
    
    func stopSession() {
        session?.stopRunning()
        session = nil
    }
    
    func setMode(_ mode: String) {
        self.mode = mode
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
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
        _view = UIView(frame: frame)
        _view.backgroundColor = .black
        if let session = cameraManager.session {
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.frame = frame
            layer.videoGravity = .resizeAspectFill
            _view.layer.addSublayer(layer)
        }
    }

    func view() -> UIView {
        return _view
    }
}
