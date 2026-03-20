import Foundation

enum ModelAssetLocator {
    static func pathInBundle(name: String, ext: String) -> String? {
        // 1. 先找原生 Bundle（Copy Bundle Resources）
        if let nativePath = Bundle.main.path(forResource: name, ofType: ext) {
            return nativePath
        }

        // 2. 再找 Flutter App.framework 里的 assets
        if let appBundle = Bundle(identifier: "io.flutter.flutter.app") ??
                           Bundle.allFrameworks.first(where: { $0.bundlePath.contains("App.framework") }) {
            if let flutterPath = appBundle.path(
                forResource: name,
                ofType: ext,
                inDirectory: "flutter_assets/assets/models"
            ) {
                return flutterPath
            }
        }

        return nil
    }
}