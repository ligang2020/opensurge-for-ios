import SwiftUI

struct ContentView: View {
    @Environment(\.openURL) private var openURL
    @StateObject private var store = StatusStore()

    var body: some View {
        NavigationStack {
            List {
                if let status = store.status {
                    StatusSection(status: status)
                }

                if let errorMessage = store.errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }

                connectionSection
                actionSection
            }
            .navigationTitle("OpenSurge")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await store.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(store.isLoading || !store.canRequest)
                }
            }
            .refreshable {
                await store.refresh()
            }
            .task {
                guard store.canRequest else { return }
                await store.refresh()
            }
        }
    }

    private var connectionSection: some View {
        Section {
            if store.isEditingSettings {
                TextField("http://mac.local:61767", text: $store.baseURLString)
                    .keyboardURLStyle()
                SecureField("Bearer token", text: $store.token)
                    .textContentType(.password)
                Button {
                    store.saveSettings()
                    Task { await store.refresh() }
                } label: {
                    Label("保存并刷新", systemImage: "checkmark.circle")
                }
                .disabled(store.isLoading)
            } else {
                LabeledContent("Control API", value: store.displayBaseURL)
                Button {
                    store.isEditingSettings = true
                } label: {
                    Label("修改连接", systemImage: "slider.horizontal.3")
                }
            }
        } header: {
            Text("连接")
        } footer: {
            Text("手机端连接 Mac 上的 OpenSurge Control API；网关、DHCP、TUN 和 PF 仍运行在 Mac。")
        }
    }

    private var actionSection: some View {
        Section {
            Button {
                Task { await store.refresh() }
            } label: {
                Label(store.isLoading ? "正在刷新" : "刷新状态", systemImage: "arrow.clockwise")
            }
            .disabled(store.isLoading || !store.canRequest)

            Button {
                Task {
                    if let url = await store.bootstrapURL(path: "") {
                        openURL(url)
                    }
                }
            } label: {
                Label("打开控制面板", systemImage: "safari")
            }
            .disabled(store.isLoading || !store.canRequest)

            if store.status?.recoveryRequired == true {
                Button {
                    Task {
                        if let url = await store.bootstrapURL(path: "network") {
                            openURL(url)
                        }
                    }
                } label: {
                    Label("查看网络恢复", systemImage: "wrench.and.screwdriver")
                }
                .disabled(store.isLoading || !store.canRequest)
            }
        } header: {
            Text("操作")
        }
    }
}

private struct StatusSection: View {
    let status: MenuBarStatus

    var body: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: status.indicator.systemImage)
                    .font(.title2)
                    .foregroundStyle(status.indicator.tint)
                VStack(alignment: .leading, spacing: 4) {
                    Text(status.indicator.title)
                        .font(.headline)
                    Text(status.topologyLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(status.gateway.capitalized)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(status.indicator.tint.opacity(0.14), in: Capsule())
                    .foregroundStyle(status.indicator.tint)
            }

            LabeledContent("LAN IP", value: status.lanIp)
            LabeledContent("Clients", value: String(status.clientCount))
            LabeledContent("DHCP / DNS", value: status.dhcp)
            LabeledContent("mihomo", value: status.mihomo)
            LabeledContent("TUN", value: status.tunLabel)
            LabeledContent("PF", value: status.pfAnchor)
            LabeledContent("Forwarding", value: status.forwarding)

            if status.drift {
                Label("配置已修改，需要重启网关", systemImage: "arrow.triangle.2.circlepath")
                    .foregroundStyle(.orange)
            }
            if status.takeoverActive {
                Label("局域网 DHCP 接管正在运行", systemImage: "checkmark.shield")
                    .foregroundStyle(.green)
            }
            if status.recoverySnapshotPrepared {
                Label("恢复资料已准备，尚未改动网络", systemImage: "doc.text")
                    .foregroundStyle(.secondary)
            }
            ForEach(status.warnings, id: \.self) { warning in
                Label(warning, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }
        } header: {
            Text("状态")
        }
    }
}

private extension View {
    @ViewBuilder
    func keyboardURLStyle() -> some View {
        #if os(iOS)
        self
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        #else
        self
        #endif
    }
}
