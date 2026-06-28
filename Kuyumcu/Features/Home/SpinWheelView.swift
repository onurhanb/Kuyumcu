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
            .background(Color.gdlCard)
            .overlay(
                RoundedRectangle(cornerRadius: GDLRadius.xxl)
                    .stroke(Color.gdlStroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: GDLRadius.xxl))
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
                .fill(LinearGradient.gdlGoldButton)
                .frame(width: 26, height: 18)
                .overlay(
                    TrianglePointer()
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 2)

            GeometryReader { proxy in
                let side = min(proxy.size.width, proxy.size.height)
                ZStack {
                    ForEach(wheelSegments) { segment in
                        WheelSegmentShape(
                            startAngle: .degrees(segment.startAngle),
                            endAngle: .degrees(segment.endAngle)
                        )
                        .fill(segmentColor(for: segment.reward))

                        WheelSegmentShape(
                            startAngle: .degrees(segment.startAngle),
                            endAngle: .degrees(segment.endAngle)
                        )
                        .stroke(Color.gdlCard, lineWidth: 1)

                        segmentLabel(for: segment, size: side)
                    }

                    Circle()
                        .stroke(AngularGradient.gdlGoldRing, lineWidth: 2)

                    Circle()
                        .stroke(AngularGradient.gdlGoldRing, lineWidth: 2)
                        .frame(width: side * 0.24, height: side * 0.24)

                    Circle()
                        .fill(Color.gdlCard)
                        .frame(width: side * 0.24, height: side * 0.24)
                        .overlay(
                            Circle()
                                .stroke(Color.gdlStroke, lineWidth: 1)
                        )

                    Circle()
                        .fill(Color.gdlGold)
                        .frame(width: side * 0.08, height: side * 0.08)
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

    private func segmentColor(for reward: GameState.WheelReward) -> Color {
        switch reward.accentColorName {
        case "cash":
            return Color.gdlGold.opacity(0.9)
        case "rights":
            return Color.gdlPositive.opacity(0.9)
        case "fx":
            return Color(red: 0.23, green: 0.55, blue: 0.92)
        default:
            return Color(red: 0.86, green: 0.56, blue: 0.18)
        }
    }

    private func segmentLabel(for segment: WheelSegment, size: CGFloat) -> some View {
        let radius = size * 0.39
        let radians = segment.centerAngle * .pi / 180
        let x = cos(radians) * radius
        let y = sin(radians) * radius

        return Text(segment.shortLabel)
            .font(.system(size: size * 0.043, weight: .bold, design: .rounded))
            .foregroundColor(.black.opacity(0.82))
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
