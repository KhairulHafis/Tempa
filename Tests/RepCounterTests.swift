#if canImport(Testing)
// Guarded so the main app target builds without the Testing module. Add this file to a test target to enable.
import Testing
import CoreGraphics

@Suite("RepCounter behavior")
struct RepCounterTests {
    @Test("Completes a rep after descending then ascending past thresholds")
    func completesRep() {
        var counter = RepCounter()
        let config = RepDetectionConfig() // normalized defaults
        let barY: CGFloat = 0.5

        // Initial sample above the bar
        #expect(counter.update(avgY: 0.60, barY: barY, config: config) == false)
        // Move upward (y decreasing) into bottom range fast enough
        #expect(counter.update(avgY: 0.54, barY: barY, config: config) == false)
        // Move downward (y increasing) past top threshold fast enough -> completes rep
        #expect(counter.update(avgY: 0.58, barY: barY, config: config) == true)
        // Next steady sample should not double count
        #expect(counter.update(avgY: 0.585, barY: barY, config: config) == false)
    }

    @Test("Does not count if motion is too small or slow")
    func ignoresSmallMotion() {
        var counter = RepCounter()
        let config = RepDetectionConfig()
        let barY: CGFloat = 0.5

        #expect(counter.update(avgY: 0.52, barY: barY, config: config) == false)
        #expect(counter.update(avgY: 0.519, barY: barY, config: config) == false)
        #expect(counter.update(avgY: 0.518, barY: barY, config: config) == false)
        #expect(counter.update(avgY: 0.517, barY: barY, config: config) == false)
    }
}
#endif

