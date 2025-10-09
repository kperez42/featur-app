import SwiftUI

// MARK: - Glass Card
struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06)))
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let title: String
    let active: Bool
    
    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                active ? AppTheme.accent : AppTheme.card,
                in: Capsule()
            )
            .foregroundStyle(active ? .white : .primary)
    }
}

// MARK: - Tag Pills
struct TagPills: View {
    let tags: [String]
    @Binding var selected: String?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(tags, id: \.self) { tag in
                    Button {
                        selected = (selected == tag) ? nil : tag
                    } label: {
                        TagChip(title: tag, active: selected == tag)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

// MARK: - Swipe Card
struct SwipeCard<Content: View>: View {
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    let content: Content
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    
    init(
        onSwipeLeft: @escaping () -> Void,
        onSwipeRight: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.onSwipeLeft = onSwipeLeft
        self.onSwipeRight = onSwipeRight
        self.content = content()
    }
    
    var body: some View {
        content
            .offset(offset)
            .rotationEffect(.degrees(rotation))
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        offset = gesture.translation
                        rotation = Double(gesture.translation.width / 20)
                    }
                    .onEnded { gesture in
                        if abs(gesture.translation.width) > 150 {
                            // Swipe detected
                            withAnimation(.spring(response: 0.3)) {
                                offset = CGSize(
                                    width: gesture.translation.width > 0 ? 500 : -500,
                                    height: gesture.translation.height
                                )
                                rotation = gesture.translation.width > 0 ? 45 : -45
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if gesture.translation.width > 0 {
                                    onSwipeRight()
                                } else {
                                    onSwipeLeft()
                                }
                                offset = .zero
                                rotation = 0
                            }
                        } else {
                            // Return to center
                            withAnimation(.spring()) {
                                offset = .zero
                                rotation = 0
                            }
                        }
                    }
            )
    }
}

// MARK: - Haptics
struct Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    
    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
