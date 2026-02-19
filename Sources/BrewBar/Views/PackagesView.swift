import SwiftUI

enum PackageFilter: String, CaseIterable {
    case all = "All"
    case formulae = "Formulae"
    case casks = "Casks"
}

struct PackagesView: View {
    let formulae: [Formula]
    let casks: [Cask]
    @Binding var filter: PackageFilter
    var searchResults: (formulae: [String], casks: [String]) = ([], [])
    var isSearching: Bool = false
    var onSearchBrew: ((String) -> Void)?
    var onClearSearch: (() -> Void)?
    var onInstall: ((String, Bool) -> Void)?
    var onUninstall: ((String) -> Void)?
    var onPin: ((String) -> Void)?
    var onUnpin: ((String) -> Void)?
    var depTreeResults: [String: String] = [:]
    var diskUsageResults: [String: String] = [:]
    var onFetchDepTree: ((String) -> Void)?
    var onFetchDiskUsage: ((String) -> Void)?
    @State private var searchText = ""
    @State private var searchTask: Task<Void, Never>?
    @State private var formulaeExpanded = true
    @State private var casksExpanded = true

    // Map: formula name → names of installed formulae that depend on it
    private var reverseDeps: [String: [String]] {
        var map: [String: [String]] = [:]
        for formula in formulae {
            for dep in formula.dependencies + formula.buildDependencies {
                map[dep, default: []].append(formula.name)
            }
        }
        return map
    }

    private var filteredFormulae: [Formula] {
        guard filter != .casks else { return [] }
        if searchText.isEmpty { return formulae }
        return formulae.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredCasks: [Cask] {
        guard filter != .formulae else { return [] }
        if searchText.isEmpty { return casks }
        return casks.filter {
            $0.token.localizedCaseInsensitiveContains(searchText) ||
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Search packages...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.caption)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
                ForEach(PackageFilter.allCases, id: \.self) { pkgFilter in
                    Button {
                        filter = pkgFilter
                    } label: {
                        Text(pkgFilter.rawValue)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(filter == pkgFilter ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
                            .foregroundStyle(filter == pkgFilter ? Color.accentColor : .secondary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if !filteredFormulae.isEmpty {
                        Section {
                            if formulaeExpanded {
                                ForEach(filteredFormulae) { formula in
                                    PackageRowView(
                                        name: formula.name,
                                        version: formula.version,
                                        description: formula.description,
                                        isCask: false,
                                        homepage: formula.homepage,
                                        license: formula.license,
                                        tap: formula.tap,
                                        dependencies: formula.dependencies,
                                        buildDependencies: formula.buildDependencies,
                                        requiredBy: reverseDeps[formula.name, default: []].sorted(),
                                        autoUpdates: false,
                                        pinned: formula.pinned,
                                        depTree: depTreeResults[formula.name],
                                        diskUsage: diskUsageResults[formula.name],
                                        onFetchDepTree: { onFetchDepTree?(formula.name) },
                                        onFetchDiskUsage: { onFetchDiskUsage?(formula.name) },
                                        onUninstall: onUninstall,
                                        onPin: onPin,
                                        onUnpin: onUnpin
                                    )
                                    .padding(.horizontal, 8)
                                    Divider()
                                }
                            }
                        } header: {
                            let depCount = searchText.isEmpty
                                ? filteredFormulae.filter { !$0.installedOnRequest }.count
                                : nil
                            let subtitle = depCount.map { $0 > 0 ? " · \($0) deps" : "" } ?? ""
                            // swiftlint:disable:next line_length
                            collapsibleHeader("Formulae (\(filteredFormulae.count)\(subtitle))", expanded: $formulaeExpanded)
                        }
                    }

                    if !filteredCasks.isEmpty {
                        Section {
                            if casksExpanded {
                                ForEach(filteredCasks) { cask in
                                    PackageRowView(
                                        name: cask.name,
                                        version: cask.version,
                                        description: cask.description,
                                        isCask: true,
                                        homepage: cask.homepage,
                                        license: nil,
                                        tap: cask.tap,
                                        dependencies: [],
                                        buildDependencies: [],
                                        autoUpdates: cask.autoUpdates,
                                        onUninstall: onUninstall
                                    )
                                    .padding(.horizontal, 8)
                                    Divider()
                                }
                            }
                        } header: {
                            collapsibleHeader("Casks (\(filteredCasks.count))", expanded: $casksExpanded)
                        }
                    }

                    // swiftlint:disable:next line_length
                    if filteredFormulae.isEmpty && filteredCasks.isEmpty && searchResults.formulae.isEmpty && searchResults.casks.isEmpty && !isSearching {
                        Text(searchText.isEmpty ? "No packages found" : "No results for \"\(searchText)\"")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }

                    // Remote search results
                    if isSearching {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Searching Homebrew...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }

                    if !searchResults.formulae.isEmpty {
                        Section {
                            ForEach(searchResults.formulae, id: \.self) { name in
                                SearchResultRow(name: name, isCask: false, onInstall: onInstall)
                                    .padding(.horizontal, 8)
                                Divider()
                            }
                        } header: {
                            sectionHeader("Available Formulae (\(searchResults.formulae.count))")
                        }
                    }

                    if !searchResults.casks.isEmpty {
                        Section {
                            ForEach(searchResults.casks, id: \.self) { name in
                                SearchResultRow(name: name, isCask: true, onInstall: onInstall)
                                    .padding(.horizontal, 8)
                                Divider()
                            }
                        } header: {
                            sectionHeader("Available Casks (\(searchResults.casks.count))")
                        }
                    }
                }
            }
        }
        .onChange(of: searchText) {
            onClearSearch?()
            if !searchText.isEmpty {
                formulaeExpanded = true
                casksExpanded = true
            }
            searchTask?.cancel()
            guard !searchText.isEmpty else { return }
            searchTask = Task {
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                onSearchBrew?(searchText)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.bar)
    }

    private func collapsibleHeader(_ title: String, expanded: Binding<Bool>) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                expanded.wrappedValue.toggle()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: expanded.wrappedValue ? "chevron.down" : "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .background(.bar)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct SearchResultRow: View {
    let name: String
    let isCask: Bool
    var onInstall: ((String, Bool) -> Void)?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(isCask ? "Cask" : "Formula")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let onInstall {
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
}
