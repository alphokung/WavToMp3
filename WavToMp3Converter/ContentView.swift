import SwiftUI
import UniformTypeIdentifiers
import SwiftLAME

struct ContentView: View {
    @State private var inputURL: URL?
    @State private var outputURL: URL?
    
    @State private var isImporting = false
    @State private var isConverting = false
    @State private var progressText = ""
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Header Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: .purple.opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "waveform")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60)
                        .foregroundColor(.white)
                }
                .padding(.top, 40)
                
                Text("WAV to MP3 Converter")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Convert your high-fidelity .wav files into compressed .mp3 files effortlessly.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                Spacer()
                
                // Status / Export Area
                if isConverting {
                    VStack(spacing: 15) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                            .scaleEffect(1.5)
                        Text(progressText)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else if let mp3URL = outputURL {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        
                        Text("Conversion Complete!")
                            .font(.headline)
                        
                        ShareLink(item: mp3URL) {
                            Label("Export MP3", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .shadow(radius: 5)
                        }
                        .padding(.horizontal, 40)
                    }
                }
                
                Spacer()
                
                // Select File Button
                Button(action: {
                    isImporting = true
                    outputURL = nil
                }) {
                    Text("Select WAV File")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                .disabled(isConverting)
                .opacity(isConverting ? 0.5 : 1.0)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.wav],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result: result)
            }
            .alert("Error", isPresented: $showError, presenting: errorMessage) { _ in
                Button("OK", role: .cancel) { }
            } message: { msg in
                Text(msg)
            }
        }
    }
    
    private func handleFileSelection(result: Result<[URL], Error>) {
        do {
            guard let selectedURL = try result.get().first else { return }
            self.inputURL = selectedURL
            Task {
                await convertWavToMp3(url: selectedURL)
            }
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    private func convertWavToMp3(url: URL) async {
        guard url.startAccessingSecurityScopedResource() else {
            showError("Cannot access the selected file.")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        await MainActor.run {
            self.isConverting = true
            self.progressText = "Preparing to convert..."
        }
        
        do {
            // Create a temporary destination URL for the MP3
            let tempDir = FileManager.default.temporaryDirectory
            let outputFilename = url.deletingPathExtension().lastPathComponent + "_converted.mp3"
            let destinationURL = tempDir.appendingPathComponent(outputFilename)
            
            // Remove existing temp file if it exists
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // We will observe progress manually using a Task to keep it simple and avoid Combine boilerplate
            let progress = Progress()
            let progressTask = Task {
                while !Task.isCancelled {
                    let fraction = progress.fractionCompleted
                    await MainActor.run {
                        self.progressText = "Converting... \(Int(fraction * 100))%"
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                }
            }

            let lameEncoder = try SwiftLameEncoder(
                sourceUrl: url,
                configuration: .init(
                    sampleRate: .custom(44100),
                    bitrateMode: .constant(320),
                    quality: .best
                ),
                destinationUrl: destinationURL,
                progress: progress
            )
            
            try await lameEncoder.encode()
            progressTask.cancel()
            
            await MainActor.run {
                self.outputURL = destinationURL
                self.isConverting = false
            }
            
        } catch {
            await MainActor.run {
                self.isConverting = false
                showError("Conversion failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func showError(_ message: String) {
        Task { @MainActor in
            self.errorMessage = message
            self.showError = true
        }
    }
}

#Preview {
    ContentView()
}
