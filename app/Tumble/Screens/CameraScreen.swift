import SwiftUI
import SwiftData
import TumbleKit

/// The camera — a deliberately quiet, single-shutter viewfinder. No burst, no
/// zoom clutter. A soft grain sits over the live feed so even the preview feels
/// filmic. The roll counter is present but never nags.
struct CameraScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(AppModel.self) private var app
    @StateObject private var camera = CameraController()

    @Query(sort: \Photo.capturedAt, order: .reverse) private var photos: [Photo]

    @State private var showDrawer = false
    @State private var showPaywall = false
    @State private var showSettings = false
    @State private var flash = false
    @State private var tossing = false
    @State private var forceIslandCamera = false
    @State private var islandExpanded = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if shouldUseIslandCamera(in: geometry) {
                    islandCameraLayout(in: geometry)
                } else {
                    standardCameraLayout
                }

                // Shutter flash.
                Color.white.opacity(flash ? 0.85 : 0).ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
        .onAppear {
            camera.start()
            DebugSeed.run(in: context)
            app.startCameraActivity(capturedCount: photos.count)
            if ProcessInfo.processInfo.arguments.contains("-islandCam") { forceIslandCamera = true }
            if ProcessInfo.processInfo.arguments.contains("-drawer") { showDrawer = true }
            if ProcessInfo.processInfo.arguments.contains("-paywall") { showPaywall = true }
            if ProcessInfo.processInfo.arguments.contains("-settings") { showSettings = true }
        }
        .onDisappear { camera.stop() }
        .task { await app.startStore() }
        .fullScreenCover(isPresented: $showDrawer) {
            DrawerScreen().environment(app)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environment(app)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environment(app)
        }
    }

    private var standardCameraLayout: some View {
        ZStack {
            viewfinder
            GrainOverlay(opacity: 0.14)

            VStack {
                topBar
                Spacer()
                bottomBar
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }

    // MARK: Viewfinder

    @ViewBuilder private var viewfinder: some View {
        if camera.isSimulated {
            // No camera (Simulator): a filmic stand-in so the UI still reads.
            GraincoreBackground()
        } else {
            CameraPreview(session: camera.session).ignoresSafeArea()
        }
    }

    // MARK: Island camera

    private func shouldUseIslandCamera(in geometry: GeometryProxy) -> Bool {
        forceIslandCamera || geometry.safeAreaInsets.top >= 54
    }

    private func islandCameraLayout(in geometry: GeometryProxy) -> some View {
        let width = geometry.size.width
        let topInset = max(geometry.safeAreaInsets.top, 54)
        let previewWidth = min(width - 88, 260)
        let previewHeight = previewWidth * 0.82

        return ZStack {
            GraincoreBackground()
            GrainOverlay(opacity: 0.18)

            VStack(spacing: 0) {
                islandBezel(topInset: topInset, previewWidth: previewWidth, previewHeight: previewHeight)
                    .padding(.top, max(8, topInset - 50))

                Spacer(minLength: 24)

                if islandExpanded {
                    VStack(spacing: 18) {
                        Text(app.roll.remainingLabel)
                            .font(Typography.sans(13, weight: .semibold))
                            .foregroundStyle(Palette.cream)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(.black.opacity(0.28), in: Capsule())
                            .overlay(Capsule().strokeBorder(Palette.amber.opacity(0.22), lineWidth: 1))

                        islandControls
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, max(32, geometry.safeAreaInsets.bottom + 24))
                } else {
                    collapsedIslandControls
                        .transition(.opacity)
                        .padding(.bottom, max(32, geometry.safeAreaInsets.bottom + 24))
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func islandBezel(topInset: CGFloat, previewWidth: CGFloat, previewHeight: CGFloat) -> some View {
        let drag = DragGesture(minimumDistance: 10)
            .onEnded { value in
                if value.translation.height > 24 {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        islandExpanded = true
                    }
                } else if value.translation.height < -24 {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        islandExpanded = false
                    }
                }
            }

        return ZStack(alignment: .top) {
            if islandExpanded {
                expandedIslandBezel(previewWidth: previewWidth, previewHeight: previewHeight)
            } else {
                collapsedIslandPill(previewWidth: previewWidth)
            }
        }
        .frame(height: islandExpanded ? previewHeight + 66 : 56)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                islandExpanded.toggle()
            }
        }
        .gesture(drag)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(islandExpanded ? "Collapse island camera" : "Open island camera")
    }

    private func expandedIslandBezel(previewWidth: CGFloat, previewHeight: CGFloat) -> some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .fill(.black)
                .frame(width: previewWidth + 48, height: previewHeight + 66)
                .overlay(
                    RoundedRectangle(cornerRadius: 38, style: .continuous)
                        .strokeBorder(Palette.amber.opacity(0.34), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.35), radius: 18, y: 10)
                .shadow(color: Palette.amber.opacity(0.18), radius: 28, y: 12)

            islandCapsule(width: min(previewWidth + 6, 252))
                .padding(.top, 4)

            islandPreview
                .frame(width: previewWidth, height: previewHeight)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.top, 54)
        }
        .transition(.scale(scale: 0.72, anchor: .top).combined(with: .opacity))
    }

    private func collapsedIslandPill(previewWidth: CGFloat) -> some View {
        islandCapsule(width: min(previewWidth + 6, 252))
            .overlay(alignment: .leading) {
                Image(systemName: "camera.aperture")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.cream)
                    .padding(.leading, 18)
            }
            .overlay(alignment: .center) {
                Text(app.roll.remainingLabel)
                    .font(Typography.sans(12, weight: .semibold))
                    .foregroundStyle(Palette.cream.opacity(0.86))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.horizontal, 48)
            }
            .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
            .shadow(color: Palette.amber.opacity(0.18), radius: 20, y: 8)
            .transition(.scale(scale: 0.86, anchor: .top).combined(with: .opacity))
    }

    private func islandCapsule(width: CGFloat) -> some View {
        Capsule()
            .fill(.black)
            .frame(width: width, height: 46)
            .overlay(Capsule().strokeBorder(Palette.amber.opacity(0.24), lineWidth: 1))
            .overlay(alignment: .trailing) {
                Circle()
                    .fill(Palette.amber)
                    .frame(width: 9, height: 9)
                    .padding(.trailing, 44)
            }
    }

    @ViewBuilder private var islandPreview: some View {
        if camera.isSimulated {
            GraincoreBackground()
                .overlay(alignment: .center) {
                    VStack(spacing: 6) {
                        Image(systemName: "camera.aperture")
                            .font(.system(size: 26, weight: .semibold))
                        Text("Island cam")
                            .font(Typography.sans(12, weight: .bold))
                    }
                    .foregroundStyle(Palette.cream.opacity(0.86))
                }
        } else {
            CameraPreview(session: camera.session)
        }
    }

    private var islandControls: some View {
        HStack(spacing: 44) {
            Button { showDrawer = true } label: {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Palette.cream)
                    .frame(width: 56, height: 56)
                    .background(.black.opacity(0.24), in: Circle())
                    .overlay(Circle().strokeBorder(Palette.amber.opacity(0.35), lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open the Drawer")

            Button(action: capture) {
                Circle()
                    .fill(Palette.cream)
                    .frame(width: 78, height: 78)
                    .overlay(Circle().strokeBorder(Palette.amber.opacity(0.72), lineWidth: 4))
                    .shadow(color: Palette.amber.opacity(0.28), radius: 18, y: 8)
                    .scaleEffect(tossing ? 0.90 : 1)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Take a shot")
            .disabled(!app.roll.canShoot)
            .opacity(app.roll.canShoot ? 1 : 0.45)

            Button { showSettings = true } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(Palette.cream)
                    .frame(width: 56, height: 56)
                    .background(.black.opacity(0.24), in: Circle())
                    .overlay(Circle().strokeBorder(Palette.amber.opacity(0.35), lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }

    private var collapsedIslandControls: some View {
        HStack(spacing: 16) {
            Button { showDrawer = true } label: {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Palette.cream)
                    .frame(width: 48, height: 48)
                    .background(.black.opacity(0.20), in: Circle())
                    .overlay(Circle().strokeBorder(Palette.amber.opacity(0.28), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open the Drawer")

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    islandExpanded = true
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Palette.cream)
                    .frame(width: 48, height: 48)
                    .background(.black.opacity(0.24), in: Circle())
                    .overlay(Circle().strokeBorder(Palette.amber.opacity(0.35), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open island camera")

            Button { showSettings = true } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Palette.cream)
                    .frame(width: 48, height: 48)
                    .background(.black.opacity(0.20), in: Circle())
                    .overlay(Circle().strokeBorder(Palette.amber.opacity(0.28), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }

    // MARK: Bars

    private var topBar: some View {
        HStack {
            Text(app.roll.remainingLabel)
                .font(Typography.sans(13, weight: .semibold))
                .foregroundStyle(Palette.cream)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(.black.opacity(0.28), in: Capsule())
                .accessibilityLabel("\(app.roll.remainingLabel) in your roll")
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Palette.cream)
                    .padding(9).background(.black.opacity(0.28), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }

    @ViewBuilder private var bottomBar: some View {
        if app.roll.canShoot {
            HStack(alignment: .center) {
                drawerButton
                Spacer()
                shutter
                Spacer()
                Color.clear.frame(width: 56, height: 56) // balance the shutter
            }
        } else {
            emptyRoll
        }
    }

    private var shutter: some View {
        Button(action: capture) {
            ZStack {
                Circle().strokeBorder(Palette.cream.opacity(0.9), lineWidth: 4)
                    .frame(width: 74, height: 74)
                Circle().fill(Palette.cream)
                    .frame(width: 60, height: 60)
                    .scaleEffect(tossing ? 0.86 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Take a shot")
    }

    private var drawerButton: some View {
        Button { showDrawer = true } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Palette.printStock)
                    .frame(width: 44, height: 54)
                    .rotationEffect(.degrees(-8))
                    .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
                if !photos.isEmpty {
                    Text("\(photos.count)")
                        .font(Typography.sans(12, weight: .bold))
                        .foregroundStyle(Palette.ink)
                }
            }
            .frame(width: 56, height: 56)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open the Drawer")
    }

    private var emptyRoll: some View {
        VStack(spacing: 6) {
            Text("That's the roll for today.")
                .font(Typography.display(20))
                .foregroundStyle(Palette.cream)
            Text("Fresh twelve at sunrise.")
                .font(Typography.sans(14))
                .foregroundStyle(Palette.cream.opacity(0.7))
            HStack(spacing: 10) {
                Button { showDrawer = true } label: {
                    Text("Open the Drawer")
                        .font(Typography.sans(14, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal, 18).padding(.vertical, 9)
                        .background(Palette.amber, in: Capsule())
                }
                .buttonStyle(.plain)

                if app.purchases.entitlement != .unlimited {
                    Button { showPaywall = true } label: {
                        Text("Own more")
                            .font(Typography.sans(14, weight: .semibold))
                            .foregroundStyle(Palette.cream)
                            .padding(.horizontal, 18).padding(.vertical, 9)
                            .overlay(Capsule().strokeBorder(Palette.cream.opacity(0.4)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: Capture

    private func capture() {
        guard app.roll.canShoot else { return }
        let haptic = UIImpactFeedbackGenerator(style: .heavy)
        haptic.impactOccurred()

        camera.capture { image in
            withAnimation(.easeOut(duration: 0.08)) { flash = true }
            withAnimation(.easeIn(duration: 0.25).delay(0.08)) { flash = false }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { tossing = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { tossing = false }
            if app.store(rawImage: image, in: context) {
                app.markShotSaved(capturedCount: photos.count + 1)
            }
        }
    }
}
