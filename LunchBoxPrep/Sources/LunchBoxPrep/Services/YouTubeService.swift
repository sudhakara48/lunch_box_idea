import Foundation
import OSLog

private let logger = Logger(subsystem: "com.sudhakara.lunchboxprep", category: "YouTubeService")

// MARK: - Protocol

public protocol YouTubeServiceProtocol {
    func searchVideoID(for query: String) async throws -> String?
}

// MARK: - YouTubeService

/// Searches the YouTube Data API v3 for a video matching a recipe name.
/// Returns the first result's video ID, or nil if none found.
public final class YouTubeService: YouTubeServiceProtocol {

    private let session: URLSession
    private let keychainService: KeychainServiceProtocol

    public init(
        keychainService: KeychainServiceProtocol,
        session: URLSession = .shared
    ) {
        self.keychainService = keychainService
        self.session = session
    }

    public func searchVideoID(for query: String) async throws -> String? {
        let apiKey: String
        do {
            apiKey = try keychainService.loadAPIKey(account: YouTubeService.keychainAccount)
        } catch KeychainError.itemNotFound {
            logger.warning("No YouTube API key found in Keychain")
            return nil
        }

        var components = URLComponents(string: "https://www.googleapis.com/youtube/v3/search")!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "q", value: "\(query) recipe lunch"),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "maxResults", value: "1"),
            URLQueryItem(name: "key", value: apiKey),
        ]

        guard let url = components.url else { return nil }

        let (data, response) = try await session.data(from: url)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            logger.error("YouTube API error: \(http.statusCode)")
            return nil
        }

        let result = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
        return result.items.first?.id.videoId
    }

    public static let keychainAccount = "youtubeAPIKey"
}

// MARK: - Response shapes

private struct YouTubeSearchResponse: Decodable {
    let items: [YouTubeSearchItem]
}

private struct YouTubeSearchItem: Decodable {
    let id: YouTubeVideoID
}

private struct YouTubeVideoID: Decodable {
    let videoId: String?
}
