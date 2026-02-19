// swiftlint:disable type_body_length
import SwiftUI

enum Tab: String, CaseIterable {
    case dashboard = "Dashboard"
    case packages = "Packages"
    case outdated = "Outdated"
    case services = "Services"
    case info = "Info"

    var icon: String {
        switch self {
        case .dashboard: "square.grid.2x2"
        case .packages: "shippingbox"
        case .outdated: "exclamationmark.arrow.circlepath"
        case .services: "gearshape.2"
        case .info: "info.circle"
        }
    }
}

struct ContentView: View {
    @State var viewModel = BrewViewModel()
    @State private var selectedTab: Tab = .dashboard
    @State private var packageFilter: PackageFilter = .all

    private var outdatedCount: Int {
        viewModel.info.outdatedFormulae.count + viewModel.info.outdatedCasks.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("BrewBar")
                    .font(.headline)
                Spacer()
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
                Button {
                    viewModel.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.isLoading)
                .help("Refresh")

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.borderless)
                .help("Quit BrewBar")
            }
            .padding(10)

            // Status bar
            if let action = viewModel.actionInProgress {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                    Text(action)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(.blue.opacity(0.1))
            }

            if let error = viewModel.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(error)
                        .font(.caption)
                        .lineLimit(2)
                    Spacer()
                    Button("Dismiss") {
                        viewModel.error = nil
                    }
                    .controlSize(.small)
                }
                .padding(6)
                .background(.red.opacity(0.1))
            }

            // Tab picker
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    TabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        badge: tab == .outdated ? outdatedCount : nil
                    ) {
                        if tab == .packages {
                            packageFilter = .all
                        }
                        selectedTab = tab
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 6)

            // Action output log
            if let output = viewModel.lastActionOutput {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text("Done")
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                        Button {
                            viewModel.dismissOutput()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption2)
                        }
                        .buttonStyle(.borderless)
                    }
                    ScrollViewReader { proxy in
                        ScrollView {
                            Text(output)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                            Color.clear
                                .frame(height: 0)
                                .id("bottom")
                        }
                        .onAppear {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                        .onChange(of: output) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                    .frame(maxHeight: 80)
                }
                .padding(8)
                .background(.green.opacity(0.05))
            }

            // Nothing to clean banner
            if viewModel.showNothingToClean {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text("Already clean — nothing to remove.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        viewModel.showNothingToClean = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption2)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(6)
                .background(.green.opacity(0.05))
            }

            // Uninstall confirmation
            if let confirmation = viewModel.confirmingUninstall {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                    let pkgLabel = confirmation.packages.count == 1
                        ? confirmation.packages[0]
                        : "\(confirmation.packages.count) packages"
                    // swiftlint:disable:next line_length
                    Text("**\(confirmation.dependents.joined(separator: ", "))** depend\(confirmation.dependents.count == 1 ? "s" : "") on \(pkgLabel)")
                        .font(.caption)
                        .lineLimit(2)
                    Spacer()
                    Button("Uninstall Anyway") {
                        viewModel.confirmUninstall()
                    }
                    .font(.caption)
                    .controlSize(.small)
                    Button {
                        viewModel.confirmingUninstall = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption2)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(6)
                .background(.orange.opacity(0.08))
            }

            // Cleanup preview
            if let preview = viewModel.cleanupPreview {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "trash.circle")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("\(preview.fileCount) item\(preview.fileCount == 1 ? "" : "s") to remove")
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                        Button("Clean Up") {
                            viewModel.confirmCleanup()
                        }
                        .font(.caption)
                        .controlSize(.small)
                        Button {
                            viewModel.cleanupPreview = nil
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption2)
                        }
                        .buttonStyle(.borderless)
                    }
                    ScrollView {
                        Text(preview.details)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 80)
                }
                .padding(8)
                .background(.orange.opacity(0.05))
            }

            // Service log viewer
            if let log = viewModel.serviceLog {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("\(log.name) log")
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                        Button {
                            viewModel.dismissServiceLog()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption2)
                        }
                        .buttonStyle(.borderless)
                    }
                    ScrollViewReader { proxy in
                        ScrollView {
                            Text(log.content)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                            Color.clear
                                .frame(height: 0)
                                .id("logBottom")
                        }
                        .onAppear {
                            proxy.scrollTo("logBottom", anchor: .bottom)
                        }
                    }
                    .frame(maxHeight: 120)
                }
                .padding(8)
                .background(.blue.opacity(0.05))
            }

            Divider()

            // Tab content
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView(
                        info: viewModel.info,
                        onNavigate: { tab, filter in
                            if let filter {
                                packageFilter = filter
                            }
                            selectedTab = tab
                        },
                        onUninstall: { name in
                            viewModel.uninstall(package: name)
                        },
                        onUninstallAll: { names in
                            viewModel.uninstallAll(packages: names)
                        },
                        onCleanup: {
                            viewModel.previewCleanup()
                        },
                        bundle: viewModel.bundle,
                        onExportBundle: { viewModel.exportBundle() },
                        onLoadBundle: { viewModel.loadBundle() },
                        onInstallMissing: { viewModel.installBundleMissing() },
                        onClearBundle: { viewModel.clearBundle() },
                        doctorWarnings: viewModel.doctorWarnings,
                        doctorChecked: viewModel.doctorChecked,
                        isDoctorRunning: viewModel.isDoctorRunning,
                        onRunDoctor: { viewModel.runDoctor() }
                    )
                case .packages:
                    PackagesView(
                        formulae: viewModel.info.formulae,
                        casks: viewModel.info.casks,
                        filter: $packageFilter,
                        searchResults: viewModel.searchResults,
                        isSearching: viewModel.isSearching,
                        onSearchBrew: { viewModel.searchBrewPackages($0) },
                        onClearSearch: { viewModel.clearSearchResults() },
                        onInstall: { viewModel.install(package: $0, isCask: $1) },
                        onUninstall: { viewModel.uninstall(package: $0) },
                        onPin: { viewModel.pin(package: $0) },
                        onUnpin: { viewModel.unpin(package: $0) },
                        depTreeResults: viewModel.depTreeResults,
                        diskUsageResults: viewModel.diskUsageResults,
                        onFetchDepTree: { viewModel.fetchDepTree(for: $0) },
                        onFetchDiskUsage: { viewModel.fetchDiskUsage(for: $0) }
                    )
                case .outdated:
                    OutdatedView(
                        formulae: viewModel.info.outdatedFormulae,
                        casks: viewModel.info.outdatedCasks,
                        onUpgrade: { viewModel.upgrade(package: $0, isCask: $1) },
                        onUpgradeAll: { viewModel.upgradeAll() },
                        onUpgradeSelected: { viewModel.upgradeSelected(formulae: $0, casks: $1) }
                    )
                case .services:
                    ServicesView(
                        services: viewModel.info.services,
                        onStart: { viewModel.startService($0) },
                        onStop: { viewModel.stopService($0) },
                        onRestart: { viewModel.restartService($0) },
                        onViewLog: { viewModel.fetchServiceLog($0) }
                    )
                case .info:
                    InfoView(
                        info: viewModel.info,
                        onAddTap: { viewModel.addTap($0) },
                        onRemoveTap: { viewModel.removeTap($0) }
                    )
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: 360, height: 480)
        .onAppear {
            viewModel.refresh()
        }
    }
}

private struct TabButton: View {
    let tab: Tab
    let isSelected: Bool
    let badge: Int?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.caption2)
                Text(tab.rawValue)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let badge, badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(.orange, in: Capsule())
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.accentColor.opacity(0.15) : .clear)
            .foregroundStyle(isSelected ? .primary : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}
