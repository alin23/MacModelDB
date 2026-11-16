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
        XCTAssertTrue(MacModelDB.macBookModels.contains("Mac17,10"))
        XCTAssertTrue(MacModelDB.macMiniModels.contains("Mac16,10"))
        XCTAssertEqual(MacModelDB.knownModels["Mac17,10"]?.model, .macBookPro)
        XCTAssertEqual(MacModelDB.knownModels["Mac17,4"]?.model, .macBookAir)
    }

    func testFamiliesDontOverlap() {
        let families = [MacModelDB.macBookModels, MacModelDB.macMiniModels, MacModelDB.macProModels, MacModelDB.iMacModels, MacModelDB.macStudioModels]
        XCTAssertEqual(families.map(\.count).reduce(0, +), MacModelDB.knownModels.count)
    }

    func testLaptopSignalsAgreeWithTheModel() {
        // Every MacBook has a battery and a built-in keyboard; a desktop has neither.
        guard MacModelDB.knownModels[MacModelDB.modelIdentifier] != nil || MacModelDB.modelIdentifier.lowercased().hasPrefix("macbook") else { return }
        XCTAssertEqual(MacModelDB.hasLid, MacModelDB.isMacBook)
        XCTAssertEqual(MacModelDB.hasInternalBattery, MacModelDB.isMacBook)
        XCTAssertEqual(MacModelDB.hasClamshell, MacModelDB.isMacBook)
    }
}
