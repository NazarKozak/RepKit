//
//  Exercise.swift
//  RepCounterSDK
//
//  Created by Nazar Kozak on 05.06.2026.
//

import Foundation

/// The exercises RepCounterSDK detects out of the box. Each compiles to an ``ExerciseSpec``;
/// define your own with the `ExerciseSpec.reps`/`.hold` DSL.
public enum Exercise: Sendable, CaseIterable {
    case squat
    case pushUp
    case lunge
    case bicepCurl
    case shoulderPress
    case plank

    public var isTimed: Bool { spec.isTimed }

    /// The detection rules for this exercise.
    public var spec: ExerciseSpec {
        switch self {
        case .squat:
            .reps(name: "Squat",
                  formTip: "Bend both knees fully",
                  gates: [Gate.bent({ $0.kneeAngle($1) }, .left, below: 140),
                          Gate.bent({ $0.kneeAngle($1) }, .right, below: 140)],
                  progress: { $0.depth(of: $0.kneeAngle, standing: 160, deep: 95) })

        case .pushUp:
            .reps(name: "Push-up",
                  formTip: "Lower fully on both arms",
                  gates: [Gate.bent({ $0.elbowAngle($1) }, .left, below: 150),
                          Gate.bent({ $0.elbowAngle($1) }, .right, below: 150)],
                  progress: { $0.depth(of: $0.elbowAngle, standing: 165, deep: 90) })

        case .lunge:
            .reps(name: "Lunge",
                  formTip: "Bend both knees",
                  gates: [Gate.bent({ $0.kneeAngle($1) }, .left, below: 150),
                          Gate.bent({ $0.kneeAngle($1) }, .right, below: 150)],
                  progress: { $0.depth(of: $0.kneeAngle, standing: 165, deep: 100) })

        case .bicepCurl:
            // Either arm curling counts; no anti-cheat gate.
            .reps(name: "Bicep curl", enter: 0.9, exit: 0.1,
                  progress: { $0.depth(of: $0.elbowAngle, standing: 160, deep: 50) })

        case .shoulderPress:
            .reps(name: "Shoulder press",
                  formTip: "Press both arms fully overhead",
                  gates: [Gate.wristAboveShoulder(.left), Gate.wristAboveShoulder(.right)],
                  // "Depth" here is full overhead extension: both elbows straight.
                  progress: { $0.depth(of: $0.elbowAngle, standing: 90, deep: 165) })

        case .plank:
            .hold(name: "Plank",
                  progress: { $0.hipAngle().map { PoseMath.normalize($0, from: 140, to: 180) } })
        }
    }
}

/// Convenience builders for common anti-cheat gates.
enum Gate {
    /// True while `angle(pose, side)` is bent below `below` degrees.
    static func bent(_ angle: @escaping @Sendable (PoseLandmarks, Side) -> Double?,
                     _ side: Side, below: Double) -> @Sendable (PoseLandmarks) -> Bool {
        { (angle($0, side) ?? .greatestFiniteMagnitude) < below }
    }

    /// True while a side's wrist is above its shoulder (e.g. pressed overhead).
    static func wristAboveShoulder(_ side: Side) -> @Sendable (PoseLandmarks) -> Bool {
        { landmarks in
            let wrist: Joint = side == .left ? .leftWrist : .rightWrist
            let shoulder: Joint = side == .left ? .leftShoulder : .rightShoulder
            guard let w = landmarks[wrist], let s = landmarks[shoulder] else { return false }
            return w.y > s.y   // Vision y-axis points up
        }
    }
}

/// The result of feeding one pose to a ``RepDetector``.
public enum RepUpdate: Sendable, Equatable {
    case idle
    case rep(count: Int)
    case holding(seconds: Int)
    case formIssue(String)
}
