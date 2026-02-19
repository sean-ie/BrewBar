import SwiftUI

struct PackageDetailView: View {
    let name: String
    let version: String
    let description: String?
    let homepage: String?
    let isCask: Bool
    let license: String?
    let tap: String?
    let dependencies: [String]
    let buildDependencies: [String]
    var requiredBy: [String] = []
    let autoUpdates: Bool
    var pinned: Bool = false
    var depTree: String?          // nil = not fetched, "…" = loading, "" = no deps
    var diskUsage: String?        // nil = not fetched, "…" = loading
    var onFetchDepTree: (() -> Void)?
    var onFetchDiskUsage: (() -> Void)?
    var onUninstall: ((String) -> Void)?
    var onPin: ((String) -> Void)?
    var onUnpin: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.headline)
                StatusBadge(
                    text: isCask ? "cask" : "formula",
                    color: isCask ? .purple : .blue
                )
                if pinned {
                    StatusBadge(text: "pinned", color: .orange)
                }
            }

            Text("v\(version)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            if let homepage, let url = URL(string: homepage) {
                LabeledContent("Homepage") {
                    Link(url.host ?? homepage, destination: url)
                        .font(.caption)
                }
            }

            if let tap {
                detailRow("Tap", value: tap)
            }

            if let license {
                detailRow("License", value: license)
            }

            if isCask {
                detailRow("Auto-updates", value: autoUpdates ? "Yes" : "No")
            }

            if !dependencies.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dependencies")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(dependencies.joined(separator: ", "))
                        .font(.caption)
                }
            }

            if !buildDependencies.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Build Dependencies")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(buildDependencies.joined(separator: ", "))
                        .font(.caption)
                }
            }

            if !requiredBy.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Required by")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(requiredBy.joined(separator: ", "))
                        .font(.caption)
                }
            }

            if !isCask, let diskUsage {
                detailRow("Size", value: diskUsage == "…" ? "…" : diskUsage)
            }

            if !isCask {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dependency tree")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    switch depTree {
                    case nil:
                        Text("…")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    case "":
                        Text("No dependencies")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    case let tree?:
                        if tree == "…" {
                            ProgressView().controlSize(.mini)
                        } else {
                            ScrollView([.horizontal, .vertical]) {
                                Text(tree)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                            }
                            .frame(maxHeight: 120)
                        }
                    }
                }
            }

            if onUninstall != nil || onPin != nil || onUnpin != nil {
                Divider()
                HStack(spacing: 8) {
                    if !isCask {
                        if pinned, let onUnpin {
                            Button {
                                onUnpin(name)
                            } label: {
                                Label("Unpin", systemImage: "pin.slash")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                        } else if let onPin {
                            Button {
                                onPin(name)
                            } label: {
                                Label("Pin", systemImage: "pin")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    Spacer()
                    if let onUninstall {
                        Button(role: .destructive) {
                            onUninstall(name)
                        } label: {
                            Label("Uninstall", systemImage: "trash")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
        .padding(12)
        .frame(width: 280, alignment: .leading)
        .onAppear {
            if !isCask {
                onFetchDepTree?()
                onFetchDiskUsage?()
            }
        }
    }

    private func detailRow(_ label: String, value: String) -> some View {
        LabeledContent(label) {
            Text(value)
                .font(.caption)
        }
        .font(.caption)
    }
}
