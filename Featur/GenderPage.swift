import SwiftUI

struct GenderPage: View {
    @Binding var gender: String
    
    private let options = ["Male", "Female", "Non-binary", "Prefer not to say"]
    
    var body: some View {
        FlowPageContainer(title: "What's your gender?") {
            VStack(spacing: 16) {
                ForEach(options, id: \.self) { option in
                    Button {
                        gender = option
                    } label: {
                        Text(option)
                            .font(.title3.weight(.medium))
                            .foregroundColor(gender == option ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(gender == option ? AppTheme.accent : AppTheme.card)
                            )
                            .scaleEffect(gender == option ? 1.03 : 1.0)
                            .animation(.easeInOut(duration: 0.15), value: gender)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if !gender.isEmpty {
                Text("Selected: \(gender)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
        }
    }
}
