import SwiftUI

struct GameView: View {
    @EnvironmentObject var gameManager: GameManager
    @ObservedObject var game: GameViewModel

    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > geometry.size.height {
                // Landscape layout
                HStack(spacing: 20) {
                    gridSection(size: min(geometry.size.height - 40, geometry.size.width * 0.55))
                    controlsSection(compact: true)
                }
                .padding()
            } else {
                // Portrait layout
                VStack(spacing: 16) {
                    headerSection
                    gridSection(size: min(geometry.size.width - 32, geometry.size.height * 0.55))
                    Spacer(minLength: 8)
                    numberPadSection
                    controlsSection(compact: false)
                }
                .padding()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            // Timer
            if gameManager.settings.timerVisible {
                Label(game.elapsedTimeString, systemImage: "clock")
                    .font(.headline.monospacedDigit())
            }

            Spacer()

            // Difficulty
            Text(game.difficulty.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            // Mistakes
            HStack(spacing: 4) {
                ForEach(0..<game.maxMistakes, id: \.self) { i in
                    Image(systemName: i < game.mistakes ? "heart.slash.fill" : "heart.fill")
                        .foregroundStyle(i < game.mistakes ? .red : .pink)
                }
            }
        }
    }

    // MARK: - Grid

    private func gridSection(size: CGFloat) -> some View {
        GridView(game: game, size: size)
            .frame(width: size, height: size)
    }

    // MARK: - Number Pad

    private var numberPadSection: some View {
        NumberPadView(game: game)
    }

    // MARK: - Controls

    private func controlsSection(compact: Bool) -> some View {
        VStack(spacing: compact ? 8 : 12) {
            if compact {
                // Landscape: vertical controls
                VStack(spacing: 8) {
                    controlButtons
                    modeToggle
                }
            } else {
                // Portrait: horizontal controls
                HStack(spacing: 16) {
                    controlButtons
                }
                modeToggle
            }
        }
    }

    private var controlButtons: some View {
        Group {
            Button {
                game.undo()
                hapticFeedback(.light)
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!game.canUndo)

            Button {
                game.redo()
                hapticFeedback(.light)
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!game.canRedo)

            Button {
                game.clearSelectedCell()
                hapticFeedback(.light)
            } label: {
                Image(systemName: "delete.left")
            }

            Button {
                game.getHint()
                hapticFeedback(.medium)
            } label: {
                Image(systemName: "lightbulb")
            }

            Button {
                gameManager.pauseGame()
            } label: {
                Image(systemName: "pause")
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
    }

    private var modeToggle: some View {
        Button {
            game.inputMode.toggle()
            hapticFeedback(.light)
        } label: {
            HStack {
                Image(systemName: game.inputMode == .normal ? "pencil" : "pencil.line")
                Text(game.inputMode.displayName)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(game.inputMode == .candidate ? .orange : nil)
    }

    // MARK: - Haptics

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard gameManager.settings.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

#Preview {
    GameView(game: GameViewModel(difficulty: .medium))
        .environmentObject(GameManager())
}
