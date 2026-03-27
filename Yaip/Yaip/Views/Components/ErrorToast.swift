import SwiftUI

/// Non-blocking error toast that appears at the top of the screen.
/// Automatically dismisses after a delay, with optional retry action.
struct ErrorToast: View {
    let error: UserFacingError
    var onRetry: (() -> Void)?
    var onDismiss: (() -> Void)?

    @State private var isVisible = true

    var body: some View {
        if isVisible {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text(error.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Text(error.message)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(2)
                }

                Spacer()

                if let retryLabel = error.retryLabel {
                    Button {
                        onRetry?()
                        dismiss()
                    } label: {
                        Text(retryLabel)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.white.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.red.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            .padding(.horizontal, 16)
            .transition(.move(edge: .top).combined(with: .opacity))
            .task {
                // Auto-dismiss after 5 seconds (cancelled if view removed)
                try? await Task.sleep(for: .seconds(5))
                dismiss()
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            isVisible = false
        }
        onDismiss?()
    }
}

/// View modifier for conveniently showing error toasts
struct ErrorToastModifier: ViewModifier {
    @Binding var error: UserFacingError?
    var onRetry: (() -> Void)?

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let error = error {
                ErrorToast(
                    error: error,
                    onRetry: onRetry,
                    onDismiss: { self.error = nil }
                )
                .padding(.top, 8)
            }
        }
        .animation(.spring(response: 0.4), value: error != nil)
    }
}

extension View {
    func errorToast(_ error: Binding<UserFacingError?>, onRetry: (() -> Void)? = nil) -> some View {
        modifier(ErrorToastModifier(error: error, onRetry: onRetry))
    }
}
