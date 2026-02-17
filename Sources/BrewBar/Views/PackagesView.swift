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
    @State private var searchText = ""

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
                ForEach(PackageFilter.allCases, id: \.self) { f in
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
            }
            .padding(8)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if !filteredFormulae.isEmpty {
                        Section {
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
                                    autoUpdates: false,
                                    pinned: formula.pinned,
                                    onUninstall: onUninstall,
                                    onPin: onPin,
                                    onUnpin: onUnpin
                                )
                                .padding(.horizontal, 8)
                                Divider()
                            }
                        } header: {
                            sectionHeader("Formulae (\(filteredFormulae.count))")
                        }
                    }

                    if !filteredCasks.isEmpty {
                        Section {
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
                        } header: {
                            sectionHeader("Casks (\(filteredCasks.count))")
                        }
                    }

                    if filteredFormulae.isEmpty && filteredCasks.isEmpty && !searchText.isEmpty && searchResults.formulae.isEmpty && searchResults.casks.isEmpty && !isSearching {
                        VStack(spacing: 8) {
                            Text("No installed packages match")
                                .foregroundStyle(.secondary)
                            if let onSearchBrew {
                                Button("Search Homebrew for \"\(searchText)\"") {
                                    onSearchBrew(searchText)
                                }
                                .font(.caption)
                                .buttonStyle(.borderless)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else if filteredFormulae.isEmpty && filteredCasks.isEmpty && searchResults.formulae.isEmpty && searchResults.casks.isEmpty {
                        Text("No packages found")
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
