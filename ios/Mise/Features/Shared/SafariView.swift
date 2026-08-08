import SafariServices
import SwiftUI

/// In-app browser for server-authoritative web flows (docs/IOS-UPGRADE.md
/// item ④, ADR 0067). Proposal accept/decline, contract signing, and invoice
/// checkout stay on the studio's canonical pages; presenting them as a sheet
/// keeps the client inside the app shell, and the caller revalidates its
/// documents when the sheet is dismissed.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(
        _ uiViewController: SFSafariViewController,
        context: Context
    ) {}
}
