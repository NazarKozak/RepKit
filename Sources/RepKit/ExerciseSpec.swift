//
//  ExerciseSpec.swift
//  RepKit
//
//  Created by Nazar Kozak on 05.06.2026.
//
//  A declarative description of an exercise. Built-ins and custom exercises both
//  compile down to a spec, which one engine interprets. Define your own in a few
//  lines — a progress signal (0…1) plus optional anti-cheat gates.
//

import Foundation

/// Describes how to detect one exercise from a stream of poses.
public struct ExerciseSpec: Sendable {
    public let name: String
    let kind: Kind

    enum Kind: Sendable {
        /// Rep-counted: count rise-past-`enter` / fall-past-`exit` cycles of `progress`.
        /// A rep only counts when every `gate` was satisfied during it (anti-cheat).
        case reps(progress: @Sendable (PoseLandmarks) -> Double?,
                  gates: [@Sendable (PoseLandmarks) -> Bool],
                  enter: Double,
                  exit: Double,
                  formTip: String)
        /// Held: accumulate seconds while `progress` stays above `threshold`.
        case hold(progress: @Sendable (PoseLandmarks) -> Double?,
                  threshold: Double)
    }

    /// Whether this exercise accumulates a held duration rather than counting reps.
    public var isTimed: Bool {
        if case .hold = kind { return true }
        return false
    }
}

// MARK: - DSL

public extension ExerciseSpec {
    /// A rep-counted exercise.
    ///
    /// - Parameters:
    ///   - progress: 0…1 signal; ~1 at the bottom/top of a rep, ~0 at rest.
    ///   - gates: predicates that must each hold during a rep, or it's rejected as
    ///     a form issue (e.g. "left knee bent past 140°", "right knee bent past 140°").
    static func reps(
        name: String,
        enter: Double = 0.95,
        exit: Double = 0.05,
        formTip: String = "Use full range of motion",
        gates: [@Sendable (PoseLandmarks) -> Bool] = [],
        progress: @escaping @Sendable (PoseLandmarks) -> Double?
    ) -> ExerciseSpec {
        ExerciseSpec(name: name, kind: .reps(progress: progress, gates: gates, enter: enter, exit: exit, formTip: formTip))
    }

    /// A held exercise (e.g. a plank).
    static func hold(
        name: String,
        threshold: Double = 0.2,
        progress: @escaping @Sendable (PoseLandmarks) -> Double?
    ) -> ExerciseSpec {
        ExerciseSpec(name: name, kind: .hold(progress: progress, threshold: threshold))
    }
}
