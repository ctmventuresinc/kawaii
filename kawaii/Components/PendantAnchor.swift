import SwiftUI

/// Wrap any pendant-like SwiftUI view so that its *top-centre* automatically aligns with
/// the position you place it at using `.position(x:y:)`.
///
/// Usage:
/// ```swift
/// PendantAnchor {
///    MyPendantView()
/// }
/// .position(x: anchorX, y: anchorY) // anchorY = bead.position.y
/// ```
struct PendantAnchor<Content: View>: View {
    @State private var halfHeight: CGFloat = 0
    let content: Content
    let scale: CGFloat

    init(scale: CGFloat = 1, @ViewBuilder content: () -> Content) {
        self.scale = scale
        self.content = content()
    }

    var body: some View {
        content
            // Measure height of the wrapped content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: _PendantHeightKey.self, value: proxy.size.height)
                }
            )
            .onPreferenceChange(_PendantHeightKey.self) { height in
                self.halfHeight = height / 2
            }
            // Shift downwards by half the (scaled) height so that the top of the view
            // sits exactly at the supplied .position() coordinate.
            .offset(y: halfHeight * scale)
    }
}

// MARK: - Private preference key
private struct _PendantHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
