import Foundation

enum ModelAssetLocator {
    static func pathInBundle(name: String, ext: String) -> String? {
        if let nativePath = Bundle.main.path(forResource: name, ofType: ext) {
            return nativePath
        }

        if let flutterAssetPath = Bundle.main.path(
            forResource: name,
            ofType: ext,
            inDirectory: "flutter_assets/assets/models"
        ) {
            return flutterAssetPath
        }

        return nil
    }
}
