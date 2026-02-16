import SwiftUI

struct OutdatedView: View {
    let formulae: [Formula]
    let casks: [Cask]
    let onUpgrade: (String, Bool) -> Void
    let onUpgradeAll: () -> Void

    private var totalCount: Int { formulae.count + casks.count }

    var body: some View {
        VStack(spacing: 0) {
            if totalCount > 0 {
                HStack {
                    Text("\(totalCount) outdated package\(totalCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Upgrade All") {
                        onUpgradeAll()
                    }
                    .controlSize(.small)
                }
                .padding(8)
                Divider()
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(formulae) { formula in
                        OutdatedRow(
                            name: formula.name,
                            installedVersion: formula.version,
                            latestVersion: formula.latestVersion,
                            isCask: false,
                            pinned: formula.pinned
                        ) {
                            onUpgrade(formula.name, false)
                        }
                        Divider()
                    }
                    ForEach(casks) { cask in
                        OutdatedRow(
                            name: cask.token,
                            installedVersion: cask.version,
                            latestVersion: cask.latestVersion,
                            isCask: true,
                            pinned: false
                        ) {
                            onUpgrade(cask.token, true)
                        }
                        Divider()
                    }

                    if totalCount == 0 {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle")
                                .font(.title)
                                .foregroundStyle(.green)
                            Text("Everything is up to date!")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                    }
                }
            }
        }
    }
}

private struct OutdatedRow: View {
    let name: String
    let installedVersion: String
    let latestVersion: String?
    let isCask: Bool
    let pinned: Bool
    let onUpgrade: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(name)
                        .fontWeight(.medium)
                    StatusBadge(
                        text: isCask ? "cask" : "formula",
                        color: isCask ? .purple : .blue
                    )
                    if pinned {
                        StatusBadge(text: "pinned", color: .gray)
                    }
                }
                HStack(spacing: 4) {
                    Text(installedVersion)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let latestVersion {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary)
                        Text(latestVersion)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                    }
                }
            }
            Spacer()
            Button {
                onUpgrade()
            } label: {
                Text("Upgrade")
                    .font(.caption)
            }
            .controlSize(.small)
            .help("Upgrade \(name)")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}
