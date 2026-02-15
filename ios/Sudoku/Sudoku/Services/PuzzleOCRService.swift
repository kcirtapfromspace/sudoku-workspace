import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

/// Per-cell OCR result with confidence score
struct CellOCRResult {
    let digit: Int  // 0 = empty, 1-9 = recognized digit
    let confidence: Float  // 0.0 - 1.0
}

/// Result from the full OCR pipeline
struct OCRResult {
    let cells: [CellOCRResult]  // 81 cells, row-major order
    let puzzleString: String    // 81-char string (digits 1-9, 0 for empty)
}

/// On-device OCR service for recognizing Sudoku puzzles from photos.
/// Uses Apple Vision framework for grid detection and text recognition.
final class PuzzleOCRService {

    /// Minimum confidence threshold to accept a digit recognition
    private static let confidenceThreshold: Float = 0.5

    /// Process a photo of a Sudoku puzzle and extract the digit grid.
    func recognizePuzzle(from image: UIImage) async throws -> OCRResult {
        guard let ciImage = CIImage(image: image) else {
            throw OCRError.invalidImage
        }

        // Step 1: Detect the grid rectangle
        let gridRect = try await detectGrid(in: ciImage)

        // Step 2: Perspective-correct to a square
        let corrected = try perspectiveCorrect(ciImage, to: gridRect)

        // Step 3: Extract 81 cell images
        let cellImages = extractCells(from: corrected)

        // Step 4: Recognize digit in each cell
        let cells = try await recognizeDigits(in: cellImages)

        // Step 5: Assemble puzzle string
        let puzzleString = cells.map { $0.digit == 0 ? "0" : "\($0.digit)" }.joined()

        return OCRResult(cells: cells, puzzleString: puzzleString)
    }

    // MARK: - Step 1: Grid Detection

    private func detectGrid(in image: CIImage) async throws -> VNRectangleObservation {
        let request = VNDetectRectanglesRequest()
        request.minimumAspectRatio = 0.7
        request.maximumAspectRatio = 1.3
        request.minimumSize = 0.3
        request.maximumObservations = 5
        request.minimumConfidence = 0.5

        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        try handler.perform([request])

        guard let results = request.results, !results.isEmpty else {
            throw OCRError.noGridFound
        }

        // Pick the largest rectangle by area
        let best = results.max(by: { area(of: $0) < area(of: $1) })!
        return best
    }

    private func area(of rect: VNRectangleObservation) -> CGFloat {
        let w = hypot(rect.topRight.x - rect.topLeft.x, rect.topRight.y - rect.topLeft.y)
        let h = hypot(rect.bottomLeft.x - rect.topLeft.x, rect.bottomLeft.y - rect.topLeft.y)
        return w * h
    }

    // MARK: - Step 2: Perspective Correction

    private func perspectiveCorrect(_ image: CIImage, to rect: VNRectangleObservation) throws -> CIImage {
        let imageSize = image.extent.size

        // Convert normalized Vision coordinates to image coordinates
        func toImagePoint(_ p: CGPoint) -> CGPoint {
            CGPoint(x: p.x * imageSize.width, y: p.y * imageSize.height)
        }

        let filter = CIFilter.perspectiveCorrection()
        filter.inputImage = image
        filter.topLeft = toImagePoint(rect.topLeft)
        filter.topRight = toImagePoint(rect.topRight)
        filter.bottomLeft = toImagePoint(rect.bottomLeft)
        filter.bottomRight = toImagePoint(rect.bottomRight)

        guard let output = filter.outputImage else {
            throw OCRError.perspectiveCorrectionFailed
        }

        return output
    }

    // MARK: - Step 3: Cell Extraction

    private func extractCells(from image: CIImage) -> [CIImage] {
        let size = image.extent.size
        let cellW = size.width / 9.0
        let cellH = size.height / 9.0

        // Inset cells slightly to avoid grid lines
        let insetFraction: CGFloat = 0.12

        var cells: [CIImage] = []
        cells.reserveCapacity(81)

        for row in 0..<9 {
            for col in 0..<9 {
                // CIImage origin is bottom-left; row 0 is the top of the puzzle
                let flippedRow = 8 - row
                let x = CGFloat(col) * cellW
                let y = CGFloat(flippedRow) * cellH

                let insetX = cellW * insetFraction
                let insetY = cellH * insetFraction
                let cellRect = CGRect(
                    x: x + insetX,
                    y: y + insetY,
                    width: cellW - 2 * insetX,
                    height: cellH - 2 * insetY
                )

                let cropped = image.cropped(to: cellRect)
                cells.append(cropped)
            }
        }

        return cells
    }

    // MARK: - Step 4: Digit Recognition

    private func recognizeDigits(in cellImages: [CIImage]) async throws -> [CellOCRResult] {
        var results: [CellOCRResult] = []
        results.reserveCapacity(81)

        for cellImage in cellImages {
            let result = try await recognizeSingleDigit(in: cellImage, level: .fast)

            // If fast recognition has low confidence, retry with accurate
            if result.confidence < Self.confidenceThreshold && result.digit != 0 {
                let accurate = try await recognizeSingleDigit(in: cellImage, level: .accurate)
                results.append(accurate)
            } else {
                results.append(result)
            }
        }

        return results
    }

    private func recognizeSingleDigit(in cellImage: CIImage, level: VNRequestTextRecognitionLevel) async throws -> CellOCRResult {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = level
        request.usesLanguageCorrection = false
        // Only recognize single digits
        request.customWords = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

        let handler = VNImageRequestHandler(ciImage: cellImage, options: [:])
        try handler.perform([request])

        guard let results = request.results, !results.isEmpty else {
            return CellOCRResult(digit: 0, confidence: 1.0) // Empty cell (high confidence)
        }

        // Get the top candidate
        let top = results[0]
        guard let candidate = top.topCandidates(1).first else {
            return CellOCRResult(digit: 0, confidence: 1.0)
        }

        let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)

        // Must be a single digit 1-9
        if text.count == 1, let digit = Int(text), (1...9).contains(digit) {
            return CellOCRResult(digit: digit, confidence: candidate.confidence)
        }

        // Not a valid digit — treat as empty
        return CellOCRResult(digit: 0, confidence: 0.8)
    }
}

// MARK: - Errors

enum OCRError: LocalizedError {
    case invalidImage
    case noGridFound
    case perspectiveCorrectionFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Could not process the image."
        case .noGridFound:
            return "No Sudoku grid found in the image. Make sure the entire grid is visible."
        case .perspectiveCorrectionFailed:
            return "Could not straighten the grid. Try taking the photo from directly above."
        }
    }
}
