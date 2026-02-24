import Foundation

/// Lightweight crash/diagnostics facade.
/// Replace implementation with Sentry/Crashlytics without touching call sites.
@MainActor
final class CrashReportingManager {
    struct Breadcrumb: Sendable {
        let timestamp: Date
        let category: String
        let message: String
        let metadata: [String: String]
    }
    
    enum Severity: String {
        case info
        case warning
        case error
        case critical
    }
    
    static let shared = CrashReportingManager()
    
    private(set) var breadcrumbs: [Breadcrumb] = []
    private let maxBreadcrumbs = 200
    private let formatter = ISO8601DateFormatter()
    private var configured = false
    
    private init() {}
    
    func configure() {
        guard !configured else { return }
        configured = true
        addBreadcrumb(category: "app", message: "CrashReporting configured")
    }
    
    func addBreadcrumb(category: String, message: String, metadata: [String: String] = [:]) {
        let crumb = Breadcrumb(timestamp: Date(), category: category, message: message, metadata: metadata)
        breadcrumbs.append(crumb)
        if breadcrumbs.count > maxBreadcrumbs {
            breadcrumbs.removeFirst(breadcrumbs.count - maxBreadcrumbs)
        }
        
        let meta = metadata.sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        let suffix = meta.isEmpty ? "" : " \(meta)"
        print("[CrashBreadcrumb] \(formatter.string(from: crumb.timestamp)) [\(category)] \(message)\(suffix)")
    }
    
    func record(
        error: Error,
        severity: Severity = .error,
        context: String,
        metadata: [String: String] = [:]
    ) {
        record(
            message: String(describing: error),
            severity: severity,
            context: context,
            metadata: metadata
        )
    }
    
    func record(
        message: String,
        severity: Severity = .error,
        context: String,
        metadata: [String: String] = [:]
    ) {
        addBreadcrumb(
            category: "error",
            message: "\(context): \(message)",
            metadata: metadata.merging(["severity": severity.rawValue]) { current, _ in current }
        )
        print("[CrashReport] \(severity.rawValue.uppercased()) \(context): \(message)")
    }
}
