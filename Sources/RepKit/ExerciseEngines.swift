//
//  ExerciseEngines.swift
//  RepKit
//
//  Created by Nazar Kozak on 05.06.2026.
//
//  One engine interprets any ``ExerciseSpec``. The original rep logic (ported
//  from the QuickPose-based Sidequest app onto free Apple Vision): a hysteresis
//  main counter plus per-gate counters that must all agree, so half-reps and
//  one-sided cheating don't count.
//

import Foundation

protocol ExerciseEngine: AnyObject {
    func update(_ landmarks: PoseLandmarks, at time: TimeInterval) -> RepUpdate
    var count: Int { get }
    func reset()
}

final class SpecEngine: ExerciseEngine {
    private let spec: ExerciseSpec
    private var main = ThresholdCounter()
    private var gateCounters: [ThresholdCounter] = []
    private var timer = ThresholdTimer()
    private var lastSeconds = 0
    private(set) var count = 0

    init(_ spec: ExerciseSpec) {
        self.spec = spec
        switch spec.kind {
        case let .reps(_, gates, enter, exit, _):
            main = ThresholdCounter(enter: enter, exit: exit)
            gateCounters = gates.map { _ in ThresholdCounter(enter: enter, exit: exit) }
        case let .hold(_, threshold):
            timer = ThresholdTimer(threshold: threshold)
        }
    }

    func update(_ landmarks: PoseLandmarks, at time: TimeInterval) -> RepUpdate {
        switch spec.kind {
        case let .reps(progress, gates, _, _, formTip):
            guard let value = progress(landmarks) else { return .idle }

            // Each gate accumulates progress only while it is satisfied.
            for index in gates.indices {
                gateCounters[index].count(gates[index](landmarks) ? value : 0)
            }

            guard main.count(value) else { return .idle }

            // A rep only counts if every gate kept pace with the main counter.
            if gateCounters.allSatisfy({ $0.count == main.count }) {
                count = main.count
                return .rep(count: count)
            } else {
                main.reset()
                for index in gateCounters.indices { gateCounters[index].reset() }
                count = 0
                return .formIssue(formTip)
            }

        case let .hold(progress, _):
            guard let value = progress(landmarks) else { return .idle }
            let held = Int(timer.time(value, at: time))
            if held > lastSeconds {
                lastSeconds = held
                count = held
                return .holding(seconds: held)
            }
            return .idle
        }
    }

    func reset() {
        main.reset()
        for index in gateCounters.indices { gateCounters[index].reset() }
        timer.reset()
        lastSeconds = 0
        count = 0
    }
}
