import SwiftUI

struct ServicesView: View {
    let services: [BrewService]
    let onStart: (String) -> Void
    let onStop: (String) -> Void
    let onRestart: (String) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if services.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "gearshape.2")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text("No services found")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                } else {
                    ForEach(services) { service in
                        ServiceRowView(
                            service: service,
                            onStart: { onStart(service.name) },
                            onStop: { onStop(service.name) },
                            onRestart: { onRestart(service.name) }
                        )
                        .padding(.horizontal, 8)
                        Divider()
                    }
                }
            }
        }
    }
}
