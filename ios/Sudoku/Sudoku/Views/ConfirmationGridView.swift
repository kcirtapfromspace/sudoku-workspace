import SwiftUI

/// Editable 9x9 grid for reviewing and correcting OCR results.
struct ConfirmationGridView: View {
    @ObservedObject var viewModel: PuzzleConfirmationViewModel

    private let gridSpacing: CGFloat = 0
    private let thickBorder: CGFloat = 2
    private let thinBorder: CGFloat = 0.5

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let cellSize = (size - thickBorder * 4) / 9

            VStack(spacing: 0) {
                ForEach(0..<9, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<9, id: \.self) { col in
                            let index = row * 9 + col
                            cellView(index: index, size: cellSize)
                                .border(Color.secondary.opacity(0.3), width: thinBorder)
                        }
                    }
                    // Thick horizontal line after every 3rd row (except the last)
                    if row % 3 == 2 && row < 8 {
                        Rectangle()
                            .fill(Color.primary)
                            .frame(height: thickBorder)
                    }
                }
            }
            // Overlay thick vertical lines for 3x3 boxes
            .overlay {
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { boxCol in
                        let boxWidth = cellSize * 3 + thinBorder * 2
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: boxWidth)
                            .border(Color.primary, width: thickBorder)
                        if boxCol < 2 {
                            Spacer().frame(width: 0)
                        }
                    }
                }
            }
            .frame(width: cellSize * 9, height: cellSize * 9)
            .border(Color.primary, width: thickBorder)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1.0, contentMode: .fit)
    }

    @ViewBuilder
    private func cellView(index: Int, size: CGFloat) -> some View {
        let digit = viewModel.digits[index]
        let isSelected = viewModel.selectedCell == index
        let isLow = viewModel.isLowConfidence(at: index)

        ZStack {
            // Background
            Rectangle()
                .fill(cellBackground(isSelected: isSelected, isLow: isLow))

            // Digit
            if digit != 0 {
                Text("\(digit)")
                    .font(.system(size: size * 0.55, weight: .medium, design: .rounded))
                    .foregroundStyle(isLow ? .orange : .primary)
            }
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectCell(at: index)
        }
    }

    private func cellBackground(isSelected: Bool, isLow: Bool) -> Color {
        if isSelected {
            return Color.accentColor.opacity(0.2)
        } else if isLow {
            return Color.orange.opacity(0.1)
        } else {
            return Color.clear
        }
    }
}

/// Number pad for editing cells in the confirmation grid.
struct ConfirmationNumberPad: View {
    @ObservedObject var viewModel: PuzzleConfirmationViewModel

    var body: some View {
        HStack(spacing: 8) {
            // 0 = clear
            numberButton(0, label: "C")

            ForEach(1..<10, id: \.self) { digit in
                numberButton(digit, label: "\(digit)")
            }
        }
    }

    private func numberButton(_ digit: Int, label: String) -> some View {
        Button {
            if let selected = viewModel.selectedCell {
                viewModel.setDigit(digit, at: selected)
            }
        } label: {
            Text(label)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
        }
        .disabled(viewModel.selectedCell == nil)
    }
}
