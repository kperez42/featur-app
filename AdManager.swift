// AdManager.swift
import Foundation
import SwiftUI
import GoogleMobileAds
import UIKit

/// Manages ad loading, display, and tracking for the app
@MainActor
final class AdManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isInterstitialLoaded = false
    @Published var isRewardedLoaded = false
    @Published var showError: AdError?
    @Published var rewardEarned = false
    
    // MARK: - Private Properties
    
    private var interstitialAd: InterstitialAd?
    private var rewardedAd: RewardedAd?
    
    // Track ad impressions to control frequency
    private var interstitialImpressions = 0
    private var lastInterstitialTime: Date?
    private let minTimeBetweenAds: TimeInterval = 180 // 3 minutes
    
    // MARK: - Ad Unit IDs
    // ⚠️ REPLACE WITH YOUR ACTUAL AD UNIT IDs FROM ADMOB CONSOLE
    
    #if DEBUG
    // Test Ad Unit IDs (use these during development)
    private let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    private let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    private let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    #else
    // Production Ad Unit IDs (replace with your real IDs)
    private let interstitialAdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY"
    private let rewardedAdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY"
    private let bannerAdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY"
    #endif
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        configureAdMob()
        preloadAds()
    }
    
    /// Configure AdMob SDK
    private func configureAdMob() {
        MobileAds.shared.start { status in
            print("✅ AdMob SDK initialized")
            print("📊 Adapter statuses:")
            for adapter in status.adapterStatusesByClassName {
                print("  - \(adapter.key): \(adapter.value.state.rawValue)")
            }
        }
        
        // Set request configuration for test devices
        let requestConfiguration = MobileAds.shared.requestConfiguration
        requestConfiguration.testDeviceIdentifiers = ["kGADSimulatorID"]
    }
    
    /// Preload ads for better UX
    private func preloadAds() {
        Task {
            await loadInterstitialAd()
            await loadRewardedAd()
        }
    }
    
    // MARK: - Interstitial Ads
    
    /// Load an interstitial ad
    func loadInterstitialAd() async {
        isInterstitialLoaded = false
        let request = Request()
        
        print("📡 Loading InterstitialAd from unitID =", interstitialAdUnitID)
        
        do {
            interstitialAd = try await InterstitialAd.load(
                with: interstitialAdUnitID,
                request: request
            )
            interstitialAd?.fullScreenContentDelegate = self
            isInterstitialLoaded = true
            print("✅ Interstitial ad loaded (isReady =", isInterstitialLoaded, ")")
        } catch {
            print("❌ Failed to load interstitial ad: \(error.localizedDescription)")
            showError = .loadFailed(error.localizedDescription)
            isInterstitialLoaded = false
        }
    }
    
    /// Show interstitial ad with frequency control
    /// - Parameters:
    ///   - from: The view controller to present from (optional, will auto-detect if nil)
    ///   - force: Skip frequency checks (use for important moments)
    func showInterstitialAd(from presenter: UIViewController? = nil, force: Bool = false) {
        // Check if enough time has passed since last ad
        if !force, let lastTime = lastInterstitialTime {
            let timeSinceLastAd = Date().timeIntervalSince(lastTime)
            if timeSinceLastAd < minTimeBetweenAds {
                print("⏱️ Too soon to show another ad. Wait \(Int(minTimeBetweenAds - timeSinceLastAd))s")
                return
            }
        }
        
        guard let ad = interstitialAd, isInterstitialLoaded else {
            print("⚠️ Interstitial ad not ready")
            // Reload ad for next time
            Task { await loadInterstitialAd() }
            return
        }
        
        // Find the best presenter to avoid "already presenting" errors
        guard let vc = presenter ?? topViewController() else {
            print("⚠️ No view controller available to present interstitial ad.")
            return
        }
        
        // Safety: if that VC is in the middle of presenting, retry shortly
        if vc.presentedViewController != nil {
            print("ℹ️ Presenter is already presenting; retrying shortly…")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                self.showInterstitialAd(from: presenter, force: force)
            }
            return
        }
        
        ad.present(from: vc)
        lastInterstitialTime = Date()
        interstitialImpressions += 1
        
        print("📺 Interstitial ad shown (total impressions: \(interstitialImpressions))")
    }
    
    // MARK: - Rewarded Ads
    
    /// Load a rewarded ad
    func loadRewardedAd() async {
        isRewardedLoaded = false
        let request = Request()
        
        print("📡 Loading RewardedAd from unitID =", rewardedAdUnitID)
        
        do {
            rewardedAd = try await RewardedAd.load(
                with: rewardedAdUnitID,
                request: request
            )
            rewardedAd?.fullScreenContentDelegate = self
            isRewardedLoaded = true
            print("✅ Rewarded ad loaded (isReady =", isRewardedLoaded, ")")
        } catch {
            print("❌ Failed to load rewarded ad: \(error.localizedDescription)")
            showError = .loadFailed(error.localizedDescription)
            isRewardedLoaded = false
        }
    }
    
    /// Show rewarded ad
    /// - Parameters:
    ///   - from: The view controller to present from (optional, will auto-detect if nil)
    ///   - onReward: Called when user earns reward
    ///   - onFail: Called if ad fails to show
    func showRewardedAd(
        from presenter: UIViewController? = nil,
        onReward: @escaping () -> Void,
        onFail: (() -> Void)? = nil
    ) {
        guard let ad = rewardedAd, isRewardedLoaded else {
            print("⚠️ Rewarded ad not ready")
            onFail?()
            Task { await loadRewardedAd() }
            return
        }
        
        // Find the best presenter to avoid "already presenting" errors
        guard let vc = presenter ?? topViewController() else {
            print("⚠️ No view controller available to present rewarded ad.")
            onFail?()
            return
        }
        
        // Safety: if that VC is in the middle of presenting, retry shortly
        if vc.presentedViewController != nil {
            print("ℹ️ Presenter is already presenting; retrying shortly…")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                self.showRewardedAd(from: presenter, onReward: onReward, onFail: onFail)
            }
            return
        }
        
        rewardEarned = false
        
        ad.present(from: vc, userDidEarnRewardHandler: { [weak ad] in
            let reward = ad?.adReward
            self.rewardEarned = true
            print("🎁 User earned reward: \(reward?.amount ?? 0) \(reward?.type ?? "unknown")")
            onReward()
        })
    }
    
    // MARK: - Banner Ads
    
    /// Create a banner view for SwiftUI
    /// - Parameter size: The banner size (default: adaptive banner)
    /// - Returns: A UIViewRepresentable banner view
    func createBannerView(size: AdSize = AdSizeBanner) -> AdBannerView {
        return AdBannerView(adUnitID: bannerAdUnitID, adSize: size)
    }
    
    // MARK: - Helper Methods
    
    /// Returns the top-most view controller in the key window's hierarchy
    private func topViewController(base: UIViewController? = {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?.rootViewController
        return root
    }()) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
    
    /// Check if it's a good time to show an ad (respects user experience)
    func shouldShowInterstitialAd(afterActions: Int = 5) -> Bool {
        // Show ad every X actions
        guard interstitialImpressions % afterActions == 0 else {
            return false
        }
        
        // Check time since last ad
        if let lastTime = lastInterstitialTime {
            let timeSinceLastAd = Date().timeIntervalSince(lastTime)
            return timeSinceLastAd >= minTimeBetweenAds
        }
        
        return true
    }
    
    /// Get root view controller for presenting ads
    static func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            print("❌ Could not find root view controller")
            return nil
        }
        
        // Return the topmost presented view controller
        var topController = rootVC
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        return topController
    }
    
    /// Reset ad frequency tracking (e.g., when user makes a purchase)
    func resetAdFrequency() {
        interstitialImpressions = 0
        lastInterstitialTime = nil
        print("🔄 Ad frequency tracking reset")
    }
}

// MARK: - FullScreenContentDelegate (Swift 6-safe)

extension AdManager: FullScreenContentDelegate {
    
    nonisolated func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("👁️ Ad impression recorded")
    }
    
    nonisolated func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("👆 Ad click recorded")
    }
    
    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ Ad failed to present: \(error.localizedDescription)")
        // Hop to main before touching @Published vars or calling load methods
        Task { @MainActor in
            self.showError = .presentFailed(error.localizedDescription)
            
            // Reload ad
            if ad is InterstitialAd {
                self.isInterstitialLoaded = false
                await self.loadInterstitialAd()
            } else if ad is RewardedAd {
                self.isRewardedLoaded = false
                await self.loadRewardedAd()
            }
        }
    }
    
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("👋 Ad dismissed — preloading next one.")
        // Hop to main before touching @Published vars or calling load methods
        Task { @MainActor in
            // Reload the ad for next time
            if ad is InterstitialAd {
                self.isInterstitialLoaded = false
                await self.loadInterstitialAd()
            } else if ad is RewardedAd {
                self.isRewardedLoaded = false
                await self.loadRewardedAd()
            }
        }
    }
}

// MARK: - Banner View (SwiftUI Wrapper)

struct AdBannerView: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdSize
    
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.rootViewController = AdManager.getRootViewController()
        banner.delegate = context.coordinator
        banner.load(Request())
        return banner
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, BannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("✅ Banner ad loaded")
        }
        
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("❌ Banner ad failed to load: \(error.localizedDescription)")
        }
        
        func bannerViewDidRecordImpression(_ bannerView: BannerView) {
            print("👁️ Banner impression recorded")
        }
        
        func bannerViewWillPresentScreen(_ bannerView: BannerView) {
            print("📺 Banner will present full screen")
        }
        
        func bannerViewDidDismissScreen(_ bannerView: BannerView) {
            print("👋 Banner dismissed full screen")
        }
    }
}

// MARK: - Ad Error Types

enum AdError: Identifiable, LocalizedError {
    case loadFailed(String)
    case presentFailed(String)
    case notReady
    
    var id: String {
        switch self {
        case .loadFailed(let message): return "load_\(message)"
        case .presentFailed(let message): return "present_\(message)"
        case .notReady: return "not_ready"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .loadFailed(let message):
            return "Failed to load ad: \(message)"
        case .presentFailed(let message):
            return "Failed to show ad: \(message)"
        case .notReady:
            return "Ad is not ready to be displayed"
        }
    }
}

// MARK: - SwiftUI View Extension for Easy Ad Integration

extension View {
    /// Show interstitial ad after this view appears
    func showInterstitialOnAppear(
        adManager: AdManager,
        shouldShow: Bool = true
    ) -> some View {
        self.onAppear {
            guard shouldShow else { return }
            
            if let rootVC = AdManager.getRootViewController() {
                Task { @MainActor in
                    // Small delay for better UX
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    adManager.showInterstitialAd(from: rootVC)
                }
            }
        }
    }
    
    /// Add banner ad at bottom of view
    func withBannerAd(adManager: AdManager) -> some View {
        VStack(spacing: 0) {
            self
            
            adManager.createBannerView()
                .frame(height: 50)
                .background(Color(.systemBackground))
        }
    }
}
