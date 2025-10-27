// SharedComponents.swift - All Reusable Components
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

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Profile Detail Placeholder
struct ProfileDetailPlaceholder: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Image
                    if let firstMediaURL = profile.mediaURLs.first {
                        AsyncImage(url: URL(string: firstMediaURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 400)
                                    .clipped()
                            default:
                                AppTheme.gradient
                                    .frame(height: 400)
                            }
                        }
                    } else {
                        AppTheme.gradient
                            .frame(height: 400)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Name and Age
                        HStack {
                            Text(profile.displayName)
                                .font(.largeTitle.bold())
                            
                            if let age = profile.age {
                                Text("\(age)")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if profile.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        
                        // Bio
                        if let bio = profile.bio {
                            Text(bio)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Content Styles
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Content Styles")
                                .font(.headline)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(profile.contentStyles, id: \.self) { style in
                                    TagChip(title: style.rawValue, active: false)
                                }
                            }
                        }
                        
                        // Location
                        if let location = profile.location {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Location")
                                    .font(.headline)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.circle.fill")
                                    if let city = location.city, let state = location.state {
                                        Text("\(city), \(state)")
                                    }
                                }
                                .foregroundStyle(.secondary)
                            }
                        }
                        
                        // Placeholder message
                        Text("Full profile view coming soon! 🚀")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Banner Ad Placeholder
struct BannerAdPlaceholder: View {
    var body: some View {
        ZStack {
            AppTheme.card
            Text("Ad Space")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? AppTheme.accent : Color.gray.opacity(0.2), in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
        }
    }
}
