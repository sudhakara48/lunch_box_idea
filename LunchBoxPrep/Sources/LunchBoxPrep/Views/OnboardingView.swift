import SwiftUI

/// Onboarding screen shown on first launch.
///
/// First-launch tracking (`UserDefaults` "hasSeenOnboarding") is handled
/// by the parent `App` struct — this view is purely presentational and
/// calls `onGetStarted` when the user taps "Get Started".
public struct OnboardingView: View {

    public var onGetStarted: () -> Void

    public init(onGetStarted: @escaping () -> Void) {
        self.onGetStarted = onGetStarted
    }

    public var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // App icon / logo area
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: "lunchbox.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .foregroundColor(.green)
            }
            .padding(.bottom, 24)

            Text("LunchBox Prep")
                .font(.largeTitle.bold())
                .padding(.bottom, 8)

            Text("Turn what's in your fridge into a great lunch — powered by AI.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)

            // Feature highlights
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(
                    icon: "camera.viewfinder",
                    color: .blue,
                    title: "Scan Your Food",
                    description: "Point your camera at ingredients and the app identifies them instantly."
                )
                FeatureRow(
                    icon: "sparkles",
                    color: .orange,
                    title: "Get AI-Powered Ideas",
                    description: "Receive creative, personalised lunch box recipes based on what you have."
                )
                FeatureRow(
                    icon: "heart.fill",
                    color: .red,
                    title: "Save Your Favourites",
                    description: "Keep the recipes you love and revisit them any time — no scanning needed."
                )
            }
            .padding(.horizontal, 32)

            Spacer()

            Button(action: onGetStarted) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

// MARK: - Supporting Views

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
