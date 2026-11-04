//
//  OptionCard.swift
//  FluentIsh
//
//  The chunky selectable row from onboarding: white card, 2pt border with
//  a 4pt bottom edge, orange border and a filled check when selected.
//  Radio (pick one) or checkbox (pick many). Settings reuses it in step 16.
//

import SwiftUI

struct OptionCard<Leading: View>: View {
    enum Indicator { case radio, checkbox }

    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    var indicator: Indicator = .radio
    var isEnabled = true
    /// Small label in place of the indicator, e.g. "SOON" for a disabled language.
    var badge: String? = nil
    /// Unselected checkbox rows fade a little (the prototype's games step).
    var dimWhenUnselected = false
    @ViewBuilder var leading: () -> Leading
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 12) {
                leading()
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.jakarta(15, 800))
                        .foregroundStyle(Color.ink)
                    if let subtitle {
                        Text(subtitle)
                            .font(.jakarta(11, 700))
                            .foregroundStyle(Color.inkMuted)
                    }
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                if let badge {
                    Text(badge)
                        .font(.jakarta(10, 800))
                        .tracking(0.8)
                        .foregroundStyle(Color.inkMuted)
                } else {
                    indicatorView
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background { cardShape }
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(!isEnabled ? 0.45 : (dimWhenUnselected && !isSelected ? 0.7 : 1))
        .scaleEffect(isSelected ? 1.01 : 1)
        .shadow(color: isSelected ? Color.flame.opacity(0.18) : .clear, radius: 6, y: 3)
        .animation(.spring(duration: 0.25), value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// The border is a filled shape with the card inset on top of it: 2pt on
    /// the sides and top, 4pt at the bottom, like the tactile buttons.
    private var cardShape: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isSelected ? Color.flame : Color.ink.opacity(0.13))
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.optionCard)
                .padding(EdgeInsets(top: 2, leading: 2, bottom: 4, trailing: 2))
        }
    }

    private var indicatorView: some View {
        // A 24pt square with 12pt corners is a circle (radio); 6pt is a checkbox.
        let shape = RoundedRectangle(cornerRadius: indicator == .radio ? 12 : 6, style: .continuous)
        return ZStack {
            shape.fill(isSelected ? Color.flame : Color.clear)
            shape.strokeBorder(isSelected ? Color.flame : Color.ink.opacity(0.25), lineWidth: 2)
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 24, height: 24)
    }
}

/// The square tile behind an option's icon (cream, or translucent in dark mode).
struct IconTile: View {
    let systemName: String
    let color: Color
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(Color.iconTile, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

extension Color {
    /// Option card fill: white, or the slightly lifted indigo in dark mode.
    static let optionCard = Color(light: 0xFFFFFF, dark: 0x221E52)
    static let iconTile = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor.white.withAlphaComponent(0.1) : UIColor(hex: 0xFFF8EC) })
}
