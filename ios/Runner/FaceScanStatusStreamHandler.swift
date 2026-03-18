import Flutter
import Foundation

final class FaceScanStatusStreamHandler: NSObject, FlutterStreamHandler {
    static let shared = FaceScanStatusStreamHandler()

    private var eventSink: FlutterEventSink?
    private var lastValue: Bool?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        if let lastValue = lastValue {
            events(lastValue)
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    func publish(hasFace: Bool) {
        if lastValue == hasFace {
            return
        }

        lastValue = hasFace
        DispatchQueue.main.async {
            self.eventSink?(hasFace)
        }
    }
}
