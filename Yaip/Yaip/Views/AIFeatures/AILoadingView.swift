//
//  AILoadingView.swift
//  Yaip
//
//  Reusable loading and error views for AI features
//

import SwiftUI

struct AILoadingView: View {
    let title: String
    let subtitle: String

    @State private var isAnimating = false
    @State private var dotCount = 0

    var body: some View {
        VStack(spacing: 24) {
            // Animated sparkles icon
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
            }

            VStack(spacing: 8) {
                Text(title + String(repeating: ".", count: dotCount))
                    .font(.headline)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Skeleton loading bars
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                        .frame(width: skeletonWidth(for: index))
                        .shimmer()
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .onAppear {
            // Rotation animation
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                isAnimating = true
            }

            // Dots animation
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                dotCount = (dotCount + 1) % 4
            }
        }
    }

    private func skeletonWidth(for index: Int) -> CGFloat {
        switch index {
        case 0: return UIScreen.main.bounds.width - 80
        case 1: return UIScreen.main.bounds.width - 120
        case 2: return UIScreen.main.bounds.width - 100
        default: return UIScreen.main.bounds.width - 80
        }
    }
}

// Shimmer effect modifier
extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.3),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = UIScreen.main.bounds.width * 2
                }
            }
    }
}

struct AIErrorView: View {
    let error: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("Something went wrong")
                .font(.headline)

            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: retry) {
                Label("Try Again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview("Loading") {
    AILoadingView(
        title: "Processing",
        subtitle: "This won't take long..."
    )
}

#Preview("Error") {
    AIErrorView(error: "Network connection failed") {
        print("Retry tapped")
    }
}
