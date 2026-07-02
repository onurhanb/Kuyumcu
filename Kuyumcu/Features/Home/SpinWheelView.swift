import SwiftUI

struct SpinWheelView: View {
    private struct WheelSegment: Identifiable {
        let reward: GameState.WheelReward
        let shortLabel: String
        let index: Int
        let startAngle: Double
        let endAngle: Double
        let centerAngle: Double

        var id: Int { index }
    }

    @EnvironmentObject var gameState: GameState
    @Binding var isPresented: Bool

    @State private var wheelRotation: Double = 0
    @State private var isSpinning = false
    @State private var resultReward: GameState.WheelReward?
    @State private var errorMessage: String?

    private enum WheelStyle {
        case cash
        case rights
        case fx
        case gold
    }

    private let pointerAngle: Double = -90
    private var segmentCount: Double { Double(GameState.WheelReward.allCases.count) }
    private var segmentAngle: Double { 360 / segmentCount }
    private var wheelSegments: [WheelSegment] {
        GameState.WheelReward.allCases.enumerated().map { index, reward in
            let centerAngle = normalizedAngle(pointerAngle + (Double(index) * segmentAngle))
            let startAngle = normalizedAngle(centerAngle - (segmentAngle / 2))
            let endAngle = normalizedAngle(centerAngle + (segmentAngle / 2))
            return WheelSegment(
                reward: reward,
                shortLabel: reward.shortLabel,
                index: index,
                startAngle: startAngle,
                endAngle: endAngle,
                centerAngle: centerAngle
            )
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture {
                    if !isSpinning {
                        isPresented = false
                    }
                }

            VStack(spacing: GDLSpacing.lg) {
                header
                wheelSection
                statusSection
                GoldButton("Çevir", icon: "arrow.clockwise.circle.fill", style: .primary, isDisabled: isSpinning || !gameState.canSpinWheel) {
                    spinWheel()
                }
            }
            .padding(.horizontal, GDLSpacing.xl)
            .padding(.vertical, GDLSpacing.xl)
            .background(LinearGradient.gdlOuterSurface)
            .overlay(
                RoundedRectangle(cornerRadius: GDLRadius.shellOuterRadius)
                    .stroke(Color.gdlOuterSurfaceStroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: GDLRadius.shellOuterRadius))
            .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 8)
            .padding(.horizontal, 24)
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: GDLSpacing.xs) {
                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90.circle.fill")
                    .foregroundColor(.gdlGold)
                Text("Çark-ı Çevir")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.gdlTextPrimary)
            }
            Spacer()
            Button {
                if !isSpinning {
                    isPresented = false
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.gdlTextSecondary)
            }
            .buttonStyle(.plain)
            .disabled(isSpinning)
        }
    }

    private var wheelSection: some View {
        VStack(spacing: GDLSpacing.md) {
            TrianglePointer()
                .fill(pointerFill)
                .frame(width: 26, height: 18)
                .overlay(
                    TrianglePointer()
                        .stroke(Color.white.opacity(0.34), lineWidth: 0.9)
                )
                .shadow(color: Color.gdlGold.opacity(0.18), radius: 6, x: 0, y: 1)
                .shadow(color: .black.opacity(0.32), radius: 8, x: 0, y: 3)

            GeometryReader { proxy in
                let side = min(proxy.size.width, proxy.size.height)
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: side * 0.08,
                                endRadius: side * 0.48
                            )
                        )
                        .frame(width: side, height: side)

                    ForEach(wheelSegments) { segment in
                        WheelSegmentShape(
                            startAngle: .degrees(segment.startAngle),
                            endAngle: .degrees(segment.endAngle)
                        )
                        .fill(segmentFill(for: segment.reward))

                        WheelSegmentShape(
                            startAngle: .degrees(segment.startAngle),
                            endAngle: .degrees(segment.endAngle)
                        )
                        .fill(segmentHighlight)

                        WheelSegmentShape(
                            startAngle: .degrees(segment.startAngle),
                            endAngle: .degrees(segment.endAngle)
                        )
                        .stroke(segmentDividerColor, lineWidth: 0.8)

                        WheelSegmentShape(
                            startAngle: .degrees(segment.startAngle),
                            endAngle: .degrees(segment.endAngle)
                        )
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.35)

                        segmentLabel(for: segment, size: side)
                    }

                    Circle()
                        .stroke(AngularGradient.gdlChampagneRing, lineWidth: 3)

                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                        .padding(side * 0.02)

                    Circle()
                        .stroke(AngularGradient.gdlGoldRing, lineWidth: 2.2)
                        .frame(width: side * 0.24, height: side * 0.24)

                    Circle()
                        .fill(centerFill)
                        .frame(width: side * 0.24, height: side * 0.24)
                        .overlay(
                            Circle()
                                .stroke(AngularGradient.gdlChampagneRing, lineWidth: 1.2)
                        )

                    Circle()
                        .fill(LinearGradient.gdlGoldButton)
                        .frame(width: side * 0.08, height: side * 0.08)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.35), lineWidth: 0.6)
                        )
                }
                .frame(width: side, height: side)
                .rotationEffect(.degrees(wheelRotation))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity)
    }

    private var statusSection: some View {
        VStack(spacing: GDLSpacing.sm) {
            Text("Kalan Çevirme Hakkı: \(gameState.spinRightsRemaining)")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(gameState.spinRightsRemaining > 0 ? .gdlGold : .gdlTextSecondary)

            if let resultReward {
                Text("Tebrikler! Ödül: \(resultReward.displayTitle)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.gdlTextPrimary)
                    .multilineTextAlignment(.center)
            } else if !gameState.canSpinWheel {
                Text("Çark hakkın yok. Günlük ödülden hak kazanmalısın.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.gdlNegative)
                    .multilineTextAlignment(.center)
            } else if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.gdlNegative)
                    .multilineTextAlignment(.center)
            } else {
                Text("Hakkın varsa çarkı çevir, ödül anında hesabına işlenir.")
                    .font(.gdlCaption())
                    .foregroundColor(.gdlTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func spinWheel() {
        guard !isSpinning else { return }
        guard gameState.canSpinWheel else {
            resultReward = nil
            errorMessage = "Çark hakkın yok. Günlük ödülden hak kazanmalısın."
            return
        }

        let selectedReward = gameState.randomWheelReward()
        guard let selectedSegment = wheelSegments.first(where: { $0.reward == selectedReward }) else { return }

        errorMessage = nil
        resultReward = nil
        isSpinning = true

        let targetRotation = targetRotation(for: selectedSegment.index)

        withAnimation(.timingCurve(0.12, 0.88, 0.18, 1, duration: 4.2)) {
            wheelRotation = targetRotation
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.25) {
            wheelRotation = targetRotation
            let finalIndex = winningSegmentIndex(for: wheelRotation) ?? selectedSegment.index
            guard let finalSegment = wheelSegments.first(where: { $0.index == finalIndex }) else {
                isSpinning = false
                return
            }

            gameState.applyWheelReward(finalSegment.reward)
            resultReward = finalSegment.reward
            isSpinning = false
        }
    }

    private func targetRotation(for winningIndex: Int) -> Double {
        guard let segment = wheelSegments.first(where: { $0.index == winningIndex }) else {
            return wheelRotation + 2160
        }

        let normalizedRotation = normalizedAngle(wheelRotation)
        let desiredRotation = normalizedAngle(pointerAngle - segment.centerAngle)
        var delta = desiredRotation - normalizedRotation
        if delta < 0 {
            delta += 360
        }
        return wheelRotation + 2160 + delta
    }

    private var pointerFill: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.94),
                Color.gdlGoldLight,
                Color.gdlGold,
                Color(red: 0.73, green: 0.56, blue: 0.17)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var centerFill: RadialGradient {
        RadialGradient(
            colors: [
                Color(red: 0.20, green: 0.18, blue: 0.17),
                Color(red: 0.10, green: 0.10, blue: 0.12),
                Color.black.opacity(0.96)
            ],
            center: .center,
            startRadius: 2,
            endRadius: 44
        )
    }

    private var segmentDividerColor: Color {
        Color(red: 0.96, green: 0.87, blue: 0.58).opacity(0.68)
    }

    private var segmentHighlight: RadialGradient {
        RadialGradient(
            colors: [
                Color.white.opacity(0.20),
                Color.white.opacity(0.07),
                Color.clear
            ],
            center: .center,
            startRadius: 0,
            endRadius: 120
        )
    }

    private func wheelStyle(for reward: GameState.WheelReward) -> WheelStyle {
        switch reward.accentColorName {
        case "cash":
            return .cash
        case "rights":
            return .rights
        case "fx":
            return .fx
        default:
            return .gold
        }
    }

    private func segmentFill(for reward: GameState.WheelReward) -> AnyShapeStyle {
        switch wheelStyle(for: reward) {
        case .cash:
            return AnyShapeStyle(
                RadialGradient(
                    colors: [
                        Color(red: 1.00, green: 0.93, blue: 0.67),
                        Color(red: 0.90, green: 0.66, blue: 0.18),
                        Color(red: 0.68, green: 0.46, blue: 0.08)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 180
                )
            )
        case .rights:
            return AnyShapeStyle(
                RadialGradient(
                    colors: [
                        Color(red: 0.82, green: 0.96, blue: 0.84),
                        Color(red: 0.24, green: 0.63, blue: 0.42),
                        Color(red: 0.08, green: 0.33, blue: 0.24)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 180
                )
            )
        case .fx:
            return AnyShapeStyle(
                RadialGradient(
                    colors: [
                        Color(red: 0.84, green: 0.90, blue: 0.98),
                        Color(red: 0.28, green: 0.53, blue: 0.81),
                        Color(red: 0.12, green: 0.23, blue: 0.38)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 180
                )
            )
        case .gold:
            return AnyShapeStyle(
                RadialGradient(
                    colors: [
                        Color(red: 0.96, green: 0.82, blue: 0.58),
                        Color(red: 0.70, green: 0.49, blue: 0.20),
                        Color(red: 0.41, green: 0.27, blue: 0.11)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 180
                )
            )
        }
    }

    private func segmentLabel(for segment: WheelSegment, size: CGFloat) -> some View {
        let radius = size * 0.39
        let radians = segment.centerAngle * .pi / 180
        let x = cos(radians) * radius
        let y = sin(radians) * radius

        return Text(segment.shortLabel)
            .font(.system(size: size * 0.043, weight: .bold, design: .rounded))
            .foregroundColor(Color(red: 0.98, green: 0.94, blue: 0.84))
            .shadow(color: .black.opacity(0.28), radius: 1, x: 0, y: 1)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(width: size * 0.19)
            .rotationEffect(.degrees(segment.centerAngle + 90))
            .offset(x: x, y: y)
    }

    private func normalizedAngle(_ angle: Double) -> Double {
        let normalized = angle.truncatingRemainder(dividingBy: 360)
        return normalized >= 0 ? normalized : normalized + 360
    }

    private func winningSegmentIndex(for rotation: Double) -> Int? {
        let wheelAngleUnderPointer = normalizedAngle(pointerAngle - rotation)
        return wheelSegments.first(where: { contains(angle: wheelAngleUnderPointer, in: $0) })?.index
    }

    private func contains(angle: Double, in segment: WheelSegment) -> Bool {
        if segment.startAngle <= segment.endAngle {
            return angle >= segment.startAngle && angle < segment.endAngle
        }

        return angle >= segment.startAngle || angle < segment.endAngle
    }
}

private struct WheelSegmentShape: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}

private struct TrianglePointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
