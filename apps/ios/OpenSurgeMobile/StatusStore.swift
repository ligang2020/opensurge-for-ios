import Foundation

@MainActor
final class StatusStore: ObservableObject {
    @Published var baseURLString: String
    @Published var token: String
    @Published var status: MenuBarStatus?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isEditingSettings = false

    private let baseURLKey = "control-api-base-url"

    init() {
        let defaults = UserDefaults.standard
        self.baseURLString = defaults.string(forKey: baseURLKey) ?? "http://"
        self.token = KeychainStore.readToken()
        self.isEditingSettings = self.token.isEmpty || URL(string: self.baseURLString)?.host == nil
    }

    var canRequest: Bool {
        client() != nil
    }

    var displayBaseURL: String {
        guard let url = URL(string: baseURLString),
              let scheme = url.scheme,
              let host = url.host else {
            return "未配置"
        }
        if let port = url.port {
            return "\(scheme)://\(host):\(port)"
        }
        return "\(scheme)://\(host)"
    }

    func saveSettings() {
        guard client() != nil else {
            errorMessage = ControlAPIError.invalidBaseURL.localizedDescription
            isEditingSettings = true
            return
        }
        UserDefaults.standard.set(baseURLString.trimmingCharacters(in: .whitespacesAndNewlines), forKey: baseURLKey)
        do {
            try KeychainStore.saveToken(token.trimmingCharacters(in: .whitespacesAndNewlines))
            isEditingSettings = false
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() async {
        guard let client = client() else {
            status = nil
            errorMessage = ControlAPIError.missingSettings.localizedDescription
            isEditingSettings = true
            return
        }

        isLoading = true
        defer { isLoading = false }
        do {
            status = try await client.status()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func bootstrapURL(path: String) async -> URL? {
        guard let client = client() else {
            errorMessage = ControlAPIError.missingSettings.localizedDescription
            isEditingSettings = true
            return nil
        }

        isLoading = true
        defer { isLoading = false }
        do {
            errorMessage = nil
            return try await client.bootstrapURL(path: path)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private func client() -> ControlAPIClient? {
        let trimmedURL = baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedToken.isEmpty,
              let url = URL(string: trimmedURL),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            return nil
        }
        return ControlAPIClient(baseURL: url, token: trimmedToken)
    }
}
