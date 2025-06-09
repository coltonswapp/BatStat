import Foundation
import Combine
import OSLog

// MARK: - LogProvider Protocol

protocol LogProvider {
    func log(level: Logger.Level, category: Logger.Category?, message: String)
}

// MARK: - LogLine Structure

struct LogLine: CustomStringConvertible {
    let timestamp: Date
    let category: Logger.Category?
    let content: String
    
    var description: String {
        if let category = category {
            return "[\(category.displayName)] \(content)"
        } else {
            return content
        }
    }
}

// MARK: - Logger Class

class Logger {
    
    // MARK: - Singleton
    
    static let shared = Logger()
    private init() {}
    
    // MARK: - Log Levels
    
    enum Level: String, CaseIterable {
        case notice = "NOTICE"
        case info = "INFO"
        case debug = "DEBUG"
        case error = "ERROR"
        
        var osLogType: OSLogType {
            switch self {
            case .notice: return .default
            case .info: return .info
            case .debug: return .debug
            case .error: return .error
            }
        }
    }
    
    // MARK: - Log Categories
    
    enum Category: String, CaseIterable {
        case general = "general"
        case auth = "auth"
        case players = "players"
        case games = "games"
        case stats = "stats"
        case database = "database"
        case networking = "networking"
        case ui = "ui"
        case navigation = "navigation"
        case settings = "settings"
        
        var displayName: String {
            switch self {
            case .general: return "🔍 General"
            case .auth: return "🔐 Auth"
            case .players: return "⚾ Players"
            case .games: return "🏟️ Games"
            case .stats: return "📊 Stats"
            case .database: return "💾 Database"
            case .networking: return "🌐 Network"
            case .ui: return "🎨 UI"
            case .navigation: return "🧭 Navigation"
            case .settings: return "⚙️ Settings"
            }
        }
    }
    
    // MARK: - Properties
    
    private var providers: [LogProvider] = []
    private let maxLogLines = 5000
    private let logQueue = DispatchQueue(label: "com.batstat.logger", qos: .utility)
    
    @Published private(set) var logLines: [LogLine] = []
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
    
    // MARK: - Public Interface
    
    static func register(_ provider: LogProvider) {
        shared.logQueue.async {
            shared.providers.append(provider)
            shared.logInternal(level: .info, category: .general, message: "## Registered new log provider: \(type(of: provider))")
        }
    }
    
    static func log(level: Level, category: Category? = .general, message: String) {
        shared.logQueue.async { [weak shared] in
            shared?.logInternal(level: level, category: category, message: message)
        }
    }
    
    static func log(level: Level, message: String) {
        log(level: level, category: .general, message: message)
    }
    
    // MARK: - Internal Implementation
    
    private func logInternal(level: Level, category: Category?, message: String) {
        let logLine = LogLine(
            timestamp: Date(),
            category: category,
            content: message
        )
        
        // Add to internal log lines
        DispatchQueue.main.async { [weak self] in
            self?.logLines.append(logLine)
            self?.cleanupIfNeeded()
        }
        
        // Distribute to providers
        providers.forEach { provider in
            provider.log(level: level, category: category, message: message)
        }
    }
    
    private func cleanupIfNeeded() {
        if logLines.count > maxLogLines {
            let excess = logLines.count - maxLogLines
            logLines.removeFirst(excess)
        }
    }
    
    // MARK: - Convenience Methods
    
    static func notice(_ message: String, category: Category? = .general) {
        log(level: .notice, category: category, message: message)
    }
    
    static func info(_ message: String, category: Category? = .general) {
        log(level: .info, category: category, message: message)
    }
    
    static func debug(_ message: String, category: Category? = .general) {
        log(level: .debug, category: category, message: message)
    }
    
    static func error(_ message: String, category: Category? = .general) {
        log(level: .error, category: category, message: message)
    }
}

// MARK: - SystemProvider

class SystemProvider: LogProvider {
    private let subsystem: String
    private let osLog: OSLog
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    init() {
        self.subsystem = Bundle.main.bundleIdentifier ?? "com.batstat.app"
        self.osLog = OSLog(subsystem: subsystem, category: "BatStat")
    }
    
    func log(level: Logger.Level, category: Logger.Category?, message: String) {
        let timestamp = dateFormatter.string(from: Date())
        let categoryPrefix = category?.displayName ?? "General"
        let formattedMessage = "[\(timestamp)] [\(categoryPrefix)] \(message)"
        
        os_log("%{public}@", log: osLog, type: level.osLogType, formattedMessage)
    }
}

// MARK: - Logger Setup Extension

extension Logger {
    static func setup() {
        // Register the system provider by default
        register(SystemProvider())
        
        info("Logger system initialized", category: .general)
        info("Available categories: \(Category.allCases.map { $0.displayName }.joined(separator: ", "))", category: .general)
    }
}