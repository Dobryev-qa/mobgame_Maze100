import Foundation

/// Lightweight analytics facade used for production event instrumentation.
/// Replace internals with a real SDK (Firebase/Amplitude/etc.) without changing call sites.
@MainActor
final class AnalyticsManager {
    struct EventRecord: Sendable {
        let name: String
        let properties: [String: String]
        let timestamp: Date
    }
    
    enum Event: String {
        case levelStart = "level_start"
        case levelComplete = "level_complete"
        case playerDeath = "player_death"
        case pause = "pause"
        case resume = "resume"
        case rewardedStarted = "rewarded_started"
        case rewardedRewarded = "rewarded_rewarded"
        case purchaseStarted = "iap_purchase_started"
        case purchaseSuccess = "iap_purchase_success"
        case purchaseFail = "iap_purchase_fail"
        case purchasePending = "iap_purchase_pending"
        case purchaseCancelled = "iap_purchase_cancelled"
        case restoreStarted = "iap_restore_started"
        case restoreSuccess = "iap_restore_success"
        case restoreFail = "iap_restore_fail"
        case progressReset = "progress_reset"
    }
    
    static let shared = AnalyticsManager()
    
    private(set) var recentEvents: [EventRecord] = []
    private let maxBufferedEvents = 200
    private let iso8601 = ISO8601DateFormatter()
    
    private init() {}
    
    func track(_ event: Event, properties: [String: String] = [:]) {
        track(event.rawValue, properties: properties)
    }
    
    func track(_ name: String, properties: [String: String] = [:]) {
        let record = EventRecord(name: name, properties: properties, timestamp: Date())
        recentEvents.append(record)
        if recentEvents.count > maxBufferedEvents {
            recentEvents.removeFirst(recentEvents.count - maxBufferedEvents)
        }
        
        let props = properties
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        let suffix = props.isEmpty ? "" : " \(props)"
        print("[Analytics] \(iso8601.string(from: record.timestamp)) \(name)\(suffix)")
    }
}
