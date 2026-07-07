import SwiftUI
import SwiftData
import TumbleKit

/// The app's home. The whole screen is the **Drawer** - your pile of prints -
/// not a camera. The camera lives in the Dynamic Island / top handle: pull it
/// down to shoot, and the shot lands here.
struct HomeScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(AppModel.self) private var app
    @Query(sort: \Photo.capturedAt, order: .reverse) private var photos: [Photo]

    @State private var selected: Photo?
    @State private var selectedDay: PhotoDay?
    @State private var showPaywall = false
    @State private var nudgeDismissed = false
    @State private var nudgeDrag = CGSize.zero
    @State private var drawerCanReset = false
    @State private var drawerResetToken = 0

    /// Prompt to own more when the daily roll is running low.
    private let lowRollThreshold = 3

    private var developedCount: Int { photos.filter(\.isDeveloped).count }
    private var photoDays: [PhotoDay] { PhotoDay.group(photos) }
    private var today: PhotoDay? {
        photoDays.first { Calendar.current.isDate($0.dayStart, inSameDayAs: Date()) }
    }
    private var todayPhotos: [Photo] { today?.photos ?? [] }
    private var todayCount: Int { today?.totalCount ?? 0 }
    private var collectionDays: [PhotoDay] {
        Array(photoDays.filter { day in
            !Calendar.current.isDate(day.dayStart, inSameDayAs: Date())
        }.prefix(3))
    }
    private var remaining: Int? { app.roll.remaining }
    private var showsNudge: Bool {
        guard !app.roll.isUnlimited, let r = remaining else { return false }
        if r == 0 { return true }                       // empty roll: always informs
        return r <= lowRollThreshold && !nudgeDismissed  // low: dismissible
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                GraincoreBackground()

                // Home surface: today's Drawer gets the flexible space; older
                // daily collections stay as a small strip at the bottom.
                VStack(spacing: 14) {
                    header
                        .padding(.top, geo.safeAreaInsets.top + 46)
                        .padding(.horizontal, 20)

                    DrawerPile(
                        photos: todayPhotos,
                        previewLimit: 15,
                        emptyTitle: photos.isEmpty ? "Nothing in the drawer yet." : "No shots today yet.",
                        emptySubtitle: "Pull the camera down from the top, take a shot,\nthen shake it to develop.",
                        resetToken: drawerResetToken,
                        onResetAvailabilityChange: { drawerCanReset = $0 }
                    ) { selected = $0 }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 20)

                    dayBrowser
                        .padding(.horizontal, 20)
                        .padding(.bottom, geo.safeAreaInsets.bottom + (showsNudge ? 92 : 18))
                }

                // The camera handle (island on DI phones, floating handle elsewhere).
                IslandCamera(
                    screenWidth: geo.size.width,
                    topInset: geo.safeAreaInsets.top,
                    hasIsland: geo.safeAreaInsets.top >= 51,
                    onNeedMore: { showPaywall = true },
                    autoOpen: ProcessInfo.processInfo.arguments.contains("-island")
                )
                .environment(app)

                // Gentle "own more" nudge as the roll runs low.
                if showsNudge {
                    lowRollNudge
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding(.horizontal, 18)
                        .padding(.bottom, geo.safeAreaInsets.bottom + 18)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

            }
            .ignoresSafeArea()
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: showsNudge)
        .fullScreenCover(item: $selected) { photo in
            PrintStage(photo: photo, developed: photos.filter(\.isDeveloped))
        }
        .fullScreenCover(item: $selectedDay) { day in
            DayCollectionView(day: day)
        }
        .sheet(isPresented: $showPaywall) { PaywallView().environment(app) }
        .task { await app.startStore() }
        .task { await keepRollFresh() }
        .onChange(of: photos.count) { _, n in app.capturedCount = n }
        .onChange(of: remaining) { _, r in
            guard let r, r > lowRollThreshold else { return }
            nudgeDismissed = false
            nudgeDrag = .zero
        }
        .onAppear {
            app.roll.refresh()
            DebugSeed.run(in: context)
            app.capturedCount = photos.count
            if ProcessInfo.processInfo.arguments.contains("-develop") {
                selected = photos.first { !$0.isDeveloped }
            } else if ProcessInfo.processInfo.arguments.contains("-detail") {
                selected = photos.first { $0.isDeveloped }
            }
            if ProcessInfo.processInfo.arguments.contains("-paywall") { showPaywall = true }
            if ProcessInfo.processInfo.arguments.contains("-lowroll") {
                for _ in 0..<10 { app.roll.consumeShot() }
            }
            if ProcessInfo.processInfo.arguments.contains("-emptyroll") {
                for _ in 0..<12 { app.roll.consumeShot() }
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Drawer")
                    .font(Typography.display(26))
                    .foregroundStyle(Palette.cream)
                if !photos.isEmpty {
                    Text("\(todayCount) today · \(developedCount) developed · \(photos.count) total")
                        .font(Typography.sans(12))
                        .foregroundStyle(Palette.cream.opacity(0.55))
                }
            }
            Spacer()
            HStack(spacing: 10) {
                if drawerCanReset {
                    Button {
                        drawerResetToken += 1
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Palette.cream)
                            .frame(width: 35, height: 35)
                            .background(.black.opacity(0.28), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Reset drawer layout")
                    .transition(.scale(scale: 0.82).combined(with: .opacity))
                }

                Button { showPaywall = true } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Palette.cream)
                        .padding(9).background(.black.opacity(0.28), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Plans and about")
            }
        }
    }

    // MARK: Collections

    @ViewBuilder private var dayBrowser: some View {
        if !collectionDays.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Collections")
                        .font(Typography.display(22))
                        .foregroundStyle(Palette.cream)
                    Spacer()
                    Text(collectionDays.count == 1 ? "1 day" : "\(collectionDays.count) days")
                        .font(Typography.sans(12, weight: .semibold))
                        .foregroundStyle(Palette.cream.opacity(0.5))
                }

                VStack(spacing: 10) {
                    ForEach(collectionDays) { day in
                        Button { selectedDay = day } label: {
                            DayCollectionRow(day: day)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Low-roll nudge

    private var lowRollNudge: some View {
        let isEmpty = (remaining ?? 0) == 0
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(isEmpty ? "That's your twelve for today." : app.roll.remainingShotsSentence)
                    .font(Typography.sans(14, weight: .semibold))
                    .foregroundStyle(Palette.cream)
                Text(isEmpty ? "Fresh roll at sunrise, or pay once for more shots." : "Pay once to unlock more shots every day.")
                    .font(Typography.sans(12))
                    .foregroundStyle(Palette.cream.opacity(0.65))
            }
            Spacer(minLength: 8)
            Button { showPaywall = true } label: {
                Text("Pay once")
                    .font(Typography.sans(13, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Palette.gold, in: Capsule())
            }
            .buttonStyle(.plain)
            if !isEmpty {
                Button { dismissNudge() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Palette.cream.opacity(0.6))
                        .padding(6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss")
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Palette.charcoalDeep.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Palette.amber.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
        .offset(x: isEmpty ? 0 : nudgeDrag.width, y: isEmpty ? 0 : max(0, nudgeDrag.height))
        .gesture(
            DragGesture(minimumDistance: 12)
                .onChanged { value in
                    guard !isEmpty else { return }
                    nudgeDrag = CGSize(
                        width: value.translation.width,
                        height: max(0, value.translation.height)
                    )
                }
                .onEnded { value in
                    guard !isEmpty else { return }
                    if abs(value.translation.width) > 80 || value.translation.height > 60 {
                        dismissNudge()
                    } else {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            nudgeDrag = .zero
                        }
                    }
                }
        )
    }

    private func dismissNudge() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            nudgeDrag = .zero
            nudgeDismissed = true
        }
    }

    @MainActor
    private func keepRollFresh() async {
        while !Task.isCancelled {
            app.roll.refresh()
            let nextMidnight = Calendar.current.nextDate(
                after: Date(),
                matching: DateComponents(hour: 0, minute: 0, second: 1),
                matchingPolicy: .nextTime
            ) ?? Date().addingTimeInterval(60 * 60)
            let seconds = max(5, min(60 * 60, nextMidnight.timeIntervalSinceNow))
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        }
    }

    // MARK: Coachmark
}

private struct DayCollectionRow: View {
    let day: PhotoDay

    private var printCount: String {
        day.totalCount == 1 ? "1 print" : "\(day.totalCount) prints"
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Palette.gold.opacity(0.18))
                Image(systemName: "folder")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Palette.gold)
            }
            .frame(width: 50, height: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text(day.displayTitle)
                    .font(Typography.sans(15, weight: .semibold))
                    .foregroundStyle(Palette.cream)
                Text("\(day.developedCount) ready · \(printCount)")
                    .font(Typography.sans(12))
                    .foregroundStyle(Palette.cream.opacity(0.55))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.cream.opacity(0.35))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Palette.charcoalDeep.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Palette.cream.opacity(0.08), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}
