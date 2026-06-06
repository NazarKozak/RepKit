//
//  ContentView.swift
//  RepKitDemo
//
//  Created by Nazar Kozak on 05.06.2026.
//

import SwiftUI
import RepKit

struct ContentView: View {
    @State private var camera = CameraPoseController(exercise: .squat)

    var body: some View {
        ZStack {
            CameraPreview(session: camera.session)
                .ignoresSafeArea()
            SkeletonOverlay(landmarks: camera.landmarks)
                .ignoresSafeArea()

            VStack {
                header
                Spacer()
                footer
            }
            .padding()
        }
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Menu {
                Picker("Exercise", selection: Binding(
                    get: { camera.exercise },
                    set: { camera.setExercise($0) }
                )) {
                    ForEach(Exercise.allCases, id: \.self) { exercise in
                        Text(exercise.spec.name).tag(exercise)
                    }
                }
            } label: {
                HStack {
                    Text(camera.exercise.spec.name).font(.headline)
                    Image(systemName: "chevron.up.chevron.down").font(.caption)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(.black.opacity(0.4), in: Capsule())
                .foregroundStyle(.white)
            }

            if let feedback = camera.feedback {
                Text(feedback)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.yellow)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(.black.opacity(0.4), in: Capsule())
            }
        }
    }

    private var footer: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                Text(camera.exercise.isTimed ? "SECONDS" : "REPS")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.7))
                Text("\(camera.count)")
                    .font(.system(size: 72, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: camera.count)
            }
            .shadow(radius: 8)

            Spacer()

            Button {
                camera.reset()
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(.white.opacity(0.2), in: Capsule())
                    .foregroundStyle(.white)
            }
        }
    }
}

#Preview {
    ContentView()
}
