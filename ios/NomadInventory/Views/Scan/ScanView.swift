import SwiftUI
import AVFoundation

struct ScanView: View {
    var onItemSaved: (() -> Void)? = nil
    var onClose: (() -> Void)? = nil

    @EnvironmentObject private var lang: LocalizationManager
    @StateObject private var camera = CameraService()
    @StateObject private var ai = AIService()

    @State private var phase: ScanPhase = .idle
    @State private var identified: IdentifiedItem? = nil
    @State private var showConfirm = false
    @State private var flashOn = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    enum ScanPhase {
        case idle, analysing, confirmed, error
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Live camera feed
                if camera.authorizationStatus == .authorized {
                    CameraPreview(session: camera.session)
                        .ignoresSafeArea()
                } else {
                    Color.black.ignoresSafeArea()
                }

                // Viewfinder overlay
                viewfinderOverlay

                // Bottom control bar
                VStack {
                    Spacer()
                    bottomBar
                }
            }
            .navigationTitle(lang.s(.scanTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.black.opacity(0.6), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        camera.stopSession()
                        onClose?()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }
            }
            .task {
                await camera.requestAccess()
            }
            .onDisappear {
                camera.stopSession()
            }
            .sheet(isPresented: $showConfirm) {
                if let img = camera.capturedImage {
                    ItemConfirmView(
                        photo: img,
                        identified: identified,
                        onSave: { onItemSaved?(); showConfirm = false; phase = .idle; camera.capturedImage = nil },
                        onRetake: { showConfirm = false; phase = .idle; camera.capturedImage = nil }
                    )
                }
            }
            .alert("Camera Access Required",
                   isPresented: .constant(camera.authorizationStatus == .denied)) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please allow camera access in Settings to scan items.")
            }
            .alert("AI Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Viewfinder overlay

    private var viewfinderOverlay: some View {
        GeometryReader { geo in
            let boxSize = min(geo.size.width, geo.size.height) * 0.68
            let x = (geo.size.width - boxSize) / 2
            let y = (geo.size.height - boxSize) / 2 - 40

            ZStack {
                // Darkened surround
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .mask(
                        Rectangle()
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .frame(width: boxSize, height: boxSize)
                                    .offset(x: 0, y: -40)
                                    .blendMode(.destinationOut)
                            )
                    )

                // Corner brackets
                CornerBrackets(size: boxSize)
                    .position(x: geo.size.width / 2, y: y + boxSize / 2)
                    .foregroundStyle(.white)

                // Status label
                if phase == .analysing {
                    VStack {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.4)
                        Text(lang.s(.identifying))
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .position(x: geo.size.width / 2, y: y + boxSize / 2)
                }
            }
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(alignment: .center, spacing: 40) {
            // Flash toggle
            Button {
                flashOn.toggle()
                camera.toggleFlash()
            } label: {
                Image(systemName: flashOn ? "bolt.fill" : "bolt.slash")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
            }

            // Shutter button
            Button { captureAndAnalyse() } label: {
                ZStack {
                    Circle()
                        .strokeBorder(.white, lineWidth: 3)
                        .frame(width: 72, height: 72)
                    Circle()
                        .fill(.white)
                        .frame(width: 60, height: 60)
                }
            }
            .disabled(phase == .analysing || !camera.isSessionRunning)

            // Placeholder for symmetry
            Color.clear.frame(width: 50, height: 50)
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 40)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Capture flow

    private func captureAndAnalyse() {
        camera.capturePhoto()
        phase = .analysing

        Task {
            // Poll briefly for the captured image (max ~3s)
            for _ in 0..<30 {
                if camera.capturedImage != nil { break }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }

            guard let image = camera.capturedImage else {
                await MainActor.run {
                    phase = .error
                    errorMessage = "Could not capture photo. Try again."
                    showErrorAlert = true
                }
                return
            }

            let result = await ai.identify(image: image)

            await MainActor.run {
                // Show AI error as alert if something went wrong
                if let err = ai.lastError, !err.isEmpty {
                    errorMessage = err
                    showErrorAlert = true
                }
                identified = result
                phase = .confirmed
                showConfirm = true
            }
        }
    }
}

// MARK: - Corner brackets shape

struct CornerBrackets: View {
    let size: CGFloat
    private let len: CGFloat = 28
    private let thick: CGFloat = 4
    private let radius: CGFloat = 8

    var body: some View {
        ZStack {
            // Top-left
            bracket(angle: 0)
                .offset(x: -size / 2, y: -size / 2)
            // Top-right
            bracket(angle: 90)
                .offset(x: size / 2, y: -size / 2)
            // Bottom-right
            bracket(angle: 180)
                .offset(x: size / 2, y: size / 2)
            // Bottom-left
            bracket(angle: 270)
                .offset(x: -size / 2, y: size / 2)
        }
    }

    private func bracket(angle: Double) -> some View {
        BracketShape(len: len, thick: thick, radius: radius)
            .rotationEffect(.degrees(angle))
    }
}

struct BracketShape: Shape {
    let len: CGFloat
    let thick: CGFloat
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Horizontal arm
        p.move(to: CGPoint(x: 0, y: thick))
        p.addLine(to: CGPoint(x: len, y: thick))
        p.addLine(to: CGPoint(x: len, y: 0))
        p.addLine(to: CGPoint(x: thick, y: 0))
        // Corner
        p.addLine(to: CGPoint(x: thick, y: len))
        p.addLine(to: CGPoint(x: 0, y: len))
        p.closeSubpath()
        return p
    }
}
