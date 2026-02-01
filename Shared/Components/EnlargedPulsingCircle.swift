import SwiftUI

/// A reusable pulsing circle indicator.
///
/// Displays a stroked circle that gently scales and fades in a repeating animation.
/// Useful for highlighting a tracked joint or focus point in overlays.
///
/// Usage:
/// ```swift
/// EnlargedPulsingCircle()
///     .position(point)
/// ```
public struct EnlargedPulsingCircle: View {
    @State private var animate = false
    /// Creates a new pulsing circle with default styling.
    public init() {}
    public var body: some View {
        Circle()
            .stroke(Color.blue, lineWidth: 4)
            .frame(width: 50, height: 50)
            .scaleEffect(animate ? 1.2 : 1.0)
            .opacity(animate ? 0.5 : 1.0)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    animate = true
                }
            }
    }
}
