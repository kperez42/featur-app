import SwiftUI

struct ContentTypePage: View {
    @Binding var selected: [UserProfile.ContentStyle]
    private let allStyles = UserProfile.ContentStyle.allCases
    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 12)]
    
    var body: some View {
        FlowPageContainer(title: "What kind of content do you make?") {
            VStack(alignment: .center, spacing: 16) {
                
                Text("Pick a few categories that best match your style.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(allStyles, id: \.self) { style in
                        let isSelected = selected.contains(style)
                        
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if isSelected {
                                    selected.removeAll { $0 == style }
                                } else {
                                    selected.append(style)
                                }
                            }
                        } label: {
                            Text(style.rawValue)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(isSelected ? AppTheme.accent : AppTheme.card)
                                )
                                .foregroundColor(isSelected ? .white : .primary)
                                .scaleEffect(isSelected ? 1.05 : 1.0)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                
                if !selected.isEmpty {
                    Text("Selected: \(selected.map { $0.rawValue }.joined(separator: ", "))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }
}
