import SwiftUI

struct InfoView: View {
    let info: BrewInfo
    var onAddTap: ((String) -> Void)?
    var onRemoveTap: ((String) -> Void)?
    var recentInstalls: [InstallRecord] = []
    var brewEvents: [BrewEvent] = []

    @State private var newTapName = ""

    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    private func relativeDate(_ date: Date) -> String {
        Self.relativeDateFormatter.localizedString(for: date, relativeTo: Date())
    }

    private var config: [String: String] { info.brewConfig }

    // swiftlint:disable:next large_tuple
    private var detectedDevTools: [(name: String, version: String, path: String?)] {
        let toolNames = [
            "uv", "bun", "mise", "fnm", "volta", "pyenv", "rbenv", "rustup", "goenv", "jenv", "chruby", "nvm"
        ]
        return toolNames.compactMap { name in
            guard let formula = info.formulae.first(where: { $0.name == name }) else { return nil }
            return (name: name, version: formula.version, path: info.toolPaths[name])
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                section("Homebrew") {
                    configRow("Version", key: "HOMEBREW_VERSION")
                    configRow("Prefix", key: "HOMEBREW_PREFIX")
                }

                section("System") {
                    configRow("macOS", key: "macOS")
                    configRow("CPU", key: "CPU")
                    configRow("Xcode", key: "Xcode")
                    configRow("CLT", key: "CLT")
                    configRow("Rosetta 2", key: "Rosetta 2")
                }

                section("Tools") {
                    configRow("Git", key: "Git")
                    configRow("Ruby", key: "Ruby")
                    configRow("Curl", key: "Curl")
                    ForEach(detectedDevTools, id: \.name) { tool in
                        VStack(alignment: .leading, spacing: 1) {
                            HStack {
                                Text(tool.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(tool.version)
                                    .font(.caption)
                                    .textSelection(.enabled)
                            }
                            if let path = tool.path {
                                Text(path)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }

                section("Packages") {
                    infoRow("Installed formulae", value: "\(info.formulae.count)")
                    infoRow("Installed casks", value: "\(info.casks.count)")
                    let outdatedCount = info.outdatedFormulae.count + info.outdatedCasks.count
                    infoRow("Outdated", value: "\(outdatedCount)")
                }

                section("Taps") {
                    ForEach(info.taps, id: \.self) { tap in
                        HStack {
                            Text(tap)
                                .font(.caption)
                            Spacer()
                            if let onRemoveTap {
                                Button {
                                    onRemoveTap(tap)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.borderless)
                                .help("Remove tap \(tap)")
                            }
                        }
                    }
                    if let onAddTap {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            TextField("Add tap (e.g. user/repo)", text: $newTapName)
                                .textFieldStyle(.plain)
                                .font(.caption)
                                .onSubmit {
                                    guard !newTapName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                                    onAddTap(newTapName)
                                    newTapName = ""
                                }
                            if !newTapName.isEmpty {
                                Button {
                                    onAddTap(newTapName)
                                    newTapName = ""
                                } label: {
                                    Text("Add")
                                        .font(.caption)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background(.quaternary.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(.top, 2)
                    }
                }

                section("Recently Installed") {
                    if recentInstalls.isEmpty {
                        Text("No install data found.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    } else {
                        ForEach(recentInstalls.prefix(15)) { record in
                            HStack(spacing: 6) {
                                Text(record.name)
                                    .font(.caption)
                                StatusBadge(text: record.isCask ? "cask" : "formula",
                                            color: record.isCask ? .purple : .blue)
                                Spacer()
                                Text(relativeDate(record.date))
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }

                section("BrewBar Activity") {
                    if brewEvents.isEmpty {
                        Text("No activity recorded yet.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    } else {
                        ForEach(brewEvents.prefix(20)) { event in
                            HStack(spacing: 6) {
                                Image(systemName: event.type.icon)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                if event.packages.count == 1 {
                                    Text("\(event.type.label) \(event.packages[0])")
                                        .font(.caption)
                                } else {
                                    Text("\(event.type.label) \(event.packages.count) packages")
                                        .font(.caption)
                                        .help(event.packages.joined(separator: "\n"))
                                }
                                Spacer()
                                Text(relativeDate(event.date))
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            .padding(10)
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func configRow(_ label: String, key: String) -> some View {
        infoRow(label, value: config[key] ?? "–")
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .textSelection(.enabled)
        }
    }

}
