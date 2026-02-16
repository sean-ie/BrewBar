import SwiftUI

struct PackageRowView: View {
    let name: String
    let version: String
    let description: String?
    let isCask: Bool
    let homepage: String?
    let license: String?
    let tap: String?
    let dependencies: [String]
    let buildDependencies: [String]
    let autoUpdates: Bool

    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail.toggle()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(name)
                            .fontWeight(.medium)
                        StatusBadge(
                            text: isCask ? "cask" : "formula",
                            color: isCask ? .purple : .blue
                        )
                    }
                    if let description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Text(version)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showDetail) {
            PackageDetailView(
                name: name,
                version: version,
                description: description,
                homepage: homepage,
                isCask: isCask,
                license: license,
                tap: tap,
                dependencies: dependencies,
                buildDependencies: buildDependencies,
                autoUpdates: autoUpdates
            )
        }
    }
}
