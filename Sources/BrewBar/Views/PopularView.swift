import SwiftUI

struct PopularView: View {
    let analytics: BrewAnalytics
    let installedFormulae: Set<String>
    let installedCasks: Set<String>
    var onInstall: ((String, Bool) -> Void)?

    @State private var filter: PopularFilter = .formulae
    @State private var showNotInstalled = true

    enum PopularFilter: String, CaseIterable {
        case formulae = "Formulae"
        case casks = "Casks"
    }

    private var rankedEntries: [(rank: Int, name: String, count: Int, isInstalled: Bool)] {
        let isCask = filter == .casks
        let installs = isCask ? analytics.caskInstalls : analytics.formulaInstalls
        let installedSet = isCask ? installedCasks : installedFormulae
        let sorted = installs.sorted { $0.value > $1.value }.prefix(100)
        return sorted.enumerated().map { idx, entry in
            (rank: idx + 1, name: entry.key, count: entry.value, isInstalled: installedSet.contains(entry.key))
        }
    }

    private var displayedEntries: [(rank: Int, name: String, count: Int, isInstalled: Bool)] {
        showNotInstalled ? rankedEntries.filter { !$0.isInstalled } : rankedEntries
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text("30-day installs")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                ForEach(PopularFilter.allCases, id: \.self) { f in
                    Button {
                        filter = f
                    } label: {
                        Text(f.rawValue)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(filter == f ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
                            .foregroundStyle(filter == f ? Color.accentColor : .secondary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                Toggle(isOn: $showNotInstalled) {
                    Text("Not installed")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .toggleStyle(.checkbox)
                .controlSize(.small)
            }
            .padding(8)

            Divider()

            if analytics.formulaInstalls.isEmpty && analytics.caskInstalls.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("Analytics unavailable")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Check your network connection")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if displayedEntries.isEmpty {
                Text("No packages to show")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(displayedEntries, id: \.name) { entry in
                            PopularRowView(
                                rank: entry.rank,
                                name: entry.name,
                                count: entry.count,
                                isInstalled: entry.isInstalled,
                                isCask: filter == .casks,
                                onInstall: onInstall
                            )
                            .padding(.horizontal, 8)
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

private struct PopularRowView: View {
    let rank: Int
    let name: String
    let count: Int
    let isInstalled: Bool
    let isCask: Bool
    var onInstall: ((String, Bool) -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            Text("#\(rank)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(width: 28, alignment: .trailing)

            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
                Text("\(formatCount(count)) / 30d")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isInstalled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            } else if let onInstall {
                Button {
                    onInstall(name, isCask)
                } label: {
                    Label("Install", systemImage: "arrow.down.circle")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            String(format: "%.1fK", Double(count) / 1_000)
        } else {
            "\(count)"
        }
    }
}
