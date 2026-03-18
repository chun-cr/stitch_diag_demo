import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {
  func testFaceFrameMetadataPayload() {
    let payload = FaceFramePayload.make(imageWidth: 480, imageHeight: 640, isPreviewMirrored: true)

    XCTAssertEqual(payload["imageWidth"] as? Int, 480)
    XCTAssertEqual(payload["imageHeight"] as? Int, 640)
    XCTAssertEqual(payload["isPreviewMirrored"] as? Bool, true)
  }
}
