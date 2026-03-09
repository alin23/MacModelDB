import AVFoundation
import CoreGraphics
import Foundation
import IOKit.hid
import IOKit.ps

// MARK: - MacModel

/// Identifies the type of Mac hardware.
public enum MacModel: String, CaseIterable {
    case macBookAir
    case macBookPro
    case macBook
    case macMini
    case macPro
    case macStudio
    case iMac
    case xserve
    case unknown
}

// MARK: - MacModelDB

/// Detects the current Mac's model identifier and hardware type.
public enum MacModelDB {
    /// The raw model identifier string, e.g. "Mac14,7" or "MacBookPro18,1".
    public static let modelIdentifier: String = {
        #if os(iOS) && !arch(x86_64) && !arch(i386)
            return (try? sysctlString(for: [CTL_HW, HW_MACHINE])) ?? "Unknown"
        #else
            return (try? sysctlString(for: [CTL_HW, HW_MODEL])) ?? "Unknown"
        #endif
    }()

    /// The detected Mac model type for this machine.
    public static let model: MacModel = detectModel()

    /// Whether this Mac has a lid (i.e. is a laptop).
    public static let hasLid: Bool = detectLidHardware()

    /// Whether this Mac has a built-in display.
    public static let hasBuiltInDisplay: Bool = detectBuiltInDisplay()

    /// A human-readable device name, e.g. "MacBook Pro", "Mac Mini".
    public static let deviceName: String = humanReadableName(for: model, identifier: modelIdentifier)
}

// MARK: - Model Database

extension MacModelDB {
    static let macBookModels: Set<String> =
        Set([2, 5, 6, 7, 9, 10, 15].map { "Mac14,\($0)" })
            .union([2, 3, 6, 7, 8, 9, 10, 11, 12, 13].map { "Mac15,\($0)" })
            .union([1, 5, 6, 7, 8, 12, 13].map { "Mac16,\($0)" })
            .union([2, 3, 4, 5, 6, 7, 8, 9].map { "Mac17,\($0)" })

    static let macMiniModels: Set<String> =
        Set([3, 12].map { "Mac14,\($0)" })
            .union([16].map { "Mac16,\($0)" })

    static let macProModels: Set<String> =
        Set([8].map { "Mac14,\($0)" })

    static let iMacModels: Set<String> =
        Set([4, 5].map { "Mac15,\($0)" })
            .union([2, 3].map { "Mac16,\($0)" })

    static let macStudioModels: Set<String> =
        Set([1, 2].map { "Mac13,\($0)" })
            .union([13, 14].map { "Mac14,\($0)" })
            .union([14].map { "Mac15,\($0)" })
            .union([9].map { "Mac16,\($0)" })
}

// MARK: - Detection

extension MacModelDB {
    private static func detectModel() -> MacModel {
        let id = modelIdentifier
        let lower = id.lowercased()

        // Legacy identifiers (e.g. "MacBookPro18,1", "iMac20,1")
        if lower.hasPrefix("macbookair") { return .macBookAir }
        if lower.hasPrefix("macbookpro") { return .macBookPro }
        if lower.hasPrefix("macbook") { return .macBook }
        if lower.hasPrefix("macmini") { return .macMini }
        if lower.hasPrefix("macpro") { return .macPro }
        if lower.hasPrefix("macstudio") { return .macStudio }
        if lower.hasPrefix("imac") { return .iMac }
        if lower.hasPrefix("xserve") { return .xserve }

        // New-style "MacXX,Y" identifiers
        if macMiniModels.contains(id) { return .macMini }
        if macProModels.contains(id) { return .macPro }
        if iMacModels.contains(id) { return .iMac }
        if macStudioModels.contains(id) { return .macStudio }
        if macBookModels.contains(id) { return .macBook }

        // Fallback: if lid hardware is detected, it's a laptop
        if hasLid { return .macBook }

        // Fallback: built-in display without a lid means iMac
        if hasBuiltInDisplay { return .iMac }

        return .unknown
    }

    private static func humanReadableName(for model: MacModel, identifier: String) -> String {
        switch model {
        case .macBookAir: "MacBook Air"
        case .macBookPro: "MacBook Pro"
        case .macBook: "MacBook"
        case .macMini: "Mac Mini"
        case .macPro: "Mac Pro"
        case .macStudio: "Mac Studio"
        case .iMac: "iMac"
        case .xserve: "Xserve"
        case .unknown: identifier
        }
    }
}

// MARK: - Convenience

public extension MacModelDB {
    static var isMacBook: Bool { [.macBook, .macBookAir, .macBookPro].contains(model) }
    static var isMacMini: Bool { model == .macMini }
    static var isMacPro: Bool { model == .macPro }
    static var isMacStudio: Bool { model == .macStudio }
    static var isiMac: Bool { model == .iMac }
    static var isLaptop: Bool { isMacBook }
    static var isDesktop: Bool { !isLaptop && model != .unknown }

    static func batteryLevel() -> Double? {
        guard isMacBook, let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources: NSArray = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue()
        else { return nil }

        for ps in sources {
            guard let info: NSDictionary = IOPSGetPowerSourceDescription(snapshot, ps as CFTypeRef)?.takeUnretainedValue(),
                  let capacity = info[kIOPSCurrentCapacityKey] as? Int,
                  let max = info[kIOPSMaxCapacityKey] as? Int
            else { continue }

            return (max > 0) ? (Double(capacity) / Double(max)) : Double(capacity)
        }

        return nil
    }

    static var hasCamera: Bool {
        let deviceTypes: [AVCaptureDevice.DeviceType]
        if #available(macOS 14.0, *) {
            deviceTypes = [.builtInWideAngleCamera, .external, .continuityCamera]
        } else {
            deviceTypes = [.builtInWideAngleCamera, .externalUnknown]
        }
        return !AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .unspecified
        ).devices.isEmpty
    }
}

// MARK: - Lid Detection

extension MacModelDB {
    private static let lidMatchingDict: [String: Any] = [
        "VendorID": 0x05AC,
        "ProductID": 0x8104,
        "UsagePage": 0x0020,
        "Usage": 0x008A,
    ]

    private static func detectLidHardware() -> Bool {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        guard IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess else { return false }
        defer { IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone)) }

        IOHIDManagerSetDeviceMatching(manager, lidMatchingDict as CFDictionary)

        guard let cfDevices = IOHIDManagerCopyDevices(manager),
              CFSetGetCount(cfDevices) > 0 else { return false }

        let count = CFSetGetCount(cfDevices)
        var ptrs = [UnsafeRawPointer?](repeating: nil, count: count)
        CFSetGetValues(cfDevices, &ptrs)

        for ptr in ptrs {
            guard let ptr else { continue }
            let candidate = Unmanaged<IOHIDDevice>.fromOpaque(ptr).takeUnretainedValue()
            guard IOHIDDeviceOpen(candidate, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess else { continue }
            var report = [UInt8](repeating: 0, count: 8)
            var length = CFIndex(report.count)
            let ret = IOHIDDeviceGetReport(candidate, kIOHIDReportTypeFeature, 1, &report, &length)
            IOHIDDeviceClose(candidate, IOOptionBits(kIOHIDOptionsTypeNone))
            if ret == kIOReturnSuccess, length >= 3 {
                return true
            }
        }

        return false
    }
}

// MARK: - Built-in Display Detection

extension MacModelDB {
    private static func detectBuiltInDisplay() -> Bool {
        for display in CGSGetActiveDisplayList() {
            if CGDisplayIsBuiltin(display) != 0 {
                return true
            }
        }
        return false
    }

    private static func CGSGetActiveDisplayList() -> [CGDirectDisplayID] {
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &count) == .success, count > 0 else { return [] }
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetActiveDisplayList(count, &displays, &count) == .success else { return [] }
        return displays
    }
}

// MARK: - Sysctl Helpers

extension MacModelDB {
    enum SysctlError: Error {
        case unknown
        case malformedUTF8
        case posixError(POSIXErrorCode)
    }

    static func sysctlData(for keys: [Int32]) throws -> [Int8] {
        try keys.withUnsafeBufferPointer { keysPointer throws -> [Int8] in
            var requiredSize = 0
            let preFlightResult = Darwin.sysctl(
                UnsafeMutablePointer<Int32>(mutating: keysPointer.baseAddress),
                UInt32(keys.count), nil, &requiredSize, nil, 0
            )
            if preFlightResult != 0 {
                throw POSIXErrorCode(rawValue: errno).map { SysctlError.posixError($0) } ?? SysctlError.unknown
            }

            let data = [Int8](repeating: 0, count: requiredSize)
            let result = data.withUnsafeBufferPointer { dataBuffer -> Int32 in
                Darwin.sysctl(
                    UnsafeMutablePointer<Int32>(mutating: keysPointer.baseAddress),
                    UInt32(keys.count),
                    UnsafeMutableRawPointer(mutating: dataBuffer.baseAddress),
                    &requiredSize, nil, 0
                )
            }
            if result != 0 {
                throw POSIXErrorCode(rawValue: errno).map { SysctlError.posixError($0) } ?? SysctlError.unknown
            }

            return data
        }
    }

    static func sysctlString(for keys: [Int32]) throws -> String {
        let optionalString = try sysctlData(for: keys).withUnsafeBufferPointer { dataPointer -> String? in
            dataPointer.baseAddress.flatMap { String(validatingUTF8: $0) }
        }
        guard let s = optionalString else {
            throw SysctlError.malformedUTF8
        }
        return s
    }
}
