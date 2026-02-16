import SwiftUI

struct ServiceRowView: View {
    let service: BrewService
    let onStart: () -> Void
    let onStop: () -> Void
    let onRestart: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(service.name)
                    .fontWeight(.medium)
                HStack(spacing: 4) {
                    statusBadge
                    if let pid = service.pid {
                        Text("PID: \(pid)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            HStack(spacing: 4) {
                switch service.status {
                case .started:
                    Button(action: onStop) {
                        Image(systemName: "stop.fill")
                    }
                    .help("Stop")
                    Button(action: onRestart) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Restart")
                case .stopped, .unknown:
                    Button(action: onStart) {
                        Image(systemName: "play.fill")
                    }
                    .help("Start")
                case .error:
                    Button(action: onRestart) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Restart")
                }
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch service.status {
        case .started:
            StatusBadge(text: "running", color: .green)
        case .stopped:
            StatusBadge(text: "stopped", color: .secondary)
        case .error:
            StatusBadge(text: "error", color: .red)
        case .unknown:
            StatusBadge(text: "unknown", color: .orange)
        }
    }
}
