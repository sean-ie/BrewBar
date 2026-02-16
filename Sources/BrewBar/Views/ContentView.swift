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
                    ScrollView {
                        Text(output)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 80)
                }
                .padding(8)
                .background(.green.opacity(0.05))
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
                        }
                    )
                case .packages:
                    PackagesView(
                        formulae: viewModel.info.formulae,
                        casks: viewModel.info.casks,
                        filter: $packageFilter
                    )
                case .outdated:
                    OutdatedView(
                        formulae: viewModel.info.outdatedFormulae,
                        casks: viewModel.info.outdatedCasks,
                        onUpgrade: { name, isCask in
                            viewModel.upgrade(package: name, isCask: isCask)
                        },
                        onUpgradeAll: {
                            viewModel.upgradeAll()
                        }
                    )
                case .services:
                    ServicesView(
                        services: viewModel.info.services,
                        onStart: { viewModel.startService($0) },
                        onStop: { viewModel.stopService($0) },
                        onRestart: { viewModel.restartService($0) }
                    )
                case .info:
                    InfoView(info: viewModel.info)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: 360, height: 420)
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
