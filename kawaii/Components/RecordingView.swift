import SwiftUI

/// A purely visual mock-up of an audio recording screen:
/// – A red waveform rendered as small vertical bars that span the width of the view.
/// – A white vertical center line.
/// – A timestamp pill displayed above the center line.
///
/// Behavioural aspects (live audio levels, elapsed time, etc.) are *not* implemented – this is strictly a design scaffold.
struct RecordingView: View {
    // MARK: - State
    /// Elapsed time in seconds – increments once per second.
    @State private var elapsed: TimeInterval = 0

    // MARK: - Styling constants
    private let barWidth: CGFloat = 3
    private let barSpacing: CGFloat = 2
    private let minBarHeight: CGFloat = 8
    private let maxBarHeight: CGFloat = 40

    /// Formats `elapsed` into mm:ss.
    private var formattedElapsed: String {
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        let centiseconds = Int((elapsed * 100).truncatingRemainder(dividingBy: 100))
        return String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated waveform
                ScrollingWaveformView(width: geometry.size.width,
                                      barWidth: barWidth,
                                      barSpacing: barSpacing,
                                      minBarHeight: minBarHeight,
                                      maxBarHeight: maxBarHeight)
                    .frame(height: maxBarHeight)

                // Center white vertical line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: geometry.size.height)

                // Timestamp pill
                VStack {
                    Text(formattedElapsed)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    Spacer()
                }
            }
            // Stretch content to entire view bounds
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // Update elapsed time every second.
        .onReceive(Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()) { _ in
            elapsed += 0.01
        }
    }
}

// MARK: - Convenience Modifier
public extension View {
    /// Overlays the `RecordingView` on top of the current view in a single line.
    /// Usage: `SomeView().recordingOverlay()`
    /// - Parameter height: Desired height for the waveform component.
    /// - Returns: A view with the recording overlay applied.
    func recordingOverlay(height: CGFloat = 120) -> some View {
        self.overlay(
            RecordingView()
                .frame(height: height)
        )
    }
}

// MARK: - Animated Waveform
/// Produces a scrolling red waveform by continuously appending random bar heights and
/// removing the oldest bar, giving the illusion of left-to-right movement.
private struct ScrollingWaveformView: View {
    let width: CGFloat
    let barWidth: CGFloat
    let barSpacing: CGFloat
    let minBarHeight: CGFloat
    let maxBarHeight: CGFloat

    @State private var bars: [CGFloat] = []

    var body: some View {
        HStack(alignment: .center, spacing: barSpacing) {
            ForEach(Array(bars.enumerated()), id: \.offset) { _, height in
                Rectangle()
                    .fill(Color.red)
                    .frame(width: barWidth, height: height)
            }
        }
        .onAppear {
            initializeBars()
        }
        .onReceive(Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()) { _ in
            advanceWave()
        }
    }

    // Initial fills the bars to match the available width.
    private func initializeBars() {
        let count = barCapacity
        bars = (0 ..< count).map { _ in randomHeight }
    }

    // Adds a new random bar at the end and removes the first to create motion.
    private func advanceWave() {
        bars.append(randomHeight)
        if bars.count > barCapacity {
            bars.removeFirst()
        }
    }

    private var barCapacity: Int {
        max(1, Int(width / (barWidth + barSpacing)) + 2)
    }

    private var randomHeight: CGFloat {
        CGFloat.random(in: minBarHeight ... maxBarHeight)
    }
}

// MARK: - Preview
struct RecordingView_Previews: PreviewProvider {
    static var previews: some View {
        RecordingView()
            .frame(height: 120)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
