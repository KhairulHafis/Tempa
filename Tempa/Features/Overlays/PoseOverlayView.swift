import SwiftUI

/// Renders a simple pose overlay (neck–shoulders, shoulders–wrists) using normalized points (0...1).
/// Denormalizes points to the local view size for drawing and highlights wrists and neck.
struct PoseOverlayView: View {
    let neck: CGPoint?
    let leftShoulder: CGPoint?
    let rightShoulder: CGPoint?
    let leftWrist: CGPoint?
    let rightWrist: CGPoint?

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            Path { path in
                if let neck = neck?.denormalized(in: size),
                   let lShoulder = leftShoulder?.denormalized(in: size),
                   let rShoulder = rightShoulder?.denormalized(in: size) {
                    path.move(to: neck)
                    path.addLine(to: lShoulder)
                    path.move(to: neck)
                    path.addLine(to: rShoulder)
                }
                if let lShoulder = leftShoulder?.denormalized(in: size),
                   let lWrist = leftWrist?.denormalized(in: size) {
                    path.move(to: lShoulder)
                    path.addLine(to: lWrist)
                }
                if let rShoulder = rightShoulder?.denormalized(in: size),
                   let rWrist = rightWrist?.denormalized(in: size) {
                    path.move(to: rShoulder)
                    path.addLine(to: rWrist)
                }
            }
            .stroke(AppTheme.Colors.success, lineWidth: 4)

            if let neck = neck?.denormalized(in: size) {
                EnlargedPulsingCircle().position(neck)
            }

            if let lw = leftWrist?.denormalized(in: size) {
                Circle().stroke(AppTheme.Colors.success, lineWidth: 3).frame(width: 20, height: 20).position(lw)
            }
            if let rw = rightWrist?.denormalized(in: size) {
                Circle().stroke(AppTheme.Colors.success, lineWidth: 3).frame(width: 20, height: 20).position(rw)
            }
        }
    }
}

private extension CGPoint {
    func denormalized(in size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width, y: y * size.height)
    }
}
