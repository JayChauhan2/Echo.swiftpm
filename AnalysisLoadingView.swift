import SwiftUI

struct AnalysisLoadingView: View {
    var body: some View {
        SwiftUI.ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: Theme.tint))
            .scaleEffect(2.0)
    }
}
