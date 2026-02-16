import SwiftUI
import AVFoundation
import UIKit

struct CameraScannerView: UIViewControllerRepresentable {
    let isActive: Bool
    let onScan: (String) -> Void
    let onHint: (String) -> Void
    let onError: (String) -> Void

    func makeUIViewController(context: Context) -> CameraScannerViewController {
        let controller = CameraScannerViewController()
        controller.onScan = onScan
        controller.onHint = onHint
        controller.onError = onError
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraScannerViewController, context: Context) {
        uiViewController.setActive(isActive)
    }
}

final class CameraScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate,
    AVCaptureVideoDataOutputSampleBufferDelegate
{
    private let session = AVCaptureSession()
    private let metadataOutput = AVCaptureMetadataOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "passport.camera.queue")
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isConfigured = false
    private var isActive = false
    private var scanLocked = false
    private var lastHintAt: Date?

    var onScan: ((String) -> Void)?
    var onHint: ((String) -> Void)?
    var onError: ((String) -> Void)?

    private struct FrameLuma {
        let data: [UInt8]
        let width: Int
        let height: Int
        let bytesPerRow: Int
    }

    private var lastFrame: FrameLuma?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    func setActive(_ active: Bool) {
        if active == isActive { return }
        isActive = active
        if active {
            startSession()
        } else {
            stopSession()
        }
    }

    private func configureSession() {
        guard !isConfigured else { return }
        session.beginConfiguration()
        session.sessionPreset = .hd1280x720

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            onError?("Camera unavailable.")
            session.commitConfiguration()
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            onError?("Camera error: \(error.localizedDescription)")
            session.commitConfiguration()
            return
        }

        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: queue)
            metadataOutput.metadataObjectTypes = [.qr]
        }

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            videoOutput.setSampleBufferDelegate(self, queue: queue)
        }

        if let connection = videoOutput.connection(with: .video) {
            if #available(iOS 17.0, *) {
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
            } else if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
        if let connection = metadataOutput.connection(with: .video) {
            if #available(iOS 17.0, *) {
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
            } else if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }

        session.commitConfiguration()
        isConfigured = true

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        self.previewLayer = previewLayer
    }

    private func startSession() {
        scanLocked = false
        if !session.isRunning {
            queue.async { [weak self] in
                self?.session.startRunning()
            }
        }
    }

    private func stopSession() {
        scanLocked = true
        if session.isRunning {
            queue.async { [weak self] in
                self?.session.stopRunning()
            }
        }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard isActive, !scanLocked else { return }
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              object.type == .qr,
              let rawValue = object.stringValue,
              let frame = lastFrame
        else { return }

        let box = CGRect(
            x: object.bounds.origin.x * CGFloat(frame.width),
            y: object.bounds.origin.y * CGFloat(frame.height),
            width: object.bounds.size.width * CGFloat(frame.width),
            height: object.bounds.size.height * CGFloat(frame.height)
        )

        let whiteOk = passesWhiteBorderCheck(frame: frame, box: box)
        let textureOk = passesTextureCheck(frame: frame, box: box)

        if !whiteOk || !textureOk {
            postHint(whiteOk: whiteOk, textureOk: textureOk)
            return
        }

        scanLocked = true
        DispatchQueue.main.async { [weak self] in
            self?.onScan?(rawValue)
        }
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard isActive, !scanLocked else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        guard let baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else { return }
        let size = bytesPerRow * height

        var buffer = [UInt8](repeating: 0, count: size)
        buffer.withUnsafeMutableBytes { dest in
            _ = memcpy(dest.baseAddress, baseAddress, size)
        }
        lastFrame = FrameLuma(data: buffer, width: width, height: height, bytesPerRow: bytesPerRow)
    }

    private func postHint(whiteOk: Bool, textureOk: Bool) {
        let now = Date()
        if let last = lastHintAt, now.timeIntervalSince(last) < 1.0 { return }
        lastHintAt = now
        let message: String
        if !whiteOk && !textureOk {
            message = "Needs white paper and the official printout."
        } else if !whiteOk {
            message = "Place the QR on white paper under bright light."
        } else {
            message = "Printed QR texture missing. Use the official printout."
        }
        DispatchQueue.main.async { [weak self] in
            self?.onHint?(message)
        }
    }

    private func lumaAt(_ frame: FrameLuma, x: Int, y: Int) -> Double {
        if x < 0 || y < 0 || x >= frame.width || y >= frame.height { return 0 }
        let idx = y * frame.bytesPerRow + x
        if idx < 0 || idx >= frame.data.count { return 0 }
        return Double(frame.data[idx])
    }

    private func passesWhiteBorderCheck(frame: FrameLuma, box: CGRect) -> Bool {
        let minX = max(0, Int(box.origin.x))
        let minY = max(0, Int(box.origin.y))
        let maxX = min(frame.width - 1, Int(box.origin.x + box.size.width))
        let maxY = min(frame.height - 1, Int(box.origin.y + box.size.height))
        if maxX <= minX || maxY <= minY { return false }

        let boxW = maxX - minX
        let boxH = maxY - minY
        let margin = max(6, Int(Double(min(boxW, boxH)) * 0.08))
        let ringMinX = max(0, minX - margin)
        let ringMinY = max(0, minY - margin)
        let ringMaxX = min(frame.width - 1, maxX + margin)
        let ringMaxY = min(frame.height - 1, maxY + margin)

        var whiteCount = 0
        var total = 0
        let step = 2
        var y = ringMinY
        while y <= ringMaxY {
            var x = ringMinX
            while x <= ringMaxX {
                let inBox = x >= minX && x <= maxX && y >= minY && y <= maxY
                if !inBox {
                    let luma = lumaAt(frame, x: x, y: y)
                    total += 1
                    if luma >= 230 { whiteCount += 1 }
                }
                x += step
            }
            y += step
        }
        if total == 0 { return false }
        return Double(whiteCount) / Double(total) >= 0.7
    }

    private func passesTextureCheck(frame: FrameLuma, box: CGRect) -> Bool {
        let minX = max(0, Int(box.origin.x))
        let minY = max(0, Int(box.origin.y))
        let maxX = min(frame.width - 1, Int(box.origin.x + box.size.width))
        let maxY = min(frame.height - 1, Int(box.origin.y + box.size.height))
        if maxX <= minX || maxY <= minY { return false }

        let boxW = maxX - minX
        let boxH = maxY - minY
        let inset = max(6, Int(Double(min(boxW, boxH)) * 0.08))
        let startX = minX + inset
        let endX = maxX - inset
        let startY = minY + inset
        let endY = maxY - inset
        if endX <= startX || endY <= startY { return false }

        var count = 0
        var mean = 0.0
        var m2 = 0.0
        var deviation = 0.0
        let step = 2
        var y = startY
        while y <= endY {
            var x = startX
            while x <= endX {
                let luma = lumaAt(frame, x: x, y: y)
                if luma >= 200 {
                    let lumaRight = lumaAt(frame, x: min(x + 1, frame.width - 1), y: y)
                    let lumaDown = lumaAt(frame, x: x, y: min(y + 1, frame.height - 1))
                    let gradient = abs(luma - lumaRight) + abs(luma - lumaDown)
                    if gradient <= 12 {
                        count += 1
                        let delta = luma - mean
                        mean += delta / Double(count)
                        m2 += delta * (luma - mean)
                        deviation += abs(luma - (lumaRight + lumaDown) / 2.0)
                    }
                }
                x += step
            }
            y += step
        }
        if count < 160 { return false }
        let variance = m2 / Double(max(1, count - 1))
        let avgDeviation = deviation / Double(count)
        return variance >= 14 && avgDeviation >= 4
    }
}
