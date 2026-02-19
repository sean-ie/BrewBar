import SwiftUI

struct OutdatedView: View {
    let formulae: [Formula]
    let casks: [Cask]
    let onUpgrade: (String, Bool) -> Void
    let onUpgradeAll: () -> Void
    var onUpgradeSelected: (([String], [String]) -> Void)?

    @State private var selectedFormulae: Set<String> = []
    @State private var selectedCasks: Set<String> = []

    private var totalCount: Int { formulae.count + casks.count }
    private var selectedCount: Int { selectedFormulae.count + selectedCasks.count }

    var body: some View {
        VStack(spacing: 0) {
            if totalCount > 0 {
                HStack(spacing: 6) {
                    Text("\(totalCount) outdated")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if selectedCount > 0 {
                        Button {
                            onUpgradeSelected?(Array(selectedFormulae), Array(selectedCasks))
                            selectedFormulae.removeAll()
                            selectedCasks.removeAll()
                        } label: {
                            Text("Upgrade \(selectedCount) Selected")
                                .font(.caption)
                        }
                        .controlSize(.small)
                        Button {
                            selectedFormulae.removeAll()
                            selectedCasks.removeAll()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption2)
                        }
                        .buttonStyle(.borderless)
                        .help("Clear selection")
                    } else {
                        Button("Select All") {
                            selectedFormulae = Set(formulae.map(\.name))
                            selectedCasks = Set(casks.map(\.token))
                        }
                        .font(.caption)
                        .buttonStyle(.borderless)
                        Button("Upgrade All") { onUpgradeAll() }
                            .controlSize(.small)
                    }
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
                            pinned: formula.pinned,
                            isSelected: selectedFormulae.contains(formula.name),
                            onToggleSelect: {
                                if selectedFormulae.contains(formula.name) {
                                    selectedFormulae.remove(formula.name)
                                } else {
                                    selectedFormulae.insert(formula.name)
                                }
                            }
                        ) { onUpgrade(formula.name, false) }
                        Divider()
                    }
                    ForEach(casks) { cask in
                        OutdatedRow(
                            name: cask.token,
                            installedVersion: cask.version,
                            latestVersion: cask.latestVersion,
                            isCask: true,
                            pinned: false,
                            isSelected: selectedCasks.contains(cask.token),
                            onToggleSelect: {
                                if selectedCasks.contains(cask.token) {
                                    selectedCasks.remove(cask.token)
                                } else {
                                    selectedCasks.insert(cask.token)
                                }
                            }
                        ) { onUpgrade(cask.token, true) }
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
    let isSelected: Bool
    let onToggleSelect: () -> Void
    let onUpgrade: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onToggleSelect) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.caption)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.gray.opacity(0.5))
            }
            .buttonStyle(.borderless)

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
