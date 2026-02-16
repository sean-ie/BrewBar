import SwiftUI

struct InfoView: View {
    let info: BrewInfo

    private var config: [String: String] { info.brewConfig }

    private var detectedDevTools: [(name: String, version: String, path: String?)] {
        let toolNames = ["uv", "bun", "mise", "fnm", "volta", "pyenv", "rbenv", "rustup", "goenv", "jenv", "chruby", "nvm"]
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

                let taps = deriveTaps()
                if !taps.isEmpty {
                    section("Taps") {
                        ForEach(taps, id: \.self) { tap in
                            Text(tap)
                                .font(.caption)
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

    private func deriveTaps() -> [String] {
        var taps = Set<String>()
        for formula in info.formulae {
            if let tap = formula.tap { taps.insert(tap) }
        }
        for cask in info.casks {
            if let tap = cask.tap { taps.insert(tap) }
        }
        return taps.sorted()
    }
}
