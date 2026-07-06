import ActivityKit
import SwiftUI
import TumbleKit
import WidgetKit

struct TumbleIslandLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TumbleCameraActivityAttributes.self) { context in
            lockScreenView(context: context)
                .activityBackgroundTint(.black.opacity(0.82))
                .activitySystemActionForegroundColor(Palette.cream)
                .widgetURL(URL(string: "tumble://camera"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tumble")
                            .font(.caption.bold())
                        Text(context.state.remainingLabel)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: "camera.aperture")
                        .font(.title3)
                        .foregroundStyle(Palette.amber)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Label(context.state.status, systemImage: "circle.dashed")
                        Spacer()
                        Text("\(context.state.capturedCount) prints")
                    }
                    .font(.caption)
                }
            } compactLeading: {
                Image(systemName: "camera.aperture")
                    .foregroundStyle(Palette.amber)
            } compactTrailing: {
                Text(compactRemainingLabel(context.state.remainingLabel))
                    .font(.caption2.bold())
            } minimal: {
                Image(systemName: "camera.aperture")
                    .foregroundStyle(Palette.amber)
            }
            .widgetURL(URL(string: "tumble://camera"))
            .keylineTint(Palette.amber)
        }
    }

    private func lockScreenView(context: ActivityViewContext<TumbleCameraActivityAttributes>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "camera.aperture")
                .font(.title2)
                .foregroundStyle(Palette.amber)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(context.state.status)
                    .font(.headline)
                    .foregroundStyle(Palette.cream)
                Text(context.state.remainingLabel)
                    .font(.caption)
                    .foregroundStyle(Palette.cream.opacity(0.72))
            }

            Spacer()

            Text("\(context.state.capturedCount)")
                .font(.title3.bold())
                .foregroundStyle(Palette.cream)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }

    private func compactRemainingLabel(_ label: String) -> String {
        if label == "Unlimited" { return "∞" }
        return label.split(separator: " ").first.map(String.init) ?? label
    }
}

@main
struct TumbleIslandBundle: WidgetBundle {
    var body: some Widget {
        TumbleIslandLiveActivity()
    }
}
