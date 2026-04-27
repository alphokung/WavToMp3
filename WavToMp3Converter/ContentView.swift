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

    private let nekoColor = Color(red: 82/255.0, green: 134/255.0, blue: 233/255.0)
    private let nekoLightColor = Color(red: 105/255.0, green: 210/255.0, blue: 231/255.0)

    var body: some View {
        ZStack {
            // Background Glow Gradient
            LinearGradient(
                colors: [nekoColor, nekoLightColor],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header Logo
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180)
                    .padding(.top, 30)
                    .shadow(color: .white.opacity(0.3), radius: 20, x: 0, y: 0)
                
                // Title Area
                VStack(spacing: 8) {
                    Text("NEKO CONVERTER")
                        .font(.system(size: 34, weight: .heavy, design: .default))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 3)
                    
                    Text("The wave to mp3 converter app")
                        .font(.system(size: 18, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 2)
                }
                
                Spacer()
                
                // Material Design Card Surface
                VStack(spacing: 30) {
                    // Status / Export Area
                    if isConverting {
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: nekoColor))
                                .scaleEffect(1.8)
                            Text(progressText)
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                    } else if let mp3URL = outputURL {
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            
                            Text("Conversion Complete!")
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                            
                            ShareLink(item: mp3URL) {
                                Label("Export MP3", systemImage: "square.and.arrow.up")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.green)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: .green.opacity(0.4), radius: 8, x: 0, y: 4)
                            }
                            .padding(.horizontal, 10)
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                    } else {
                        // Empty State Outline
                        VStack(spacing: 12) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 50))
                                .foregroundColor(nekoColor.opacity(0.5))
                                .padding(.bottom, 8)
                            
                            Text("Ready to Convert")
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                            
                            Text("Select a high-fidelity .wav file from your device to begin the offline conversion.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 10)
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                    }
                    
                    // Material Action Button
                    Button(action: {
                        isImporting = true
                        outputURL = nil
                    }) {
                        Text("MEOW WAV FILE TO CONVERT")
                            .font(.system(size: 16, weight: .bold)) // Material Typography
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(nekoColor)
                            .clipShape(RoundedRectangle(cornerRadius: 30))
                            .shadow(color: nekoColor.opacity(0.5), radius: 10, x: 0, y: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .disabled(isConverting)
                    .opacity(isConverting ? 0.5 : 1.0)
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 24) // Material Surface
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: .black.opacity(0.15), radius: 25, x: 0, y: 15)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
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
