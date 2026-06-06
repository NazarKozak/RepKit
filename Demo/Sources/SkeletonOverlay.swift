//
//  SkeletonOverlay.swift
//  RepKitDemo
//
//  Created by Nazar Kozak on 05.06.2026.
//

import SwiftUI
import RepKit

/// Draws the detected skeleton over the camera preview.
struct SkeletonOverlay: View {
    let landmarks: PoseLandmarks?

    private static let bones: [(Joint, Joint)] = [
        (.leftShoulder, .rightShoulder),
        (.leftHip, .rightHip),
        (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee), (.rightKnee, .rightAnkle)
    ]

    var body: some View {
        Canvas { context, size in
            guard let landmarks else { return }

            // Vision points are normalized with a bottom-left origin.
            func map(_ joint: Joint) -> CGPoint? {
                guard let p = landmarks[joint] else { return nil }
                return CGPoint(x: p.x * size.width, y: (1 - p.y) * size.height)
            }

            for (a, b) in Self.bones {
                guard let pa = map(a), let pb = map(b) else { continue }
                var path = Path()
                path.move(to: pa)
                path.addLine(to: pb)
                context.stroke(path, with: .color(.green.opacity(0.9)), lineWidth: 4)
            }

            for joint in jointsToDot {
                guard let p = map(joint) else { continue }
                let r: CGFloat = 5
                context.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                             with: .color(.white))
            }
        }
        .allowsHitTesting(false)
    }

    private var jointsToDot: [Joint] {
        [.leftShoulder, .rightShoulder, .leftElbow, .rightElbow, .leftWrist, .rightWrist,
         .leftHip, .rightHip, .leftKnee, .rightKnee, .leftAnkle, .rightAnkle]
    }
}
