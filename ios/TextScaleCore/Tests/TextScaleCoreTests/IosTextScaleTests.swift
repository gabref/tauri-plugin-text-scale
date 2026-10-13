import XCTest
@testable import TextScaleCore

final class IosTextScaleTests: XCTestCase {
   // The body font size at the default category, `large`.
   private let defaultSize = 17.0

   func testDefaultBodyTextSizeGivesDefaultScale() {
      XCTAssertEqual(scale(17), 1.0)
   }

   func testBodyTextSizeGivesItsRatioToDefaultSize() {
      // The body font sizes at `extraSmall`, `extraExtraExtraLarge` and
      // `accessibilityExtraExtraExtraLarge`.
      XCTAssertEqual(scale(14), 14.0 / 17.0)
      XCTAssertEqual(scale(23), 23.0 / 17.0)
      XCTAssertEqual(scale(53), 53.0 / 17.0)
   }

   func testInvalidBodyTextSizeGivesDefaultScale() {
      XCTAssertEqual(scale(0), 1.0)
      XCTAssertEqual(scale(-17), 1.0)
      XCTAssertEqual(scale(.nan), 1.0)
      XCTAssertEqual(scale(.infinity), 1.0)
   }

   func testInvalidDefaultBodyTextSizeGivesDefaultScale() {
      XCTAssertEqual(scale(23, defaultSize: 0), 1.0)
      XCTAssertEqual(scale(23, defaultSize: -17), 1.0)
      XCTAssertEqual(scale(23, defaultSize: .nan), 1.0)
   }

   private func scale(_ size: Double, defaultSize: Double? = nil) -> Double {
      IosTextScale.scale(
         bodyTextSize: size,
         defaultBodyTextSize: defaultSize ?? self.defaultSize
      )
   }
}
