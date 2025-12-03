import SwiftUI

struct VerifyEmailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var auth: AuthViewModel // Add AuthViewModel to handle sign-out
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        ZStack {
            AppTheme.gradient.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                Image(systemName: "envelope.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.white)
                    .shadow(radius: 10)
                
                VStack(spacing: 12) {
                    Text("Check Your Email")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("We sent a verification link to:")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text(auth.user?.email ?? "Email unavailable")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                
                Spacer()
                
                Button {
                    Task {
                        await auth.signOut() // Sign out, triggering AuthGateView to show LoginView
                            
                        navigationPath = NavigationPath()
                }
                    // navigate back to login or trigger state change
                } label: {
                    Text("Back to Login")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(AppTheme.accent)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

