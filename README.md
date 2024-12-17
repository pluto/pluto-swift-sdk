# PlutoSwiftSDK

PlutoSwiftSDK is a Swift library that provides tools for proof generation and includes a reusable BrowserView component.

## Features


- Proof generation for your provided configuration.
- Reusable BrowserView component based on WKWebView.

## Requirements


- macOS: 11.0 or later
- Xcode: 14.0 or later
- iOS: 12.0 or later
- Swift: 5.0+


## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/PlutoSwiftSDK.git
cd PlutoSwiftSDK
```

### 2. Build the Framework

Open the Xcode project:

```bash
open PlutoSwiftSDK.xcodeproj
```

Select the PlutoSwiftSDK scheme and build it with Cmd + B.

### 3. Run the Test App


Select the PlutoSDKTestApp scheme and run it:

```bash
Cmd + R
```


### 4. Run Unit Tests


Run the tests in Xcode with Cmd + U.
Or from the terminal:

```bash
xcodebuild test -scheme PlutoSwiftSDK -destination 'platform=iOS Simulator,name=iPhone 14'
```

## Folder Structure

```
PlutoSwiftSDK/
├── Sources/                 # Source code
│   ├── Enums.swift          # Enums
│   ├── ManifestModels.swift # Models for manifest
│   ├── ManifestParser.swift # JSON parsing
│   ├── BrowserView.swift    # BrowserView component
│   └── PlutoSDK.swift       # Public API
├── Tests/                   # Unit tests
├── PlutoSDKTestApp/         # Sample app
├── PlutoSwiftSDK.xcodeproj  # Xcode project
└── README.md                # Project documentation
```

## Using PlutoSwiftSDK in Your Project

### Swift Package Manager
1. Open Xcode and go to File > Swift Packages > Add Package Dependency.
2. Enter the repository URL:
   https://github.com/yourusername/PlutoSwiftSDK.git

### CocoaPods
1. Add this to your Podfile:
```ruby
pod 'PlutoSwiftSDK', :git => 'https://github.com/yourusername/PlutoSwiftSDK.git'
```

2. Run
```bash
pod install
```

## Example Usage

### Proof Generation

```swift
import PlutoSwiftSDK

let manifestConfig = """
{
    "manifestVersion": "1.0",
    "id": "1234",
    "title": "Sample",
    "description": "This is a test.",
    "mode": "TLSN",
    "request": {
        "method": "POST",
        "url": "https://example.com/api",
        "headers": { "Content-Type": "application/json" },
        "body": "{\\"key\\":\\"value\\"}"
    },
    "response": {
        "status": "200",
        "headers": {},
        "body": {
            "json": [["key", "value"]],
            "contains": "success"
        }
    }
}
"""

if let manifest = PlutoSDK.parseManifest(config: manifestConfig) {
    print("Manifest ID: \(manifest.id)")
}
```

### BrowserView Component

```swift
import PlutoSwiftSDK
import UIKit

let browserView = BrowserView(frame: someView.bounds)
browserView.load(url: URL(string: "https://example.com")!)
someView.addSubview(browserView)
```

## Contributing
1. Fork the repository.
2. Create a new branch.
3. Commit and push your changes.
4. Open a pull request.

## License
This project is licensed under the MIT License.

## Contact
GitHub: [pluto](https://github.com/pluto)

Twitter: [@plutolabs_](https://x.com/plutolabs_)
