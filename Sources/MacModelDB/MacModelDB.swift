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

    /// Whether this Mac is a laptop: it has a lid, a battery, a built-in keyboard or an illuminated
    /// Apple logo.
    public static let hasLid: Bool = detectLaptopHardware()

    /// Whether this Mac has a built-in display.
    public static let hasBuiltInDisplay: Bool = detectBuiltInDisplay()

    /// A human-readable device name, e.g. "MacBook Pro", "Mac Mini".
    public static let deviceName: String = humanReadableName(for: model, identifier: modelIdentifier)

    /// Apple's name for this model, e.g. "MacBook Pro (16-inch PROLED XDR, M5 Pro or M5 Max)",
    /// or nil for a model that isn't in the database yet.
    public static let marketingName: String? = knownModels[modelIdentifier]?.name
}

// MARK: - Model Database

extension MacModelDB {
    /// Every Apple silicon Mac with a "MacXX,Y" identifier, with Apple's name for it, as printed on
    /// Apple's "Identify your Mac model" pages for each product (support.apple.com 108052, 102869,
    /// 102852, 108054, 102231 and 102887). Older identifiers such as "MacBookPro18,1" name their
    /// family and don't need an entry.
    static let knownModels: [String: (model: MacModel, name: String)] = [
        // MacBook Pro
        "Mac18,1": (.macBookPro, "MacBook Pro (14-inch, M6)"),
        "Mac17,11": (.macBookPro, "MacBook Pro (14-inch PROLED XDR, M5 Pro or M5 Max)"),
        "Mac17,13": (.macBookPro, "MacBook Pro (14-inch PROLED XDR, M5 Pro or M5 Max)"),
        "Mac17,10": (.macBookPro, "MacBook Pro (16-inch PROLED XDR, M5 Pro or M5 Max)"),
        "Mac17,12": (.macBookPro, "MacBook Pro (16-inch PROLED XDR, M5 Pro or M5 Max)"),
        "Mac17,7": (.macBookPro, "MacBook Pro (14-inch, M5 Pro or M5 Max)"),
        "Mac17,9": (.macBookPro, "MacBook Pro (14-inch, M5 Pro or M5 Max)"),
        "Mac17,6": (.macBookPro, "MacBook Pro (16-inch, M5 Pro or M5 Max)"),
        "Mac17,8": (.macBookPro, "MacBook Pro (16-inch, M5 Pro or M5 Max)"),
        "Mac17,2": (.macBookPro, "MacBook Pro (14-inch, M5)"),
        "Mac16,1": (.macBookPro, "MacBook Pro (14-inch, M4, 2024)"),
        "Mac16,6": (.macBookPro, "MacBook Pro (14-inch, M4 Pro or M4 Max, 2024)"),
        "Mac16,8": (.macBookPro, "MacBook Pro (14-inch, M4 Pro or M4 Max, 2024)"),
        "Mac16,5": (.macBookPro, "MacBook Pro (16-inch, M4 Pro or M4 Max, 2024)"),
        "Mac16,7": (.macBookPro, "MacBook Pro (16-inch, M4 Pro or M4 Max, 2024)"),
        "Mac15,3": (.macBookPro, "MacBook Pro (14-inch, M3, Nov 2023)"),
        "Mac15,6": (.macBookPro, "MacBook Pro (14-inch, M3 Pro or M3 Max, Nov 2023)"),
        "Mac15,8": (.macBookPro, "MacBook Pro (14-inch, M3 Pro or M3 Max, Nov 2023)"),
        "Mac15,10": (.macBookPro, "MacBook Pro (14-inch, M3 Pro or M3 Max, Nov 2023)"),
        "Mac15,7": (.macBookPro, "MacBook Pro (16-inch, M3 Pro or M3 Max, Nov 2023)"),
        "Mac15,9": (.macBookPro, "MacBook Pro (16-inch, M3 Pro or M3 Max, Nov 2023)"),
        "Mac15,11": (.macBookPro, "MacBook Pro (16-inch, M3 Pro or M3 Max, Nov 2023)"),
        "Mac14,5": (.macBookPro, "MacBook Pro (14-inch, 2023)"),
        "Mac14,9": (.macBookPro, "MacBook Pro (14-inch, 2023)"),
        "Mac14,6": (.macBookPro, "MacBook Pro (16-inch, 2023)"),
        "Mac14,10": (.macBookPro, "MacBook Pro (16-inch, 2023)"),
        "Mac14,7": (.macBookPro, "MacBook Pro (13-inch, M2, 2022)"),

        // MacBook Air
        "Mac17,3": (.macBookAir, "MacBook Air (13-inch, M5)"),
        "Mac17,4": (.macBookAir, "MacBook Air (15-inch, M5)"),
        "Mac16,12": (.macBookAir, "MacBook Air (13-inch, M4, 2025)"),
        "Mac16,13": (.macBookAir, "MacBook Air (15-inch, M4, 2025)"),
        "Mac15,12": (.macBookAir, "MacBook Air (13-inch, M3, 2024)"),
        "Mac15,13": (.macBookAir, "MacBook Air (15-inch, M3, 2024)"),
        "Mac14,15": (.macBookAir, "MacBook Air (15-inch, M2, 2023)"),
        "Mac14,2": (.macBookAir, "MacBook Air (M2, 2022)"),

        // Mac mini
        "Mac18,5": (.macMini, "Mac mini (M6)"),
        "Mac17,16": (.macMini, "Mac mini (M5 Pro)"),
        "Mac16,10": (.macMini, "Mac mini (2024)"),
        "Mac16,11": (.macMini, "Mac mini (2024)"),
        "Mac14,3": (.macMini, "Mac mini (M2, 2023)"),
        "Mac14,12": (.macMini, "Mac mini (M2 Pro, 2023)"),

        // iMac
        "Mac18,2": (.iMac, "iMac (24-inch, M6)"),
        "Mac16,2": (.iMac, "iMac (24-inch, 2024, Two ports)"),
        "Mac16,3": (.iMac, "iMac (24-inch, 2024, Four ports)"),
        "Mac15,4": (.iMac, "iMac (24-inch, 2023, Two ports)"),
        "Mac15,5": (.iMac, "iMac (24-inch, 2023, Four ports)"),

        // Mac Studio
        "Mac17,14": (.macStudio, "Mac Studio (M5 Max)"),
        "Mac17,15": (.macStudio, "Mac Studio (M5 Ultra)"),
        "Mac16,9": (.macStudio, "Mac Studio (M4 Max, 2025)"),
        "Mac15,14": (.macStudio, "Mac Studio (M3 Ultra, 2025)"),
        "Mac14,13": (.macStudio, "Mac Studio (M2 Max, 2023)"),
        "Mac14,14": (.macStudio, "Mac Studio (M2 Ultra, 2023)"),
        "Mac13,1": (.macStudio, "Mac Studio (M1 Max, 2022)"),
        "Mac13,2": (.macStudio, "Mac Studio (M1 Ultra, 2022)"),

        // Mac Pro
        "Mac14,8": (.macPro, "Mac Pro (2023)"),
    ]

    static func identifiers(of family: Set<MacModel>) -> Set<String> {
        Set(knownModels.filter { family.contains($0.value.model) }.keys)
    }

    static let macBookModels = identifiers(of: [.macBook, .macBookAir, .macBookPro])
    static let macMiniModels = identifiers(of: [.macMini])
    static let macProModels = identifiers(of: [.macPro])
    static let iMacModels = identifiers(of: [.iMac])
    static let macStudioModels = identifiers(of: [.macStudio])
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
        if let known = knownModels[id] { return known.model }

        // A model newer than the database: a lid, a battery or a built-in keyboard means a laptop.
        // This comes before the built-in display check, because a MacBook has a built-in display too.
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

// MARK: - Laptop Detection

extension MacModelDB {
    /// Each check reads the I/O Registry and needs no permission. The lid angle sensor is the last
    /// one, since it opens a HID device.
    private static func detectLaptopHardware() -> Bool {
        hasClamshell || hasInternalBattery || hasBuiltInKeyboard || hasIlluminatedLogo || hasLidAngleSensor()
    }

    /// The power manager publishes the clamshell state only on Macs with a lid.
    static var hasClamshell: Bool {
        let root = IOServiceGetMatchingService(mainPort, IOServiceMatching("IOPMrootDomain"))
        guard root != 0 else { return false }
        defer { IOObjectRelease(root) }
        return IORegistryEntryCreateCFProperty(root, "AppleClamshellState" as CFString, kCFAllocatorDefault, 0) != nil
    }

    static var hasInternalBattery: Bool {
        serviceExists(IOServiceMatching("AppleSmartBattery"))
    }

    /// The keyboard of a MacBook is a HID interface marked as built in. A keyboard plugged into a
    /// desktop Mac is not.
    static var hasBuiltInKeyboard: Bool {
        let matching = IOServiceMatching("IOHIDInterface") as NSMutableDictionary
        matching[kIOPropertyMatchKey] = ["Built-In": true, "PrimaryUsagePage": 1, "PrimaryUsage": 6]
        return serviceExists(matching as CFDictionary)
    }

    /// The PWM controller of the illuminated Apple logo on the lid.
    static var hasIlluminatedLogo: Bool {
        serviceExists(IOServiceNameMatching("bklb-backlight")) || serviceExists(IOServiceNameMatching("bklb-backlight@0"))
    }

    /// `kIOMainPortDefault` needs macOS 12; a null port means the same thing on every version.
    private static let mainPort: mach_port_t = 0

    private static func serviceExists(_ matching: CFDictionary) -> Bool {
        let service = IOServiceGetMatchingService(mainPort, matching)
        guard service != 0 else { return false }
        IOObjectRelease(service)
        return true
    }

    private static let lidMatchingDict: [String: Any] = [
        "VendorID": 0x05AC,
        "ProductID": 0x8104,
        "UsagePage": 0x0020,
        "Usage": 0x008A,
    ]

    private static func hasLidAngleSensor() -> Bool {
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
