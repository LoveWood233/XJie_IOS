import Network
import Combine

/// NET-01: 网络状态监控 — 使用 NWPathMonitor 检测离线 / 在线
@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isConnected = true
    @Published private(set) var connectionType: ConnectionType = .unknown

    enum ConnectionType { case wifi, cellular, wired, unknown }

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.xjie.networkmonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.mapConnectionType(path) ?? .unknown
            }
        }
        monitor.start(queue: queue)
    }

    private func mapConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) { return .wifi }
        if path.usesInterfaceType(.cellular) { return .cellular }
        if path.usesInterfaceType(.wiredEthernet) { return .wired }
        return .unknown
    }
}
