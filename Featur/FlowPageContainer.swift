import SwiftUI

struct FlowPageContainer<Content: View>: View {
    let title: String
    let content: () -> Content

    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .center, spacing: 10) {
                
                // --- Title ---
                Text(title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                // --- Page content ---
                content()
                    .frame(maxWidth: .infinity, alignment: .top)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.bottom, 20)
            .background(AppTheme.bg)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.bg.ignoresSafeArea())
        //  This removes the ScrollView’s default top inset
        .contentMargins(.zero, for: .scrollContent)
    }
}
