import AVFoundation
import UIKit
import Combine

@MainActor
final class CameraService: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isSessionRunning = false
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var error: CameraError?

    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var videoCaptureDevice: AVCaptureDevice?

    enum CameraError: LocalizedError {
        case accessDenied
        case noDevice
        case setupFailed
        case captureFailed

        var errorDescription: String? {
            switch self {
            case .accessDenied: return "Camera access denied. Please enable it in Settings."
            case .noDevice:     return "No camera device available."
            case .setupFailed:  return "Failed to configure the camera session."
            case .captureFailed: return "Failed to capture the photo."
            }
        }
    }

    override init() {
        super.init()
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    func requestAccess() async {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        authorizationStatus = granted ? .authorized : .denied
        if granted { await setupSession() }
    }

    func setupSession() async {
        guard authorizationStatus == .authorized else { return }

        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            error = .noDevice
            session.commitConfiguration()
            return
        }
        videoCaptureDevice = device

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                error = .setupFailed
                session.commitConfiguration()
                return
            }
            session.addInput(input)

            guard session.canAddOutput(photoOutput) else {
                error = .setupFailed
                session.commitConfiguration()
                return
            }
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true

        } catch {
            self.error = .setupFailed
            session.commitConfiguration()
            return
        }

        session.commitConfiguration()

        Task.detached(priority: .background) { [weak self] in
            self?.session.startRunning()
            await MainActor.run { self?.isSessionRunning = true }
        }
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func stopSession() {
        Task.detached(priority: .background) { [weak self] in
            self?.session.stopRunning()
            await MainActor.run { self?.isSessionRunning = false }
        }
    }

    func toggleFlash() {
        guard let device = videoCaptureDevice, device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = device.torchMode == .on ? .off : .on
        device.unlockForConfiguration()
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            Task { await MainActor.run { self.error = .captureFailed } }
            return
        }
        Task { await MainActor.run { self.capturedImage = image } }
    }
}
