// SharedComponents.swift - All Reusable Components
import SwiftUI

// MARK: - Glass Card
struct GlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16

    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusLarge)
                    .fill(AppTheme.card)
                    .shadow(color: AppTheme.shadowLight, radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusLarge)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let title: String
    let active: Bool

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Group {
                    if active {
                        Capsule()
                            .fill(AppTheme.gradient)
                            .shadow(color: AppTheme.shadowAccent, radius: 4, x: 0, y: 2)
                    } else {
                        Capsule()
                            .fill(AppTheme.card)
                            .overlay(
                                Capsule()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
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
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isFocused ? AppTheme.accent : .secondary)
                .animation(.easeInOut(duration: AppTheme.animFast), value: isFocused)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .focused($isFocused)

            if !text.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: AppTheme.animFast)) {
                        text = ""
                    }
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.radiusMedium)
                .fill(AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusMedium)
                        .stroke(isFocused ? AppTheme.accent.opacity(0.5) : Color.clear, lineWidth: 2)
                )
                .shadow(color: isFocused ? AppTheme.shadowAccent.opacity(0.2) : .clear, radius: 8, x: 0, y: 4)
        )
        .animation(.easeInOut(duration: AppTheme.animMedium), value: isFocused)
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

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
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

    private let imageHeight: CGFloat = 400

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Image with consistent sizing
                    GeometryReader { geo in
                        if let firstMediaURL = profile.mediaURLs?.first {
                            AsyncImage(url: URL(string: firstMediaURL)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geo.size.width, height: imageHeight)
                                        .clipped()
                                case .empty:
                                    ZStack {
                                        AppTheme.gradient
                                        ProgressView()
                                            .tint(.white)
                                    }
                                    .frame(width: geo.size.width, height: imageHeight)
                                default:
                                    ZStack {
                                        AppTheme.gradient
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 80))
                                            .foregroundStyle(.white.opacity(0.4))
                                    }
                                    .frame(width: geo.size.width, height: imageHeight)
                                }
                            }
                        } else {
                            ZStack {
                                AppTheme.gradient
                                Image(systemName: "person.fill")
                                    .font(.system(size: 80))
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                            .frame(width: geo.size.width, height: imageHeight)
                        }
                    }
                    .frame(height: imageHeight)
                    
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
                            
                            if profile.isVerified ?? false {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        
                        // Bio
                        if let bio = profile.bio, !bio.isEmpty {
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

    @State private var isPressed = false

    var body: some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? AppTheme.accent : Color.gray.opacity(0.2), in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Primary Button Style
struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if isEnabled {
                        RoundedRectangle(cornerRadius: AppTheme.radiusMedium)
                            .fill(AppTheme.gradient)
                            .shadow(color: AppTheme.shadowAccent, radius: configuration.isPressed ? 2 : 8, x: 0, y: configuration.isPressed ? 1 : 4)
                    } else {
                        RoundedRectangle(cornerRadius: AppTheme.radiusMedium)
                            .fill(Color.gray.opacity(0.3))
                    }
                }
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(AppTheme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.radiusMedium)
                    .stroke(AppTheme.accent, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.radiusMedium)
                            .fill(AppTheme.accent.opacity(configuration.isPressed ? 0.1 : 0))
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Icon Button Style
struct IconButtonStyle: ButtonStyle {
    var size: CGFloat = 50
    var backgroundColor: Color = AppTheme.card

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.4, weight: .semibold))
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(backgroundColor)
                    .shadow(color: AppTheme.shadowLight, radius: 4, x: 0, y: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Shimmer Loading Effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.3),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: -geo.size.width + (geo.size.width * 2 * phase))
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Loading View
struct SkeletonView: View {
    var width: CGFloat? = nil
    var height: CGFloat = 20
    var cornerRadius: CGFloat = AppTheme.radiusSmall

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(AppTheme.card)
            .frame(width: width, height: height)
            .shimmer()
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.accent.opacity(0.6))
                .symbolEffect(.pulse)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle) {
                    Haptics.impact(.medium)
                    action()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 60)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Verified Badge
struct VerifiedBadge: View {
    var size: CGFloat = 16

    var body: some View {
        Image(systemName: "checkmark.seal.fill")
            .font(.system(size: size))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.blue, Color.cyan],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

// MARK: - Online Status Indicator
struct OnlineIndicator: View {
    var size: CGFloat = 12
    var showBorder: Bool = true

    var body: some View {
        Circle()
            .fill(AppTheme.success)
            .frame(width: size, height: size)
            .overlay(
                showBorder ?
                    Circle()
                        .stroke(AppTheme.bg, lineWidth: 2)
                    : nil
            )
    }
}

// MARK: - Gradient Border Modifier
struct GradientBorderModifier: ViewModifier {
    var lineWidth: CGFloat = 3
    var cornerRadius: CGFloat = AppTheme.radiusLarge

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppTheme.vibrantGradient, lineWidth: lineWidth)
            )
    }
}

extension View {
    func gradientBorder(lineWidth: CGFloat = 3, cornerRadius: CGFloat = AppTheme.radiusLarge) -> some View {
        modifier(GradientBorderModifier(lineWidth: lineWidth, cornerRadius: cornerRadius))
    }
}
