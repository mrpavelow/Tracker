import Foundation
import AppMetricaCore

enum AnalyticsEventType: String {
    case open   = "open"
    case close  = "close"
    case click  = "click"
}

enum AnalyticsScreen: String {
    case main = "Main"
}

enum AnalyticsItem: String {
    case addTrack = "add_track"
    case track    = "track"
    case filter   = "filter"
    case edit     = "edit"
    case delete   = "delete"
}

enum AnalyticsService {
    static func track(
        event: AnalyticsEventType,
        screen: AnalyticsScreen,
        item: AnalyticsItem? = nil
    ) {
        var params: [AnyHashable: Any] = [
            "event": event.rawValue,
            "screen": screen.rawValue
        ]

        if let item = item {
            params["item"] = item.rawValue
        }

        AppMetrica.reportEvent(name: "ui_event", parameters: params)
    }
}
