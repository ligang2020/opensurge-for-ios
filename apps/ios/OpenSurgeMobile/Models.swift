import Foundation
import SwiftUI

struct MenuBarStatus: Codable, Equatable {
    let schemaVersion: Int
    let revision: String
    let gateway: String
    let topology: String
    let lanIp: String
    let dhcp: String
    let mihomo: String
    let tun: String?
    let tunInterface: String?
    let tunError: String?
    let pfAnchor: String
    let forwarding: String
    let clientCount: Int
    let drift: Bool
    let doctorHealthy: Bool
    let recoveryRequired: Bool
    let recoveryStage: String?
    let warnings: [String]
    let errorCode: String?

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case revision, gateway, topology
        case lanIp = "lan_ip"
        case dhcp, mihomo, tun
        case tunInterface = "tun_interface"
        case tunError = "tun_error"
        case pfAnchor = "pf_anchor"
        case forwarding
        case clientCount = "client_count"
        case drift
        case doctorHealthy = "doctor_healthy"
        case recoveryRequired = "recovery_required"
        case recoveryStage = "recovery_stage"
        case warnings
        case errorCode = "error_code"
    }
}

struct BootstrapResponse: Codable {
    let schemaVersion: Int
    let url: URL
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case url
        case expiresAt = "expires_at"
    }
}

enum IndicatorState: Equatable {
    case connecting
    case stopped
    case running
    case degraded
    case recovery
    case unreachable

    var systemImage: String {
        switch self {
        case .connecting: "network"
        case .stopped: "network"
        case .running: "network.badge.shield.half.filled"
        case .degraded: "exclamationmark.circle"
        case .recovery: "exclamationmark.triangle.fill"
        case .unreachable: "network.slash"
        }
    }

    var title: String {
        switch self {
        case .connecting: "正在连接"
        case .stopped: "已停止"
        case .running: "运行中"
        case .degraded: "运行异常"
        case .recovery: "需要恢复"
        case .unreachable: "不可达"
        }
    }

    var tint: Color {
        switch self {
        case .connecting: .secondary
        case .stopped: .secondary
        case .running: .green
        case .degraded: .orange
        case .recovery: .red
        case .unreachable: .red
        }
    }
}

extension MenuBarStatus {
    var topologyLabel: String {
        switch topology {
        case "same_wifi_dhcp": "局域网 DHCP 接管"
        case "same_lan": "旁路由模式"
        case "isolated_lan": "独立下游 LAN"
        default: topology
        }
    }

    var recoveryNeedsAttention: Bool {
        guard recoveryRequired else { return false }
        guard let stage = recoveryStage else { return true }
        return !["prepared", "gateway_active", "client_validated", "client_validation_skipped"].contains(stage)
    }

    var takeoverActive: Bool {
        guard recoveryRequired, let stage = recoveryStage else { return false }
        return ["gateway_active", "client_validated", "client_validation_skipped"].contains(stage)
    }

    var recoverySnapshotPrepared: Bool {
        recoveryRequired && recoveryStage == "prepared"
    }

    var indicator: IndicatorState {
        if recoveryNeedsAttention { return .recovery }
        if gateway == "stopped" { return .stopped }
        if gateway == "degraded" || drift || !doctorHealthy { return .degraded }
        if gateway == "running" { return .running }
        return .stopped
    }

    var tunLabel: String {
        guard let tun else { return "unknown" }
        if let tunInterface {
            return "\(tun) · \(tunInterface)"
        }
        return tun
    }
}
