import SwiftUI

/// Draws a bar with two endpoints in view coordinates and reports the normalized bar midpoint.
/// - Parameters:
///   - barPoints: Endpoints in view coordinates.
///   - color: Stroke and marker color.
///   - onBarYUpdate: Callback with the normalized (0...1) bar midpoint y.
struct BarOverlayView: View {
    let barPoints: [CGPoint]
    let color: Color
    var onBarYUpdate: (CGFloat) -> Void

    var body: some View {
        GeometryReader { geo in
            let points = barPoints
            if points.count == 2 {
                Path { path in
                    path.move(to: points[0])
                    path.addLine(to: points[1])
                }
                .stroke(color, lineWidth: 4)

                ForEach(points, id: \.self) { point in
                    Circle()
                        .fill(color)
                        .frame(width: 16, height: 16)
                        .position(point)
                }

                Color.clear.onAppear {
                    let midY = (points[0].y + points[1].y) / 2
                    let normalized = midY / geo.size.height
                    onBarYUpdate(normalized)
                }
            }
        }
    }
}
