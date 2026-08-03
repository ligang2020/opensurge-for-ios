# OpenSurge iOS 客户端

apps/ios 是 OpenSurge 的手机端控制客户端。它不会把 iPhone 变成 OpenSurge 网关；网关、DHCP/DNS、mihomo、TUN、PF/NAT 和 root helper 仍然只能运行在 Mac 上。

手机端当前提供：

- 配置 Mac Control API 地址与 Bearer token；
- 查看 /api/v1/menubar 返回的网关状态、拓扑、客户端数、DHCP/DNS、mihomo、TUN、PF 和恢复提醒；
- 请求一次性 bootstrap URL，并在浏览器中打开 Web 控制面板或网络恢复页面。

## 本地打包

需要完整 Xcode。只有 Command Line Tools 时，xcodebuild archive/build 无法产出 iOS IPA。

运行：

    make ios-ipa

默认输出：

    artifacts/ios/OpenSurge-Mobile-0.1.0-unsigned.ipa

unsigned IPA 只用于 CI 验证或后续重签名，不能直接安装到真机。要得到可安装 IPA，需要 Apple Developer Team、Distribution 证书和匹配的 provisioning profile。

## GitHub Actions

.github/workflows/ios-ipa.yml 支持手动触发，也会在 master push 和 ios-v*.*.* tag push 时构建 unsigned IPA artifact。

如果仓库配置以下 secrets，同一 workflow 还会额外产出 signed IPA artifact：

- IOS_CERTIFICATE_BASE64：.p12 证书的 base64；
- IOS_CERTIFICATE_PASSWORD：.p12 密码；
- IOS_PROVISIONING_PROFILE_BASE64：.mobileprovision 的 base64；
- IOS_DEVELOPMENT_TEAM：Apple Team ID；
- IOS_BUNDLE_IDENTIFIER：可选，默认 com.opensurge.mobile；
- IOS_EXPORT_METHOD：可选，默认 ad-hoc。

## 连接限制

当前 macOS Control API 默认只监听 127.0.0.1:61767。手机要访问它，需要先用安全方式把 Control API 暴露给手机，例如 VPN、Tailscale、SSH 隧道或受控反向代理。不要把带 token 的 Control API 直接暴露到公网。
