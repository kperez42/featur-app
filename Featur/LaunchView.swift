import SwiftUI

struct LaunchView: View {
    @State private var show = false

    var body: some View {
        ZStack {
            AppTheme.gradient.ignoresSafeArea()

            VStack(spacing: 16) {
                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .cornerRadius(28)
                    .opacity(show ? 1 : 0)
                    .scaleEffect(show ? 1 : 0.85)
            }
            .shadow(radius: 10)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9)) { show = true }
        }
    }
}



