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
                                    autoUpdates: false
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
                                    autoUpdates: cask.autoUpdates
                                )
                                .padding(.horizontal, 8)
                                Divider()
                            }
                        } header: {
                            sectionHeader("Casks (\(filteredCasks.count))")
                        }
                    }

                    if filteredFormulae.isEmpty && filteredCasks.isEmpty {
                        Text("No packages found")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
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
}
