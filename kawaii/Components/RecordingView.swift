import SwiftUI

/// A purely visual mock-up of an audio recording screen:
/// – A red waveform rendered as small vertical bars that span the width of the view.
/// – A white vertical center line.
/// – A timestamp pill displayed above the center line.
///
/// Behavioural aspects (live audio levels, elapsed time, etc.) are *not* implemented – this is strictly a design scaffold.
struct RecordingView: View {
    /// The timestamp to display. In a future functional implementation this could be bound to a timer.
    var timestamp: String = "00:16.53"

    // MARK: - Styling constants
    private let barWidth: CGFloat = 3
    private let barSpacing: CGFloat = 2
    private let minBarHeight: CGFloat = 8
    private let maxBarHeight: CGFloat = 40

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Waveform
                HStack(alignment: .center, spacing: barSpacing) {
                    ForEach(0 ..< Int(geometry.size.width / (barWidth + barSpacing)), id: \.self) { _ in
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: barWidth,
                                   height: CGFloat.random(in: minBarHeight ... maxBarHeight))
                    }
                }
                .frame(height: maxBarHeight)

                // Center white vertical line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: geometry.size.height)

                // Timestamp pill
                VStack {
                    Text(timestamp)
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
    }
}

// MARK: - Preview
struct RecordingView_Previews: PreviewProvider {
    static var previews: some View {
        RecordingView()
            .frame(height: 100)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.95, green: 0.96, blue: 0.97),
                                                 Color(red: 0.88, green: 0.92, blue: 0.94)]),
                    startPoint: .top,
                    endPoint: .bottom)
            )
            .previewLayout(.sizeThatFits)
    }
}
