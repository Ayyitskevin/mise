import SwiftUI

/// Owner "Devices" screen: every signed-in studio-owner session from
/// `GET /api/v1/auth/sessions`, with revocation for the others. The roster is
/// network-first and session-memory-only — it changes on any login, logout,
/// or expiry, so nothing here reads or writes the tenant cache.
struct OwnerDevicesView: View {
    @State private var model: ResourceModel<[SessionSummary]>
    @State private var sessionPendingRevoke: SessionSummary?
    @State private var revokeFailureMessage: String?

    private let repository: OwnerRepository

    init(repository: OwnerRepository) {
        self.repository = repository
        _model = State(initialValue: ResourceModel(
            staleAfter: 0,
            cached: { nil },
            remote: { try await repository.refreshDeviceSessions() }
        ))
    }

    var body: some View {
        ResourceView(
            model: model,
            isEmpty: { $0.isEmpty },
            content: list,
            empty: {
                ContentUnavailableView(
                    "No signed-in sessions",
                    systemImage: "iphone",
                    description: Text("Sessions appear here as soon as a device signs in.")
                )
            }
        )
        .navigationTitle("Devices")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Revoke this session?",
            isPresented: isRevokeConfirmationPresented,
            presenting: sessionPendingRevoke
        ) { session in
            Button("Revoke session", role: .destructive) {
                Task { await revoke(session) }
            }
        } message: { session in
            Text("\(deviceName(for: session)) will be signed out of this studio.")
        }
        .alert(
            "Couldn’t revoke session",
            isPresented: isRevokeFailurePresented,
            presenting: revokeFailureMessage
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    private var isRevokeConfirmationPresented: Binding<Bool> {
        Binding(
            get: { sessionPendingRevoke != nil },
            set: { if !$0 { sessionPendingRevoke = nil } }
        )
    }

    private var isRevokeFailurePresented: Binding<Bool> {
        Binding(
            get: { revokeFailureMessage != nil },
            set: { if !$0 { revokeFailureMessage = nil } }
        )
    }

    private func list(_ sessions: [SessionSummary]) -> some View {
        List {
            ForEach(sessions) { session in
                SessionRow(session: session) {
                    sessionPendingRevoke = session
                }
            }
        }
        .refreshable { await model.refresh() }
    }

    private func revoke(_ session: SessionSummary) async {
        do {
            try await repository.revokeDeviceSession(id: session.id)
            _ = await model.refreshAfterCurrent()
        } catch {
            revokeFailureMessage = error.localizedDescription
        }
    }

    private func deviceName(for session: SessionSummary) -> String {
        if let name = session.device.name, !name.isEmpty { return name }
        return "Unknown device"
    }

    private struct SessionRow: View {
        let session: SessionSummary
        let requestRevoke: () -> Void

        var body: some View {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(MiseDesign.terra)
                    .frame(width: 38, height: 38)
                    .background(MiseDesign.terraTint, in: RoundedRectangle(cornerRadius: 10))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(name).font(.subheadline.weight(.semibold))
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                if session.isCurrent {
                    StatusPill(label: "This device", tone: .ok)
                } else if session.revokedAt != nil {
                    StatusPill(label: "Revoked", tone: .neutral)
                } else {
                    Button("Revoke", action: requestRevoke)
                        .buttonStyle(.bordered)
                        .foregroundStyle(MiseDesign.clay)
                }
            }
            .padding(.vertical, 3)
        }

        private var name: String {
            if let deviceName = session.device.name, !deviceName.isEmpty {
                return deviceName
            }
            return "Unknown device"
        }

        private var icon: String {
            guard let platform = session.device.platform?.lowercased() else {
                return "iphone"
            }
            if platform.contains("ipad") { return "ipad" }
            if platform.contains("ios") || platform.contains("iphone") { return "iphone" }
            return "desktopcomputer"
        }

        private var subtitle: String {
            var parts: [String] = []
            if let appVersion = session.device.appVersion, !appVersion.isEmpty {
                parts.append("App \(appVersion)")
            }
            if let lastSeenAt = session.lastSeenAt {
                parts.append(
                    "Active " + lastSeenAt.formatted(.relative(presentation: .named))
                )
            } else {
                parts.append(
                    "Signed in " + session.createdAt.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                )
            }
            return parts.joined(separator: " · ")
        }
    }
}
