@testable import MacModelDB
import XCTest

final class MacModelDBTests: XCTestCase {
    func testModelIdentifierIsNotEmpty() {
        XCTAssertFalse(MacModelDB.modelIdentifier.isEmpty)
        XCTAssertNotEqual(MacModelDB.modelIdentifier, "Unknown")
    }

    func testModelIsDetected() {
        XCTAssertNotEqual(MacModelDB.model, .unknown)
    }

    func testDeviceNameIsNotEmpty() {
        XCTAssertFalse(MacModelDB.deviceName.isEmpty)
    }

    func testConveniencePropertiesAreConsistent() {
        if MacModelDB.isMacBook {
            XCTAssertTrue([MacModel.macBook, .macBookAir, .macBookPro].contains(MacModelDB.model))
            XCTAssertTrue(MacModelDB.isLaptop)
            XCTAssertFalse(MacModelDB.isDesktop)
        }
        if MacModelDB.isDesktop {
            XCTAssertFalse(MacModelDB.isLaptop)
        }
    }

    func testModelDatabaseContainsExpectedEntries() {
        XCTAssertTrue(MacModelDB.macBookModels.contains("Mac14,2"))
        XCTAssertTrue(MacModelDB.macMiniModels.contains("Mac14,3"))
        XCTAssertTrue(MacModelDB.macProModels.contains("Mac14,8"))
        XCTAssertTrue(MacModelDB.iMacModels.contains("Mac15,4"))
        XCTAssertTrue(MacModelDB.macStudioModels.contains("Mac13,1"))
    }
}
