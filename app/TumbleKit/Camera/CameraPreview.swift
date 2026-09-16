import AVFoundation
import CoreImage
import Metal
import QuartzCore
import SwiftUI
import UIKit

/// Live viewfinder backed by `AVCaptureVideoPreviewLayer`.
public struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    public init(session: AVCaptureSession) { self.session = session }

    public func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.updatePortraitOrientation()
        return view
    }

    public func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.updatePortraitOrientation()
    }

    public final class PreviewView: UIView {
        public override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }

        public override func layoutSubviews() {
            super.layoutSubviews()
            updatePortraitOrientation()
        }

        func updatePortraitOrientation() {
            guard let connection = videoPreviewLayer.connection,
                  connection.isVideoRotationAngleSupported(90) else { return }
            connection.videoRotationAngle = 90
        }
    }
}

/// Deterministic cadence controller for the live camera. A slow or thermally
/// constrained renderer drops to 30 FPS quickly, then waits for sustained
/// headroom before attempting 60 FPS again.
public struct AdaptiveFrameRatePolicy: Sendable {
    public private(set) var targetFPS: Int
    private var samples: [Double] = []
    private var fastSampleCount = 0

    public init(targetFPS: Int = 60) {
        self.targetFPS = targetFPS == 30 ? 30 : 60
    }

    /// Returns a new target only when the cadence changes.
    public mutating func record(renderDuration: Double, thermallyConstrained: Bool) -> Int? {
        if thermallyConstrained {
            fastSampleCount = 0
            samples.removeAll(keepingCapacity: true)
            guard targetFPS != 30 else { return nil }
            targetFPS = 30
            return 30
        }

        samples.append(renderDuration)
        if samples.count > 30 { samples.removeFirst() }

        if targetFPS == 60, samples.count == 30 {
            let overBudget = samples.filter { $0 > 1.0 / 55.0 }.count
            if overBudget >= 8 {
                targetFPS = 30
                fastSampleCount = 0
                samples.removeAll(keepingCapacity: true)
                return 30
            }
        } else if targetFPS == 30 {
            if renderDuration < 1.0 / 75.0 {
                fastSampleCount += 1
            } else {
                fastSampleCount = 0
            }
            if fastSampleCount >= 300 {
                targetFPS = 60
                fastSampleCount = 0
                samples.removeAll(keepingCapacity: true)
                return 60
            }
        }
        return nil
    }
}

/// Single-consumer mailbox that replaces pending work with the newest value.
/// The caller supplies synchronization; keeping it separate makes the camera's
/// no-backlog behavior deterministic and directly testable.
struct LatestValueMailbox<Value> {
    private var latest: Value?
    private var isDraining = false

    /// Returns true only when a consumer needs to be scheduled.
    mutating func submit(_ value: Value) -> Bool {
        latest = value
        guard !isDraining else { return false }
        isDraining = true
        return true
    }

    mutating func take() -> Value? {
        guard let latest else {
            isDraining = false
            return nil
        }
        self.latest = nil
        return latest
    }
}

enum LivePreviewGeometry {
    static func mirroredHorizontally(_ image: CIImage) -> CIImage {
        let extent = image.extent
        return image
            .transformed(by: CGAffineTransform(scaleX: -1, y: 1))
            .transformed(by: CGAffineTransform(translationX: extent.minX + extent.maxX, y: 0))
    }

    static func aspectFill(_ image: CIImage, into bounds: CGRect) -> CIImage {
        guard image.extent.width > 0, image.extent.height > 0,
              bounds.width > 0, bounds.height > 0 else { return image }
        let scale = max(bounds.width / image.extent.width, bounds.height / image.extent.height)
        let scaled = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let crop = CGRect(
            x: scaled.extent.midX - bounds.width / 2,
            y: scaled.extent.midY - bounds.height / 2,
            width: bounds.width,
            height: bounds.height
        )
        return scaled.cropped(to: crop).transformed(
            by: CGAffineTransform(translationX: -crop.minX, y: -crop.minY)
        )
    }
}

/// A Metal-backed destination for the filtered viewfinder. Camera frames are
/// rendered straight from `CVPixelBuffer` into a drawable, avoiding a CGImage,
/// UIImage, and SwiftUI state update for every frame.
public final class LiveCameraRenderer: @unchecked Sendable {
    private struct Recipe: Sendable {
        var stock: FilmStock
        var intensity: Double
        var mirrored: Bool
    }

    private let lock = NSLock()
    private let renderQueue = DispatchQueue(label: "com.tumble.camera.metal", qos: .userInteractive)
    private let device: MTLDevice?
    private let commandQueue: MTLCommandQueue?
    private let context: CIContext?
    private let colorSpace: CGColorSpace
    private weak var layer: CAMetalLayer?
    private var recipe = Recipe(stock: FilmStockCatalog.defaultStock, intensity: 1, mirrored: false)
    private var pendingFrames = LatestValueMailbox<CVPixelBuffer>()
    private var lastAcceptedTime: CFTimeInterval = 0
    private var policy = AdaptiveFrameRatePolicy()

    public var isAvailable: Bool { device != nil && commandQueue != nil && context != nil }
    public var onTargetFrameRateChanged: (@Sendable (Int) -> Void)?

    public init() {
        let device = MTLCreateSystemDefaultDevice()
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        self.device = device
        self.colorSpace = colorSpace
        commandQueue = device?.makeCommandQueue()
        context = device.map {
            CIContext(mtlDevice: $0, options: [
                .workingColorSpace: colorSpace,
                .outputColorSpace: colorSpace,
                .cacheIntermediates: false,
            ])
        }
    }

    fileprivate func attach(to layer: CAMetalLayer?) {
        lock.lock()
        self.layer = layer
        lock.unlock()
    }

    public func update(stock: FilmStock, intensity: Double, mirrored: Bool) {
        lock.lock()
        recipe = Recipe(stock: stock, intensity: intensity, mirrored: mirrored)
        lock.unlock()
    }

    public func enqueue(_ pixelBuffer: CVPixelBuffer) {
        guard isAvailable else { return }
        let now = CACurrentMediaTime()
        lock.lock()
        let minimumInterval = 1.0 / Double(policy.targetFPS)
        guard now - lastAcceptedTime >= minimumInterval else {
            lock.unlock()
            return
        }
        lastAcceptedTime = now
        let shouldSchedule = pendingFrames.submit(pixelBuffer)
        lock.unlock()

        if shouldSchedule {
            renderQueue.async { [weak self] in self?.drainLatestFrames() }
        }
    }

    private func drainLatestFrames() {
        while true {
            lock.lock()
            guard let frame = pendingFrames.take() else {
                lock.unlock()
                return
            }
            let recipe = recipe
            let targetFPS = policy.targetFPS
            let layer = layer
            lock.unlock()

            guard let layer, let drawable = layer.nextDrawable(),
                  let context, let commandQueue, let commandBuffer = commandQueue.makeCommandBuffer()
            else { continue }

            let started = CACurrentMediaTime()
            let maxDimension: CGFloat = targetFPS == 60 ? 720 : 960
            var output = TumblePhotoFilter.livePreviewImage(
                from: frame,
                stock: recipe.stock,
                intensity: recipe.intensity,
                maxDimension: maxDimension
            )
            if recipe.mirrored {
                output = LivePreviewGeometry.mirroredHorizontally(output)
            }

            let bounds = CGRect(origin: .zero, size: layer.drawableSize)
            output = LivePreviewGeometry.aspectFill(output, into: bounds)
            context.render(output, to: drawable.texture, commandBuffer: commandBuffer, bounds: bounds, colorSpace: colorSpace)
            commandBuffer.present(drawable)
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()

            let duration = CACurrentMediaTime() - started
            let thermal = ProcessInfo.processInfo.thermalState
            let constrained = thermal == .serious || thermal == .critical
            lock.lock()
            let changed = policy.record(renderDuration: duration, thermallyConstrained: constrained)
            lock.unlock()
            if let changed { onTargetFrameRateChanged?(changed) }
        }
    }

}

/// The production live film preview. The raw preview layer remains underneath
/// as a zero-cost fallback if Metal is unavailable or before the first filtered
/// frame arrives.
public struct LiveFilmCameraPreview: UIViewRepresentable {
    public let session: AVCaptureSession
    public let renderer: LiveCameraRenderer

    public init(session: AVCaptureSession, renderer: LiveCameraRenderer) {
        self.session = session
        self.renderer = renderer
    }

    public func makeUIView(context: Context) -> LivePreviewContainer {
        let view = LivePreviewContainer(session: session, renderer: renderer)
        return view
    }

    public func updateUIView(_ uiView: LivePreviewContainer, context: Context) {
        uiView.updatePortraitOrientation()
    }

    public static func dismantleUIView(_ uiView: LivePreviewContainer, coordinator: ()) {
        uiView.detachRenderer()
    }

    public final class LivePreviewContainer: UIView {
        private let rawPreview = CameraPreview.PreviewView()
        private let metalPreview = MetalPreviewView()
        private let renderer: LiveCameraRenderer

        init(session: AVCaptureSession, renderer: LiveCameraRenderer) {
            self.renderer = renderer
            super.init(frame: .zero)
            rawPreview.videoPreviewLayer.session = session
            rawPreview.videoPreviewLayer.videoGravity = .resizeAspectFill
            addSubview(rawPreview)
            if renderer.isAvailable {
                addSubview(metalPreview)
                renderer.attach(to: metalPreview.metalLayer)
            }
            updatePortraitOrientation()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        public override func layoutSubviews() {
            super.layoutSubviews()
            rawPreview.frame = bounds
            metalPreview.frame = bounds
            updatePortraitOrientation()
        }

        func updatePortraitOrientation() { rawPreview.updatePortraitOrientation() }
        func detachRenderer() { renderer.attach(to: nil) }
    }
}

private final class MetalPreviewView: UIView {
    override class var layerClass: AnyClass { CAMetalLayer.self }
    var metalLayer: CAMetalLayer { layer as! CAMetalLayer }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        metalLayer.isOpaque = false
        metalLayer.device = MTLCreateSystemDefaultDevice()
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = false
        metalLayer.colorspace = CGColorSpace(name: CGColorSpace.sRGB)
        metalLayer.contentsScale = UIScreen.main.scale
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        metalLayer.drawableSize = CGSize(
            width: max(1, bounds.width * contentScaleFactor),
            height: max(1, bounds.height * contentScaleFactor)
        )
    }
}
