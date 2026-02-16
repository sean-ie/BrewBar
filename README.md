# BrewBar

A native macOS menu bar application for managing Homebrew packages, services, and system information.

## Features

- **Dashboard** - Quick overview of installed packages, outdated items, and system health
- **Package Management** - Browse and manage all installed formulae and casks
- **Update Detection** - Automatic detection of outdated packages with one-click upgrades
- **Service Control** - Start, stop, and restart Homebrew services
- **System Info** - View Homebrew configuration and installation details
- **Redundancy Detection** - Identify and remove redundant packages
- **Auto-Refresh** - Automatically updates package information every 5 minutes

## Screenshots

<!-- Add screenshots here when ready -->
_Coming soon_

## Requirements

- macOS 14.0 (Sonoma) or later
- [Homebrew](https://brew.sh) installed
- Swift 6.0 or later (for building from source)

## Installation

### Option 1: Download Release (Recommended)

1. Download the latest `.dmg` from [Releases](https://github.com/yourusername/BrewBar/releases)
2. Open the `.dmg` file
3. Drag BrewBar to your Applications folder
4. Launch BrewBar from Applications
5. Grant necessary permissions when prompted

### Option 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/BrewBar.git
cd BrewBar

# Build the app
swift build -c release

# Run the app
.build/release/BrewBar
```

## Usage

1. **Launch BrewBar** - Click the beer mug icon in your menu bar
2. **Navigate Tabs** - Switch between Dashboard, Packages, Outdated, Services, and Info
3. **Refresh** - Click the refresh button to update package information
4. **Upgrade Packages** - Go to the Outdated tab and click upgrade buttons
5. **Manage Services** - Control Homebrew services from the Services tab

### Keyboard Shortcuts

- **⌘Q** - Quit BrewBar
- **⌘R** - Refresh (when menu is open)

## Development

### Project Structure

```
BrewBar/
├── Sources/
│   └── BrewBar/
│       ├── BrewBarApp.swift      # Main app entry point
│       ├── AppDelegate.swift     # App lifecycle management
│       ├── Models/               # Data models
│       ├── ViewModels/           # View logic
│       ├── Views/                # SwiftUI views
│       └── Services/             # Homebrew interaction layer
├── Package.swift                 # Swift Package Manager manifest
└── README.md
```

### Building for Development

```bash
# Open in Xcode
swift package generate-xcodeproj
open BrewBar.xcodeproj

# Or build with Swift Package Manager
swift build

# Run tests (when available)
swift test
```

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Roadmap

- [ ] Add search/filter functionality
- [ ] Package installation from menu bar
- [ ] Custom refresh intervals
- [ ] Notifications for outdated packages
- [ ] Dark mode support customization
- [ ] Export/import package lists

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [Swift](https://swift.org) and [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- Manages [Homebrew](https://brew.sh) packages
- Icons from [SF Symbols](https://developer.apple.com/sf-symbols/)

## Support

If you encounter any issues or have suggestions, please [open an issue](https://github.com/yourusername/BrewBar/issues).

---

Made with ☕ for macOS
