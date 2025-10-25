//
//  SmartSearchView.swift
//  Yaip
//
//  View for AI-powered semantic search
//

import SwiftUI

struct SmartSearchView: View {
    @ObservedObject var viewModel: AIFeaturesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    var onJumpToMessage: ((String) -> Void)?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                // Content
                if searchText.isEmpty {
                    emptySearchView
                } else if viewModel.isSearching {
                    loadingView
                } else if let error = viewModel.searchError {
                    errorView(error: error)
                } else if viewModel.searchResults.isEmpty {
                    noResultsView
                } else {
                    searchResultsList
                }
            }
            .navigationTitle("Smart Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if !searchText.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            searchText = ""
                            viewModel.clearSearch()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var searchBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search messages...", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit {
                        performSearch()
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        viewModel.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding()

            Divider()
        }
    }

    private var emptySearchView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 64))
                .foregroundStyle(.purple.opacity(0.5))

            VStack(spacing: 8) {
                Text("AI-Powered Search")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Search by meaning, not just keywords")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 12) {
                SearchTip(
                    icon: "brain",
                    text: "Semantic search understands context and meaning"
                )

                SearchTip(
                    icon: "key",
                    text: "Finds keyword matches and related concepts"
                )

                SearchTip(
                    icon: "sparkles",
                    text: "AI ranks results by relevance"
                )
            }
            .padding()
        }
        .frame(maxHeight: .infinity)
    }

    private var loadingView: some View {
        AILoadingView(
            title: "Searching",
            subtitle: "AI is analyzing messages for: \"\(searchText)\""
        )
        .frame(maxHeight: .infinity)
    }

    private func errorView(error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("Search Failed")
                .font(.headline)

            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                performSearch()
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxHeight: .infinity)
    }

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Results Found")
                .font(.headline)

            Text("Try different keywords or rephrase your search")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
    }

    private var searchResultsList: some View {
        List {
            // Results header
            Section {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                    Text("\(viewModel.searchResults.count) results for \"\(searchText)\"")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.clear)

            // Results grouped by match type
            if !semanticResults.isEmpty {
                Section {
                    ForEach(semanticResults) { result in
                        SearchResultRow(
                            result: result,
                            onTap: {
                                onJumpToMessage?(result.messageID)
                                dismiss()
                            }
                        )
                    }
                } header: {
                    Label("Semantic Matches", systemImage: "brain")
                        .foregroundStyle(.purple)
                }
            }

            if !hybridResults.isEmpty {
                Section {
                    ForEach(hybridResults) { result in
                        SearchResultRow(
                            result: result,
                            onTap: {
                                onJumpToMessage?(result.messageID)
                                dismiss()
                            }
                        )
                    }
                } header: {
                    Label("Hybrid Matches", systemImage: "sparkles")
                        .foregroundStyle(.blue)
                }
            }

            if !keywordResults.isEmpty {
                Section {
                    ForEach(keywordResults) { result in
                        SearchResultRow(
                            result: result,
                            onTap: {
                                onJumpToMessage?(result.messageID)
                                dismiss()
                            }
                        )
                    }
                } header: {
                    Label("Keyword Matches", systemImage: "key")
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private var semanticResults: [SearchResult] {
        viewModel.searchResults.filter { $0.matchType == .semantic }
    }

    private var hybridResults: [SearchResult] {
        viewModel.searchResults.filter { $0.matchType == .hybrid }
    }

    private var keywordResults: [SearchResult] {
        viewModel.searchResults.filter { $0.matchType == .keyword }
    }

    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        viewModel.searchMessages(query: searchText)
    }
}

struct SearchResultRow: View {
    let result: SearchResult
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // Relevance score and match type
                HStack {
                    // Relevance badge
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                        Text("\(Int(result.relevanceScore * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(relevanceColor)
                    .cornerRadius(6)

                    // Match type badge
                    matchTypeBadge

                    Spacer()

                    // Timestamp
                    Text(result.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Message content
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.senderName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(result.text)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                }

                // Jump to message button
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.caption)
                    Text("View in chat")
                        .font(.caption)
                }
                .foregroundStyle(.purple)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private var relevanceColor: Color {
        switch result.relevanceScore {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .blue
        default: return .orange
        }
    }

    @ViewBuilder
    private var matchTypeBadge: some View {
        let (icon, text, color): (String, String, Color) = switch result.matchType {
        case .semantic: ("brain", "Semantic", .purple)
        case .keyword: ("key", "Keyword", .orange)
        case .hybrid: ("sparkles", "Hybrid", .blue)
        }

        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.15))
        .cornerRadius(4)
    }
}

struct SearchTip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.purple)
                .frame(width: 32)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}

#Preview {
    SmartSearchView(viewModel: AIFeaturesViewModel(conversationID: "test-123"))
}
