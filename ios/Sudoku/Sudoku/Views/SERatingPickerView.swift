import SwiftUI

struct SERatingPickerView: View {
    let onSelect: (Float) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var selectedBand: SEBand?
    @State private var refinedSE: Float = 2.0

    private var bands: [SEBand] {
        Array(SEBand.allCases)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(bands, id: \.rawValue) { band in
                    bandRow(band)
                    if selectedBand == band {
                        bandSlider(band)
                    }
                }
            }
            .navigationTitle("SE Rating")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Generate") {
                        onSelect(refinedSE)
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedBand == nil)
                }
            }
        }
    }

    @ViewBuilder
    private func bandRow(_ band: SEBand) -> some View {
        Button {
            withAnimation {
                selectedBand = band
                refinedSE = band.defaultSE
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(band.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(band.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(String(format: "%.1f", band.defaultSE))
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)

                if selectedBand == band {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .fontWeight(.semibold)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func bandSlider(_ band: SEBand) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(String(format: "%.1f", band.range.lowerBound))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(
                    value: $refinedSE,
                    in: band.range,
                    step: 0.1
                )
                Text(String(format: "%.1f", band.range.upperBound))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Target: \(String(format: "%.1f", refinedSE))")
                .font(.subheadline.monospaced())
                .foregroundStyle(Color.accentColor)
        }
        .padding(.vertical, 4)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

// MARK: - SE Bands

enum SEBand: String, CaseIterable, Identifiable {
    case gentle
    case moderate
    case tricky
    case fiendish
    case diabolical
    case nightmare
    case beyond

    var id: String { rawValue }

    var name: String {
        switch self {
        case .gentle: return "Gentle"
        case .moderate: return "Moderate"
        case .tricky: return "Tricky"
        case .fiendish: return "Fiendish"
        case .diabolical: return "Diabolical"
        case .nightmare: return "Nightmare"
        case .beyond: return "Beyond"
        }
    }

    var description: String {
        switch self {
        case .gentle: return "Singles only"
        case .moderate: return "Pairs & triples"
        case .tricky: return "Wings & rectangles"
        case .fiendish: return "Quads & ALS"
        case .diabolical: return "Chains & AIC"
        case .nightmare: return "Forcing chains"
        case .beyond: return "Extreme techniques"
        }
    }

    var defaultSE: Float {
        switch self {
        case .gentle: return 2.0
        case .moderate: return 3.2
        case .tricky: return 4.4
        case .fiendish: return 5.4
        case .diabolical: return 6.5
        case .nightmare: return 8.0
        case .beyond: return 10.0
        }
    }

    var range: ClosedRange<Float> {
        switch self {
        case .gentle: return 1.5...2.5
        case .moderate: return 2.5...3.8
        case .tricky: return 3.8...5.0
        case .fiendish: return 5.0...6.0
        case .diabolical: return 6.0...7.5
        case .nightmare: return 7.5...9.5
        case .beyond: return 9.5...11.0
        }
    }
}

#Preview {
    SERatingPickerView { se in
        print("Selected SE: \(se)")
    }
}
