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
        await log(event, app: app, tier: nil, targetVersion: nil, targetBuild: nil)
    }

    /// Log an event with privacy-safe aggregate dimensions for version adoption and update health.
    public static func log(
        _ event: String,
        app: String,
        tier: String? = nil,
        targetVersion: String? = nil,
        targetBuild: String? = nil
    ) async {
        var components = URLComponents(string: endpoint)
        components?.queryItems = queryItems(for: telemetryPayload(
            app: app,
            event: event,
            tier: tier,
            targetVersion: targetVersion,
            targetBuild: targetBuild
        ))
        guard let url = components?.url else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        _ = try? await URLSession.shared.data(for: request)
        eventLogger.debug("Event logged: \(event) for \(app)")
    }

    static func telemetryPayload(
        app: String,
        event: String,
        tier: String?,
        targetVersion: String?,
        targetBuild: String?,
        appVersion: String = appVersion(bundle: .main),
        build: String = buildVersion(bundle: .main),
        osVersion: String = osVersion(),
        platform: String = platform(),
        channel: String = distributionChannel(bundle: .main)
    ) -> [String: String] {
        var payload = [
            "app": app,
            "event": event,
            "app_version": appVersion,
            "build": build,
            "os_version": osVersion,
            "platform": platform,
            "channel": channel
        ]

        if let resolvedTier = resolvedTier(explicitTier: tier, event: event) {
            payload["tier"] = resolvedTier
        }
        if let targetVersion, !targetVersion.isEmpty {
            payload["target_version"] = targetVersion
        }
        if let targetBuild, !targetBuild.isEmpty {
            payload["target_build"] = targetBuild
        }

        return payload
    }

    static func queryItems(for payload: [String: String]) -> [URLQueryItem] {
        payload
            .sorted { $0.key < $1.key }
            .map { URLQueryItem(name: $0.key, value: $0.value) }
    }

    static func appVersion(bundle: Bundle) -> String {
        (bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nonEmpty ?? "unknown"
    }

    static func buildVersion(bundle: Bundle) -> String {
        (bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nonEmpty ?? "unknown"
    }

    static func osVersion() -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    static func platform() -> String {
        #if os(macOS)
            "macos"
        #elseif os(iOS)
            "ios"
        #elseif os(tvOS)
            "tvos"
        #elseif os(watchOS)
            "watchos"
        #elseif os(visionOS)
            "visionos"
        #else
            "unknown"
        #endif
    }

    static func distributionChannel(bundle: Bundle) -> String {
        #if SETAPP
            "setapp"
        #else
            LicenseService.isRuntimeAppStoreBuild(bundle: bundle) ? "app_store" : "direct"
        #endif
    }

    static func resolvedTier(explicitTier: String?, event: String) -> String? {
        if let explicitTier = explicitTier?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
           !explicitTier.isEmpty {
            return explicitTier
        }

        switch event {
        case "license_activated":
            return "pro"
        case "new_free_user":
            return "free"
        default:
            if event.hasSuffix("_pro") {
                return "pro"
            }
            if event.hasSuffix("_free") {
                return "free"
            }
            return nil
        }
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
