import SwiftUI

struct ContentTypePage: View {
    @Binding var selected: [UserProfile.ContentStyle]
    private let allStyles = UserProfile.ContentStyle.allCases
    private let columns = [GridItem(.adaptive(minimum: 105), spacing: 12)]

    var body: some View {
        FlowPageContainer(title: "What games do you play?") {
            VStack(alignment: .center, spacing: 16) {

                Text("Select the game genres you stream, create content for, or play competitively.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(allStyles, id: \.self) { style in
                        let isSelected = selected.contains(style)

                        Button {
                            Haptics.impact(.light)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if isSelected {
                                    selected.removeAll { $0 == style }
                                } else {
                                    selected.append(style)
                                }
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: style.icon)
                                    .font(.title3)
                                    .foregroundStyle(isSelected ? .white : style.color)

                                Text(style.rawValue)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isSelected ? AppTheme.accent : AppTheme.card)
                            )
                            .foregroundColor(isSelected ? .white : .primary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isSelected ? AppTheme.accent : Color.clear, lineWidth: 2)
                            )
                            .scaleEffect(isSelected ? 1.02 : 1.0)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)

                if !selected.isEmpty {
                    VStack(spacing: 6) {
                        Text("\(selected.count) game type\(selected.count == 1 ? "" : "s") selected")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(selected, id: \.self) { style in
                                    HStack(spacing: 4) {
                                        Image(systemName: style.icon)
                                            .font(.caption2)
                                        Text(style.rawValue)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(AppTheme.accent.opacity(0.15), in: Capsule())
                                    .foregroundStyle(AppTheme.accent)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }
}
