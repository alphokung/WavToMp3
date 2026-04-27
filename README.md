# Neko Converter (iOS)

A modern, native iOS application built with SwiftUI that allows users to quickly convert high-fidelity `.wav` audio files into compressed `.mp3` format directly on their device. 

Since Apple's `AVFoundation` doesn't natively support MP3 encoding (only decoding and AAC encoding are natively supported), this project utilizes the **SwiftLAME** package, a powerful wrapper around the open-source LAME encoder, to achieve seamless conversion.

## Features
- **Native iOS UI:** Clean, intuitive, and built entirely using SwiftUI.
- **Direct File Importer:** Pick your source `.wav` files securely via the iOS Files app.
- **Real-time Progress Indicator:** Monitor the background conversion process accurately.
- **Easy Exporting:** Share or save the converted `.mp3` files effortlessly using `ShareLink`.
- **Modern Architecture:** Built with `async/await` and isolated Swift Tasks for ultra-smooth performance.

## Prerequisites
- macOS 12+ (For development)
- Xcode 15+
- iOS 15.0+ (Deployment Target)

## Installation & Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/alphokung/WavToMp3.git
   cd WavToMp3/WavToMp3Converter
   ```
2. Open `WavToMp3Converter.xcodeproj`.
3. The project uses Swift Package Manager (SPM). The `SwiftLAME` library dependency should automatically resolve when you open Xcode via `Package.resolved`.
4. Select your Simulator (e.g. iPhone 15) or an actual iOS device.
5. Click **Run** (`Cmd + R`).

## How to Use
1. Launch the app to view the main dashboard.
2. Tap the **"Meow Wav File to Convert"** button.
3. Browse and select a document within the Files app that ends in `.wav`.
4. Wait for the conversion process to complete. You will see a real-time progress indicator.
5. Tap **"Export MP3"** to save or share your optimized audio file!

## Technical Specifications
Audio Conversion Settings (via *SwiftLAME*):
- **Sample Rate:** `44100` Hz
- **Bitrate Mode:** Constant at `320 kbps`
- **Quality:** Best (`.best`)

## Acknowledgments
- [LAME MP3 Encoder](https://lame.sourceforge.io)
- [SwiftLAME](https://github.com/hidden-spectrum/swiftlame) by hidden-spectrum

## License
This project is open-source. However, be advised that the utilized `LAME` project requires compliance with the LGPL License framework.
