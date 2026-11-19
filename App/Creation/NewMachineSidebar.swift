import SwiftUI
import VMCore

/// The sidebar of the New Virtual Machine window: the systems to try first, and under them the ways to
/// make a machine that the window had before, in second place.
struct NewMachineSidebar: View {
    @Binding var selection: NewMachineSource

    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 2) {
                row(.discover, title: String(localized: "Discover"), subtitle: String(localized: "Systems to try"),
                    color: Theme.brand) {
                    Image(systemName: "sparkles")
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .surface()

            VStack(alignment: .leading, spacing: 2) {
                Text("Create Another Way")
                    .font(.system(size: 11, weight: .semibold))
                    .textCase(.uppercase)
                    .tracking(0.4)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 10)
                    .padding(.top, 6)
                    .padding(.bottom, 4)
                row(.system(.linux), title: "Linux", subtitle: String(localized: "Quick Create"), color: .orange) {
                    Text(verbatim: "L").font(.system(size: 12, weight: .bold))
                }
                row(.system(.macOS), title: "macOS", subtitle: String(localized: "Latest macOS"), color: Color(white: 0.45)) {
                    Image(systemName: "applelogo")
                }
                row(.system(.windows), title: "Windows 11", subtitle: String(localized: "For Arm"), color: .blue) {
                    Text(verbatim: "W").font(.system(size: 12, weight: .bold))
                }
                row(.template, title: String(localized: "Template"), subtitle: String(localized: "From a template"), color: .green) {
                    Image(systemName: "square.stack.3d.up")
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .surface()

            Spacer(minLength: 0)
            dropZone
        }
    }

    private func row<Icon: View>(
        _ source: NewMachineSource, title: String, subtitle: String, color: Color, @ViewBuilder icon: () -> Icon
    ) -> some View {
        Button {
            selection = source
        } label: {
            HStack(spacing: 10) {
                icon()
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(color))
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: title)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                    Text(verbatim: subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(selection == source ? Theme.fill2 : Color.clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selection == source ? .isSelected : [])
    }

    private var dropZone: some View {
        VStack(spacing: 2) {
            Text("Drop an Image")
                .font(.system(size: 13, weight: .semibold))
            Text("Drop an ISO or IPSW file here to make a machine from it.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .overlay {
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(Theme.fill2, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
        }
    }
}
