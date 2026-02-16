import SwiftUI

struct PackageDetailView: View {
    let name: String
    let version: String
    let description: String?
    let homepage: String?
    let isCask: Bool
    let license: String?
    let tap: String?
    let dependencies: [String]
    let buildDependencies: [String]
    let autoUpdates: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.headline)
                StatusBadge(
                    text: isCask ? "cask" : "formula",
                    color: isCask ? .purple : .blue
                )
            }

            Text("v\(version)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            if let homepage, let url = URL(string: homepage) {
                LabeledContent("Homepage") {
                    Link(url.host ?? homepage, destination: url)
                        .font(.caption)
                }
            }

            if let tap {
                detailRow("Tap", value: tap)
            }

            if let license {
                detailRow("License", value: license)
            }

            if isCask {
                detailRow("Auto-updates", value: autoUpdates ? "Yes" : "No")
            }

            if !dependencies.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dependencies")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(dependencies.joined(separator: ", "))
                        .font(.caption)
                }
            }

            if !buildDependencies.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Build Dependencies")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(buildDependencies.joined(separator: ", "))
                        .font(.caption)
                }
            }
        }
        .padding(12)
        .frame(width: 280, alignment: .leading)
    }

    private func detailRow(_ label: String, value: String) -> some View {
        LabeledContent(label) {
            Text(value)
                .font(.caption)
        }
        .font(.caption)
    }
}
