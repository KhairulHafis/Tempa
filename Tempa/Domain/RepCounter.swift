import CoreGraphics

/// Configuration for rep detection thresholds using normalized coordinates (0...1 of view height).
/// - downVelocity: Negative velocity threshold (y decreasing) to enter the descending phase.
/// - upVelocity: Positive velocity threshold (y increasing) to complete a rep.
/// - bottomOffset: Distance below the bar to consider the bottom range.
/// - topOffset: Distance above the bar to consider the top range.
public struct RepDetectionConfig {
    /// Negative velocity threshold in normalized units (y decreasing).
    public var downVelocity: CGFloat
    /// Positive velocity threshold in normalized units (y increasing).
    public var upVelocity: CGFloat
    /// How far above the bar (normalized) we consider the bottom of the rep range.
    public var bottomOffset: CGFloat
    /// How far below the bar (normalized) we consider the top of the rep range.
    public var topOffset: CGFloat

    public init(downVelocity: CGFloat = -0.0048,
                upVelocity: CGFloat = 0.0048,
                bottomOffset: CGFloat = 0.047,
                topOffset: CGFloat = 0.071) {
        self.downVelocity = downVelocity
        self.upVelocity = upVelocity
        self.bottomOffset = bottomOffset
        self.topOffset = topOffset
    }
}

/// Small state machine that converts vertical shoulder/neck motion into completed reps.
/// Operates in normalized coordinates (0...1). Call `update(avgY:barY:config:)` for each sample; returns true exactly when a rep completes.
public struct RepCounter {
    private enum Phase { case idle, descending }
    private var phase: Phase = .idle
    private var lastY: CGFloat?

    public init() {}

    /// Update the counter with the latest average Y position of relevant joints.
    /// - Parameters:
    ///   - avgY: Average Y of left shoulder, right shoulder, and neck (normalized).
    ///   - barY: The Y position of the bar midpoint (normalized).
    ///   - config: Detection thresholds and offsets (normalized).
    /// - Returns: `true` if a rep was completed on this update.
    public mutating func update(avgY: CGFloat, barY: CGFloat, config: RepDetectionConfig) -> Bool {
        defer { lastY = avgY }
        guard let lastY else { return false }

        let velocity = avgY - lastY

        switch phase {
        case .idle:
            // Enter descending phase when moving upward fast enough and within the bottom range relative to the bar.
            if velocity < config.downVelocity && avgY < barY + config.bottomOffset {
                phase = .descending
            }
        case .descending:
            // Complete rep when moving downward fast enough and above the top threshold.
            if velocity > config.upVelocity && avgY > barY + config.topOffset {
                phase = .idle
                return true
            }
        }

        return false
    }
}
