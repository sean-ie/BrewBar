import SwiftUI

struct DashboardView: View {
    let info: BrewInfo
    let onNavigate: (Tab, PackageFilter?) -> Void
    var onUninstall: ((String) -> Void)?
    var onUninstallAll: (([String]) -> Void)?
    var onCleanup: (() -> Void)?

    private var detectedTools: [(name: String, version: String, icon: String, path: String?)] {
        let toolDefs: [(name: String, icon: String)] = [
            ("uv", "bolt.fill"),
            ("bun", "hare.fill"),
            ("mise", "square.stack.3d.up"),
            ("fnm", "arrow.triangle.branch"),
            ("volta", "bolt.circle"),
            ("pyenv", "arrow.triangle.branch"),
            ("rbenv", "arrow.triangle.branch"),
            ("rustup", "gearshape.2"),
            ("goenv", "arrow.triangle.branch"),
        ]
        return toolDefs.compactMap { tool in
            guard let formula = info.formulae.first(where: { $0.name == tool.name }) else { return nil }
            return (name: tool.name, version: formula.version, icon: tool.icon, path: info.toolPaths[tool.name])
        }
    }

    var body: some View {
        ScrollView {
        VStack(spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                SummaryCard(
                    title: "Formulae",
                    subtitle: "Browse & search",
                    count: info.formulae.count,
                    icon: "shippingbox",
                    color: .blue
                ) { onNavigate(.packages, .formulae) }

                SummaryCard(
                    title: "Casks",
                    subtitle: "Browse & search",
                    count: info.casks.count,
                    icon: "macwindow",
                    color: .purple
                ) { onNavigate(.packages, .casks) }

                let outdatedCount = info.outdatedFormulae.count + info.outdatedCasks.count
                SummaryCard(
                    title: "Outdated",
                    subtitle: outdatedCount > 0 ? "Tap to upgrade" : "All up to date",
                    count: outdatedCount,
                    icon: "exclamationmark.arrow.circlepath",
                    color: .orange
                ) { onNavigate(.outdated, nil) }

                SummaryCard(
                    title: "Services",
                    subtitle: "Start, stop, restart",
                    count: info.services.count,
                    icon: "gearshape.2",
                    color: .green
                ) { onNavigate(.services, nil) }
            }

            // Info & Cleanup row
            HStack(spacing: 8) {
                Button {
                    onNavigate(.info, nil)
                } label: {
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.title3)
                            .foregroundStyle(.teal)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Homebrew Info")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text(info.brewConfig["HOMEBREW_VERSION"].map { "v\($0)" } ?? "View configuration")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(8)
                    .background(.quaternary.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                if let onCleanup {
                    Button {
                        onCleanup()
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "trash.circle")
                                .font(.title3)
                                .foregroundStyle(.red)
                            Text("Cleanup")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .padding(8)
                        .background(.quaternary.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .help("Remove old versions and cache files")
                }
            }

            if !info.services.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Running Services")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            onNavigate(.services, nil)
                        } label: {
                            Text("Manage")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                    let running = info.services.filter { $0.status == .started }
                    if running.isEmpty {
                        Text("No running services")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    } else {
                        ForEach(running) { svc in
                            HStack {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 6, height: 6)
                                Text(svc.name)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Detected dev tools
            if !detectedTools.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dev Tools")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        ForEach(detectedTools, id: \.name) { tool in
                            HStack(spacing: 3) {
                                Image(systemName: tool.icon)
                                    .font(.system(size: 8))
                                    .foregroundStyle(.secondary)
                                Text(tool.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text(tool.version)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.quaternary.opacity(0.5))
                            .clipShape(Capsule())
                            .help(tool.path ?? tool.name)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Redundant packages
            if !info.redundantPackages.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Redundant Packages")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let onUninstallAll {
                            Button("Uninstall All") {
                                onUninstallAll(info.redundantPackages.map(\.formula.name))
                            }
                            .font(.caption)
                            .buttonStyle(.borderless)
                        }
                    }
                    ForEach(info.redundantPackages) { pkg in
                        HStack(spacing: 4) {
                            Text(pkg.formula.name)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text(pkg.formula.version)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            if !pkg.dependents.isEmpty {
                                StatusBadge(
                                    text: "\(pkg.dependents.count) dep\(pkg.dependents.count == 1 ? "" : "s")",
                                    color: .orange
                                )
                                .help("Required by: \(pkg.dependents.joined(separator: ", "))")
                            }
                            Spacer()
                            StatusBadge(text: "→ \(pkg.rule.toolName)", color: .blue)
                            if let onUninstall {
                                Button {
                                    onUninstall(pkg.formula.name)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption2)
                                }
                                .buttonStyle(.borderless)
                                .help("Uninstall \(pkg.formula.name)")
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(10)
        }
    }
}

private struct SummaryCard: View {
    let title: String
    let subtitle: String
    let count: Int
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text("\(count)")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(.quaternary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
