import Foundation
import Security

// MARK: - Protocol

public protocol KeychainServiceProtocol {
    func save(apiKey: String) throws
    func loadAPIKey() throws -> String
    func deleteAPIKey() throws
    func save(apiKey: String, account: String) throws
    func loadAPIKey(account: String) throws -> String
    func deleteAPIKey(account: String) throws
}

// MARK: - Implementation

/// Stores and retrieves API keys using the iOS Keychain.
public final class KeychainService: KeychainServiceProtocol {

    private let service: String
    private let defaultAccount: String

    public init(
        service: String = "com.lunchboxprep.apikey",
        account: String = "apiKey"
    ) {
        self.service = service
        self.defaultAccount = account
    }

    // MARK: - Default account

    public func save(apiKey: String) throws {
        try save(apiKey: apiKey, account: defaultAccount)
    }

    public func loadAPIKey() throws -> String {
        try loadAPIKey(account: defaultAccount)
    }

    public func deleteAPIKey() throws {
        try deleteAPIKey(account: defaultAccount)
    }

    // MARK: - Named account

    public func save(apiKey: String, account: String) throws {
        guard let data = apiKey.data(using: .utf8) else {
            throw KeychainError.unexpectedStatus(errSecParam)
        }
        let query = baseQuery(account: account)
        let attributes: [CFString: Any] = [kSecValueData: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var addQuery = baseQuery(account: account)
            addQuery[kSecValueData] = data
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainService.keychainError(for: addStatus)
            }
        default:
            throw KeychainService.keychainError(for: updateStatus)
        }
    }

    public func loadAPIKey(account: String) throws -> String {
        var query = baseQuery(account: account)
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            guard let data = result as? Data, let key = String(data: data, encoding: .utf8) else {
                throw KeychainError.unexpectedStatus(errSecDecode)
            }
            return key
        case errSecItemNotFound:
            throw KeychainError.itemNotFound
        default:
            throw KeychainService.keychainError(for: status)
        }
    }

    public func deleteAPIKey(account: String) throws {
        let query = baseQuery(account: account)
        let status = SecItemDelete(query as CFDictionary)
        switch status {
        case errSecSuccess, errSecItemNotFound:
            return
        default:
            throw KeychainService.keychainError(for: status)
        }
    }

    // MARK: - Helpers

    private func baseQuery(account: String) -> [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
    }

    private static func keychainError(for status: OSStatus) -> KeychainError {
        switch status {
        case errSecItemNotFound:  return .itemNotFound
        case errSecDuplicateItem: return .duplicateItem
        default:                  return .unexpectedStatus(status)
        }
    }
}
