//
//  AppearanceSettingsView.swift
//  Yaip
//
//  App appearance and theme settings
//

import SwiftUI

struct AppearanceSettingsView: View {
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.purple)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Appearance")
                                .font(.headline)
                            Text("Customize how Yaip looks")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            Section("Theme") {
                ForEach(AppTheme.allCases) { theme in
                    Button {
                        withAnimation {
                            themeManager.currentTheme = theme
                        }
                    } label: {
                        HStack {
                            Image(systemName: theme.icon)
                                .font(.title3)
                                .foregroundStyle(themeManager.currentTheme == theme ? .blue : .primary)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(theme.rawValue)
                                    .foregroundStyle(.primary)

                                Text(themeDescription(for: theme))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if themeManager.currentTheme == theme {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About Themes")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("• System: Automatically matches your device's appearance")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("• Light: Always use light mode")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("• Dark: Always use dark mode")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func themeDescription(for theme: AppTheme) -> String {
        switch theme {
        case .system:
            return "Match system settings"
        case .light:
            return "Always light mode"
        case .dark:
            return "Always dark mode"
        }
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
}
