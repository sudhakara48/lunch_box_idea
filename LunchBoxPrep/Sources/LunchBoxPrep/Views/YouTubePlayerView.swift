import SwiftUI
#if os(iOS)
import WebKit

// MARK: - YouTubePlayerView

/// Embeds a YouTube video using WKWebView with the iframe player API.
public struct YouTubePlayerView: UIViewRepresentable {
    let videoID: String

    public init(videoID: String) {
        self.videoID = videoID
    }

    public func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .black
        return webView
    }

    public func updateUIView(_ webView: WKWebView, context: Context) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          body { margin: 0; background: #000; }
          iframe { width: 100%; height: 100%; border: none; }
        </style>
        </head>
        <body>
        <iframe
          src="https://www.youtube.com/embed/\(videoID)?playsinline=1&autoplay=0"
          allow="autoplay; encrypted-media"
          allowfullscreen>
        </iframe>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
    }
}

// MARK: - YouTubePlayerSheet

/// Full-screen sheet wrapping the YouTube player.
struct YouTubePlayerSheet: View {
    let videoID: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            YouTubePlayerView(videoID: videoID)
                .aspectRatio(16/9, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .navigationTitle("Watch Recipe")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}
#endif
