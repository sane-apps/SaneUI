import Foundation
import os.log

private let eventLogger = Logger(subsystem: "com.saneapps", category: "EventTracker")

/// Anonymous aggregate event tracking via sane-dist Worker.
/// Fire-and-forget, silent failure — must never affect app behavior.
///
/// ```swift
/// Task.detached { await EventTracker.log("upsell_shown", app: "saneclick") }
/// ```
public enum EventTracker: Sendable {
    private static let endpoint = "https://dist.saneapps.com/api/event"

    /// Log an event. Call from `Task.detached` so it never blocks the calling actor.
    public static func log(_ event: String, app: String) async {
        var components = URLComponents(string: endpoint)
        components?.queryItems = [
            URLQueryItem(name: "app", value: app),
            URLQueryItem(name: "event", value: event)
        ]
        guard let url = components?.url else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        _ = try? await URLSession.shared.data(for: request)
        eventLogger.debug("Event logged: \(event) for \(app)")
    }
}
