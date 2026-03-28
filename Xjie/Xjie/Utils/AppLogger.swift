import os

/// PROD-01: 结构化日志 — 使用 os.Logger 按类别记录
enum AppLogger {
    static let network = Logger(subsystem: "com.xjie.app", category: "network")
    static let auth    = Logger(subsystem: "com.xjie.app", category: "auth")
    static let data    = Logger(subsystem: "com.xjie.app", category: "data")
    static let ui      = Logger(subsystem: "com.xjie.app", category: "ui")
}
