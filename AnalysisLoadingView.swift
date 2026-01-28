import SwiftUI

struct AnalysisLoadingView: View {
    var body: some View {
        SwiftUI.ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .red))
            .scaleEffect(2.0)
    }
}
