// OCRService.swift
// ReceiptSnap — Vision framework OCR implementation.
//
// Flow:
//   1. Caller provides UIImage (camera or gallery).
//   2. VisionOCRService runs VNRecognizeTextRequest on a background thread.
//   3. Returns OCRResult with extracted merchant, amount, and date strings.
//   4. ViewModel populates the Add/Edit Receipt form fields.

import Foundation
import UIKit
import Vision

// MARK: - Result model

struct OCRResult {
    var merchantName: String?   // first non-numeric line, usually the merchant
    var amount:       Double?   // largest currency value found
    var date:         Date?     // first parseable date found
    var rawText:      String    // full recognised text (for debugging / manual review)
}

// MARK: - Protocol

protocol OCRServiceProtocol: AnyObject {
    /// Recognise text in `image` and return structured OCRResult.
    func recognise(image: UIImage) async throws -> OCRResult
}

// MARK: - Vision implementation

final class VisionOCRService: OCRServiceProtocol {

    func recognise(image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw ServiceError.ocrFailed
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { req, error in
                if let error {
                    continuation.resume(throwing: ServiceError.ocrFailed)
                    return
                }
                let observations = req.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap {
                    $0.topCandidates(1).first?.string
                }
                let result = Self.parse(lines: lines)
                continuation.resume(returning: result)
            }
            request.recognitionLevel   = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: ServiceError.ocrFailed)
            }
        }
    }

    // MARK: - Pure parsing logic (fully unit-testable)

    /// Extract structured data from an array of text lines.
    static func parse(lines: [String]) -> OCRResult {
        let raw = lines.joined(separator: "\n")

        // Merchant: first non-empty, non-numeric-only, non-date-looking line
        let merchantLine = lines.first {
            !$0.trimmingCharacters(in: .whitespaces).isEmpty &&
            $0.range(of: #"^\d+[\d\s\.\,\$]*$"#, options: .regularExpression) == nil &&
            $0.count > 2
        }

        // Amount: largest currency value in text
        let amount = largestCurrencyValue(in: raw)

        // Date: first parseable date
        let date = firstDate(in: lines)

        return OCRResult(merchantName: merchantLine, amount: amount, date: date, rawText: raw)
    }

    // MARK: - Currency extraction

    /// Extracts the receipt total by first searching for TOTAL/SUBTOTAL labelled lines,
    /// then falling back to the largest standalone currency value.
    static func largestCurrencyValue(in text: String) -> Double? {
        let lines = text.components(separatedBy: "\n")

        // Priority 1: look for a line that contains a total-related keyword
        let totalKeywords = ["grand total", "total amount", "amount due", "amount total",
                             "subtotal", "sub total", "total"]
        for keyword in totalKeywords {
            for line in lines {
                let lower = line.lowercased()
                if lower.contains(keyword) {
                    if let val = extractFirstAmount(from: line), val > 0 { return val }
                }
            }
        }

        // Priority 2: largest currency value preceded by $ £ €
        let symbolPattern = #"[\$£€]\s*(\d{1,6}[,\.]?\d{0,2})"#
        if let regex = try? NSRegularExpression(pattern: symbolPattern),
           let val = extractLargest(regex: regex, from: text) { return val }

        // Priority 3: largest standalone decimal value (e.g. bare "12.50")
        let barePattern = #"\b(\d{1,5}\.\d{2})\b"#
        if let regex = try? NSRegularExpression(pattern: barePattern),
           let val = extractLargest(regex: regex, from: text) { return val }

        return nil
    }

    private static func extractFirstAmount(from line: String) -> Double? {
        // Pull the first decimal number from a line
        let pattern = #"(\d{1,6}[,\.]?\d{0,2})"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(line.startIndex..., in: line)
        return regex.matches(in: line, range: range).compactMap { m -> Double? in
            guard let r = Range(m.range(at: 1), in: line) else { return nil }
            let raw = line[r].replacingOccurrences(of: ",", with: "")
            return Double(raw)
        }.first
    }

    private static func extractLargest(regex: NSRegularExpression, from text: String) -> Double? {
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { m -> Double? in
            let idx = m.numberOfRanges > 1 ? 1 : 0
            guard let r = Range(m.range(at: idx), in: text) else { return nil }
            let raw = text[r].replacingOccurrences(of: ",", with: "")
                              .replacingOccurrences(of: "$", with: "")
                              .replacingOccurrences(of: "£", with: "")
                              .replacingOccurrences(of: "€", with: "")
                              .trimmingCharacters(in: .whitespaces)
            return Double(raw)
        }.max()
    }

    // MARK: - Date extraction

    static func firstDate(in lines: [String]) -> Date? {
        let formats = [
            "MM/dd/yyyy", "dd/MM/yyyy", "yyyy-MM-dd",
            "MMM dd, yyyy", "dd MMM yyyy", "MM-dd-yyyy"
        ]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        for line in lines {
            for fmt in formats {
                formatter.dateFormat = fmt
                if let date = formatter.date(from: line.trimmingCharacters(in: .whitespaces)) {
                    return date
                }
                // Try extracting sub-string matching the pattern
                if let extracted = extractDateSubstring(from: line, format: fmt, formatter: formatter) {
                    return extracted
                }
            }
        }
        return nil
    }

    private static func extractDateSubstring(from line: String, format: String,
                                              formatter: DateFormatter) -> Date? {
        // Try 10–16 char substrings at each position
        let chars = Array(line)
        for start in 0..<chars.count {
            for length in [8, 9, 10, 11, 12] {
                let end = start + length
                guard end <= chars.count else { break }
                let sub = String(chars[start..<end])
                if let date = formatter.date(from: sub) { return date }
            }
        }
        return nil
    }
}
