//
//  TorrentsView.swift
//  EhPanda
//
//  Created by 荒木辰造 on R 3/02/02.
//

import SwiftUI
import TTProgressHUD

struct TorrentsView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var hudVisible = false
    @State private var hudConfig = TTProgressHUDConfig()

    @State private var loadingFlag = false
    @State private var loadError: AppError?
    @State private var torrents = [GalleryTorrent]()

    private let gid: String
    private let token: String

    init(gid: String, token: String) {
        self.gid = gid
        self.token = token
    }

    // MARK: TorrentsView
    var body: some View {
        Group {
            if !torrents.isEmpty {
                ZStack {
                    List(torrents) { torrent in
                        TorrentRow(torrent: torrent, action: { magnetURL in
                            PasteboardUtil.save(value: magnetURL)
                            presentHUD()
                        })
                        .swipeActions { swipeActions(torrent: torrent) }
                    }
                    TTProgressHUD($hudVisible, config: hudConfig)
                }
            } else if loadingFlag {
                LoadingView()
            } else if let error = loadError {
                ErrorView(error: error, retryAction: fetchGalleryTorrents)
            } else {
                Circle().frame(width: 1).opacity(0.1)
            }
        }
        .onAppear(perform: fetchGalleryTorrents)
        .navigationBarTitle("Torrents")
    }
    // MARK: SwipeActions
    private func swipeActions(torrent: GalleryTorrent) -> some View {
        Button {
            tryPresentTorrentActivity(hash: torrent.hash, torrentURL: torrent.torrentURL)
        } label: {
            Image(systemName: "arrow.down.doc.fill")
        }
    }
}

private extension TorrentsView {
    func tryPresentTorrentActivity(hash: String, torrentURL: String) {
        guard let torrentURL = URL(string: torrentURL) else { return }
        URLSession.shared.downloadTask(with: torrentURL) { tmpURL, _, _ in
            guard let tmpURL = tmpURL,
                  var localURL = FileManager.default.urls(
                    for: .cachesDirectory, in: .userDomainMask).first
            else { return }

            localURL.appendPathComponent(hash + ".torrent")
            try? FileManager.default.copyItem(at: tmpURL, to: localURL)
            if FileManager.default.fileExists(atPath: localURL.path) {
                AppUtil.dispatchMainSync { AppUtil.presentActivity(items: [localURL]) }
            }
        }
        .resume()
    }

    func presentHUD() {
        hudConfig = TTProgressHUDConfig(
            type: .success, title: "Success".localized,
            caption: "Copied to clipboard".localized,
            shouldAutoHide: true, autoHideInterval: 1
        )
        hudVisible.toggle()
    }

    // MARK: Networking
    func fetchGalleryTorrents() {
//        loadError = nil
//        if loadingFlag { return }
//        loadingFlag = true
//
//        let sToken = SubscriptionToken()
//        GalleryTorrentsRequest(gid: gid, token: token)
//            .publisher.receive(on: DispatchQueue.main)
//            .sink { completion in
//                if case .failure(let error) = completion {
//                    Logger.error(error)
//                    loadError = error
//
//                    Logger.error(
//                        "GalleryTorrentsRequest Failed",
//                        context: ["gid": gid, "Token": token, "Error": error]
//                    )
//                }
//                loadingFlag = false
//                sToken.unseal()
//            } receiveValue: {
//                torrents = $0
//
//                Logger.info(
//                    "GalleryTorrentsRequest succeeded",
//                    context: ["gid": gid, "Token": token, "Torrents count": $0.count]
//                )
//            }
//            .seal(in: sToken)
    }
}

// MARK: TorrentRow
private struct TorrentRow: View {
    private let torrent: GalleryTorrent
    private let action: (String) -> Void

    init(torrent: GalleryTorrent, action: @escaping (String) -> Void) {
        self.torrent = torrent
        self.action = action
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.up.circle")
                    Text("\(torrent.seedCount)")
                }
                HStack(spacing: 3) {
                    Image(systemName: "arrow.down.circle")
                    Text("\(torrent.peerCount)")
                }
                HStack(spacing: 3) {
                    Image(systemName: "checkmark.circle")
                    Text("\(torrent.downloadCount)")
                }
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "doc.circle")
                    Text(torrent.fileSize)
                }
            }
            .minimumScaleFactor(0.1).lineLimit(1)
            Button {
                action(torrent.magnetURL)
            } label: {
                Text(torrent.fileName).font(.headline)
            }
            HStack {
                Spacer()
                Text(torrent.uploader)
                Text(torrent.formattedDateString)
            }
            .lineLimit(1).font(.callout)
            .foregroundStyle(.secondary)
            .minimumScaleFactor(0.5)
            .padding(.top, 10)
        }
        .padding()
    }
}
