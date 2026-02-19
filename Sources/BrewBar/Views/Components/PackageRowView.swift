import SwiftUI

struct PackageRowView: View {
    let name: String
    let version: String
    let description: String?
    let isCask: Bool
    let homepage: String?
    let license: String?
    let tap: String?
    let dependencies: [String]
    let buildDependencies: [String]
    var requiredBy: [String] = []
    let autoUpdates: Bool
    var pinned: Bool = false
    var depTree: String?
    var diskUsage: String?
    var onFetchDepTree: (() -> Void)?
    var onFetchDiskUsage: (() -> Void)?
    var onUninstall: ((String) -> Void)?
    var onPin: ((String) -> Void)?
    var onUnpin: ((String) -> Void)?

    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail.toggle()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(name)
                            .fontWeight(.medium)
                        StatusBadge(
                            text: isCask ? "cask" : "formula",
                            color: isCask ? .purple : .blue
                        )
                        if pinned {
                            StatusBadge(text: "pinned", color: .orange)
                        }
                        if !requiredBy.isEmpty {
                            StatusBadge(text: "dep", color: .gray)
                                .help("Required by: \(requiredBy.joined(separator: ", "))")
                        }
                    }
                    if let description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Text(version)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            if !isCask {
                if pinned {
                    Button {
                        onUnpin?(name)
                    } label: {
                        Label("Unpin", systemImage: "pin.slash")
                    }
                } else {
                    Button {
                        onPin?(name)
                    } label: {
                        Label("Pin", systemImage: "pin")
                    }
                }
            }
            Button(role: .destructive) {
                onUninstall?(name)
            } label: {
                Label("Uninstall", systemImage: "trash")
            }
        }
        .popover(isPresented: $showDetail) {
            PackageDetailView(
                name: name,
                version: version,
                description: description,
                homepage: homepage,
                isCask: isCask,
                license: license,
                tap: tap,
                dependencies: dependencies,
                buildDependencies: buildDependencies,
                requiredBy: requiredBy,
                autoUpdates: autoUpdates,
                pinned: pinned,
                depTree: depTree,
                diskUsage: diskUsage,
                onFetchDepTree: onFetchDepTree,
                onFetchDiskUsage: onFetchDiskUsage,
                onUninstall: { pkg in
                    showDetail = false
                    onUninstall?(pkg)
                },
                onPin: { pkg in
                    showDetail = false
                    onPin?(pkg)
                },
                onUnpin: { pkg in
                    showDetail = false
                    onUnpin?(pkg)
                }
            )
        }
    }
}
