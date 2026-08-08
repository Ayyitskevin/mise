import SwiftUI

struct InquiriesView: View {
    let model: ResourceModel<[InquirySummary]>
    @State private var query = ""

    var body: some View {
        ResourceView(
            model: model,
            isEmpty: { $0.isEmpty },
            content: inquiryList,
            empty: {
                ContentUnavailableView(
                    "No inquiries",
                    systemImage: "tray",
                    description: Text("New inquiries from your contact form will appear here.")
                )
            }
        )
        .navigationTitle("Inquiries")
        .searchable(text: $query, prompt: "Name, business, or service")
    }

    private func inquiryList(_ inquiries: [InquirySummary]) -> some View {
        let matches = inquiries.filter(matchesQuery)
        return List {
            if matches.isEmpty {
                ContentUnavailableView.search(text: query)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(matches) { inquiry in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(inquiry.name).font(.headline)
                            Spacer()
                            StatusPill(
                                label: inquiry.status.ownerDisplayName,
                                tone: inquiry.status.tone
                            )
                        }
                        if let business = inquiry.business, !business.isEmpty {
                            Text(business).foregroundStyle(.secondary)
                        }
                        Text(topicLine(inquiry))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if !inquiry.messagePreview.isEmpty {
                            Text(inquiry.messagePreview)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        HStack(spacing: 12) {
                            Text(inquiry.receivedAt, style: .relative)
                            if let shootOn = inquiry.shootOn {
                                Label(shootOn.rawValue, systemImage: "calendar")
                            }
                            Spacer()
                            if inquiry.isReplied {
                                Label("Replied", systemImage: "arrowshape.turn.up.left.fill")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .refreshable { await model.refresh() }
    }

    private func topicLine(_ inquiry: InquirySummary) -> String {
        let kind = inquiry.kind.replacingOccurrences(of: "_", with: " ")
        let display = kind.prefix(1).uppercased() + String(kind.dropFirst())
        if let service = inquiry.service, !service.isEmpty {
            return "\(display) · \(service)"
        }
        return display
    }

    private func matchesQuery(_ inquiry: InquirySummary) -> Bool {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return true }
        return [inquiry.name, inquiry.business, inquiry.email, inquiry.service, inquiry.kind]
            .compactMap { $0 }
            .contains { $0.localizedCaseInsensitiveContains(term) }
    }
}
