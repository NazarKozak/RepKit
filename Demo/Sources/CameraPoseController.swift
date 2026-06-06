//
//  CameraPoseController.swift
//  RepKitDemo
//
//  Created by Nazar Kozak on 05.06.2026.
//
//  Drives the camera, runs RepKit's VisionPoseSource on each frame, feeds a
//  RepDetector, and publishes the pose + rep count for the UI.
//

import Foundation
@preconcurrency import AVFoundation
import CoreVideo
import RepKit

@Observable
final class CameraPoseController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    let session = AVCaptureSession()

    // Observable UI state (written on the main queue).
    var exercise: Exercise
    var landmarks: PoseLandmarks?
    var count = 0
    var feedback: String?

    private let output = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "repkit.demo.camera")
    private let vision = VisionPoseSource()
    private var detector: RepDetector   // touched only on `queue`

    init(exercise: Exercise = .squat) {
        self.exercise = exercise
        self.detector = RepDetector(exercise: exercise)
        super.init()
        configure()
    }

    func setExercise(_ newValue: Exercise) {
        exercise = newValue
        count = 0
        feedback = nil
        queue.async { [weak self] in self?.detector = RepDetector(exercise: newValue) }
    }

    func reset() {
        count = 0
        feedback = nil
        queue.async { [weak self] in self?.detector.reset() }
    }

    func start() {
        queue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stop() {
        queue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    private func configure() {
        session.beginConfiguration()
        session.sessionPreset = .hd1280x720
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) {
            session.addInput(input)
        }
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: queue)
        if session.canAddOutput(output) { session.addOutput(output) }
        if let connection = output.connection(with: .video), connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90 // portrait buffers
        }
        session.commitConfiguration()
    }

    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let detected = vision.landmarks(in: buffer, orientation: .up)
        let update = detected.map { detector.process($0) } ?? .idle
        let total = detector.count
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.landmarks = detected
            self.count = total
            if case .formIssue(let message) = update { self.feedback = message }
        }
    }
}
