import XCTest
@testable import TextScaleCore

final class TextScaleChangesTests: XCTestCase {
   func testNoScaleBeforeFirstUpdate() {
      let changes = TextScaleChanges()

      XCTAssertNil(changes.scale)
   }

   func testFirstScaleIsNotChange() {
      var changes = TextScaleChanges()

      XCTAssertNil(changes.update(1.5))
      XCTAssertEqual(changes.scale, 1.5)
   }

   func testSameScaleIsNotChange() {
      var changes = TextScaleChanges()

      _ = changes.update(1.0)

      XCTAssertNil(changes.update(1.0))
      XCTAssertEqual(changes.scale, 1.0)
   }

   func testNewScaleIsChange() {
      var changes = TextScaleChanges()

      _ = changes.update(1.0)

      XCTAssertEqual(changes.update(1.5), 1.5)
      XCTAssertEqual(changes.scale, 1.5)
   }

   func testChangeBecomesScaleToCompareAgainst() {
      var changes = TextScaleChanges()

      _ = changes.update(1.0)
      _ = changes.update(1.5)

      XCTAssertNil(changes.update(1.5))
      XCTAssertEqual(changes.update(1.0), 1.0)
   }
}
