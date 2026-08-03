import Foundation

enum ControlAPIError: LocalizedError {
    case missingSettings
    case invalidBaseURL
    case transportUnavailable
    case invalidResponse
    case http(Int)

    var errorDescription: String? {
        switch self {
        case .missingSettings: "请先填写 Control API 地址和访问 token"
        case .invalidBaseURL: "Control API 地址无效"
        case .transportUnavailable: "无法连接 OpenSurge Control API"
        case .invalidResponse: "Control API 返回了无效数据"
        case .http(let status): "Control API 请求失败（HTTP \(status)）"
        }
    }
}

struct ControlAPIClient {
    var baseURL: URL
    var token: String
    var session: URLSession = .shared

    func status() async throws -> MenuBarStatus {
        let endpoint = baseURL.appending(path: "api/v1/menubar")
        let data = try await request(endpoint, method: "GET")
        return try decoder().decode(MenuBarStatus.self, from: data)
    }

    func bootstrapURL(path: String) async throws -> URL {
        let endpoint = baseURL.appending(path: "api/v1/session/bootstrap")
        let body = try JSONEncoder().encode(["path": path])
        let data = try await request(endpoint, method: "POST", body: body)
        return try decoder().decode(BootstrapResponse.self, from: data).url
    }

    private func request(_ url: URL, method: String, body: Data? = nil) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = 8
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch is URLError {
            throw ControlAPIError.transportUnavailable
        }

        guard let http = response as? HTTPURLResponse else {
            throw ControlAPIError.invalidResponse
        }
        guard 200..<300 ~= http.statusCode else {
            throw ControlAPIError.http(http.statusCode)
        }
        return data
    }

    private func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()

            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: value) { return date }

            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: value) { return date }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected RFC3339 timestamp with or without fractional seconds"
            )
        }
        return decoder
    }
}
