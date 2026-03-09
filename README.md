# MacModelDB

A lightweight Swift package for detecting Mac hardware type. Identifies MacBooks, iMacs, Mac Minis, Mac Pros, Mac Studios, and Xserves using Apple's model identifiers and IOKit lid hardware detection as a fallback.

## Requirements

- macOS 10.15+
- Swift 5.9+

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/alin23/MacModelDB.git", from: "1.0.0")
]
```

## Usage

```swift
import MacModelDB

// Get the raw model identifier
MacModelDB.modelIdentifier // "Mac14,7"

// Get the detected model type
MacModelDB.model // .macBookAir

// Get a human-readable name
MacModelDB.deviceName // "MacBook Air"

// Check hardware type
if MacModelDB.isMacBook {
    print("Running on a laptop")
}

if MacModelDB.isDesktop {
    print("No battery to worry about")
}
```

## API

| Property | Type | Description |
|---|---|---|
| `modelIdentifier` | `String` | Raw sysctl model string, e.g. `"Mac14,7"` |
| `model` | `MacModel` | Detected hardware type enum |
| `deviceName` | `String` | Human-readable name, e.g. `"MacBook Pro"` |
| `hasLid` | `Bool` | Whether lid hardware was detected |
| `hasBuiltInDisplay` | `Bool` | Whether a built-in display was detected |
| `isMacBook` | `Bool` | MacBook, MacBook Air, or MacBook Pro |
| `isMacMini` | `Bool` | Mac Mini |
| `isMacPro` | `Bool` | Mac Pro |
| `isMacStudio` | `Bool` | Mac Studio |
| `isiMac` | `Bool` | iMac |
| `isLaptop` | `Bool` | Same as `isMacBook` |
| `isDesktop` | `Bool` | Any non-laptop, non-unknown model |

### MacModel enum

```swift
public enum MacModel: String, Sendable, CaseIterable {
    case macBookAir, macBookPro, macBook
    case macMini, macPro, macStudio
    case iMac, xserve, unknown
}
```

## How it works

1. Reads the model identifier via `sysctl` (`hw.model`)
2. Matches against legacy identifiers (e.g. `MacBookPro18,1`) and the modern `MacXX,Y` scheme
3. Falls back to IOKit HID lid sensor detection for unrecognized laptops
4. Falls back to built-in display detection (via CoreGraphics) for unrecognized iMacs — a built-in screen without a lid implies an iMac

