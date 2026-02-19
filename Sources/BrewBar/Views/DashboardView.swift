// swiftlint:disable file_length
import SwiftUI

struct DashboardView: View {
    let info: BrewInfo
    let onNavigate: (Tab, PackageFilter?) -> Void
    var onUninstall: ((String) -> Void)?
    var onUninstallAll: (([String]) -> Void)?
    var onCleanup: (() -> Void)?
    var bundle: BrewBundle?
    var onExportBundle: (() -> Void)?
    var onLoadBundle: (() -> Void)?
    var onInstallMissing: (() -> Void)?
    var onClearBundle: (() -> Void)?
    var doctorWarnings: [String] = []
    var doctorChecked: Bool = false
    var isDoctorRunning: Bool = false
    var onRunDoctor: (() -> Void)?

    // swiftlint:disable:next large_tuple
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
            ("goenv", "arrow.triangle.branch")
        ]
        return toolDefs.compactMap { tool in
            guard let formula = info.formulae.first(where: { $0.name == tool.name }) else { return nil }
            return (name: tool.name, version: formula.version, icon: tool.icon, path: info.toolPaths[tool.name])
        }
    }

    var body: some View {
        ScrollView {
        VStack(spacing: 8) {
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
                    color: outdatedCount > 0 ? .orange : .green
                ) { onNavigate(.outdated, nil) }

                SummaryCard(
                    title: "Services",
                    subtitle: "Start, stop, restart",
                    count: info.services.count,
                    icon: "gearshape.2",
                    color: .teal
                ) { onNavigate(.services, nil) }
            }

            // Info & Cleanup row
            HStack(spacing: 8) {
                Button {
                    onNavigate(.info, nil)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.teal)
                            .frame(width: 22, alignment: .center)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Homebrew Info")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(info.brewConfig["HOMEBREW_VERSION"].map { "v\($0)" } ?? "—")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                if let onCleanup {
                    Button {
                        onCleanup()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "trash.circle")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.red)
                                .frame(width: 22, alignment: .center)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Cleanup")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text("Remove old files")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .help("Remove old versions and cache files")
                }
            }

            DoctorSectionView(
                warnings: doctorWarnings,
                checked: doctorChecked,
                isRunning: isDoctorRunning,
                onRun: onRunDoctor
            )

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
            BrewfileSectionView(
                bundle: bundle,
                onExport: onExportBundle,
                onLoad: onLoadBundle,
                onInstallMissing: onInstallMissing,
                onClear: onClearBundle
            )
        }
        .padding(10)
        }
    }
}

private struct DoctorSectionView: View {
    let warnings: [String]
    let checked: Bool
    let isRunning: Bool
    let onRun: (() -> Void)?

    @State private var expanded = false

    var body: some View {
        HStack(spacing: 8) {
            if isRunning {
                ProgressView()
                    .controlSize(.small)
                Text("Running brew doctor…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if !checked {
                Image(systemName: "stethoscope")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("brew doctor")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if let onRun {
                    Button("Run Check", action: onRun)
                        .font(.caption)
                        .buttonStyle(.borderless)
                }
            } else if warnings.isEmpty {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                Text("Your system is ready to brew.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if let onRun {
                    Button("Re-run", action: onRun)
                        .font(.caption2)
                        .buttonStyle(.borderless)
                        .foregroundStyle(.tertiary)
                }
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(warnings.count) warning\(warnings.count == 1 ? "" : "s")")
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) { expanded.toggle() }
                        } label: {
                            Image(systemName: expanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.borderless)
                        if let onRun {
                            Button("Re-run", action: onRun)
                                .font(.caption2)
                                .buttonStyle(.borderless)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    if expanded {
                        ForEach(warnings, id: \.self) { warning in
                            Text(warning.components(separatedBy: "\n").first ?? warning)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .padding(.leading, 4)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BrewfileSectionView: View {
    let bundle: BrewBundle?
    let onExport: (() -> Void)?
    let onLoad: (() -> Void)?
    let onInstallMissing: (() -> Void)?
    let onClear: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header row
            HStack {
                Text("Brewfile")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let bundle {
                    Text(bundle.displayName)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Button {
                        onClear?()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.borderless)
                    .help("Clear Brewfile")
                } else {
                    Spacer()
                }
            }

            if let bundle {
                // Status row
                HStack(spacing: 8) {
                    Label("\(bundle.installedCount) installed", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                    if bundle.missingCount > 0 {
                        Label("\(bundle.missingCount) missing", systemImage: "xmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                    Spacer()
                }

                // Missing entries list (capped at 5)
                let missing = bundle.entries.filter { $0.type.isCheckable && !$0.isInstalled }
                if !missing.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(missing.prefix(5)) { entry in
                            HStack(spacing: 4) {
                                Text("•")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                Text(entry.type.label + ":")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(entry.name)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                        }
                        if missing.count > 5 {
                            Text("and \(missing.count - 5) more…")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                // Action buttons
                HStack(spacing: 6) {
                    Button("Export Current") { onExport?() }
                        .font(.caption2)
                        .buttonStyle(.borderless)
                    Spacer()
                    if bundle.missingCount > 0 {
                        Button("Install Missing →") { onInstallMissing?() }
                            .font(.caption2)
                            .buttonStyle(.borderless)
                            .foregroundStyle(.orange)
                    }
                }
            } else {
                // No bundle loaded
                Text("No Brewfile loaded")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                HStack(spacing: 6) {
                    Button("Export Current") { onExport?() }
                        .font(.caption2)
                        .buttonStyle(.borderless)
                    Button("Load Brewfile") { onLoad?() }
                        .font(.caption2)
                        .buttonStyle(.borderless)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 22, alignment: .center)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(count)")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                    Text(title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .help(subtitle)
    }
}
