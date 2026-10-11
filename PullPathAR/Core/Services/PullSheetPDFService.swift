import Foundation
import UIKit

struct PullSheetSegment: Sendable, Equatable {
    let index: Int
    let fromLabel: String
    let toLabel: String
    let lengthMeters: Double
}

struct PullSheetSnapshot: Sendable, Equatable {
    let projectName: String
    let clientName: String
    let siteName: String
    let routeName: String
    let cableProfileName: String
    let routeStatus: String
    let baseLengthMeters: Double
    let fixedSlackMeters: Double
    let slackPercent: Double
    let requiredLengthMeters: Double
    let reelName: String
    let reelRemainingMeters: Double?
    let notes: String
    let segments: [PullSheetSegment]
    let generatedAt: Date
}

@MainActor
enum PullSheetPDFService {
    static func render(snapshot: PullSheetSnapshot, unitSystem: UnitSystem) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let margin: CGFloat = 44
        let usableWidth = pageRect.width - (margin * 2)
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        return renderer.pdfData { context in
            var y: CGFloat = margin

            func startPage() {
                context.beginPage()
                y = margin
            }

            func ensureSpace(_ height: CGFloat) {
                if y + height > pageRect.height - margin {
                    startPage()
                }
            }

            func drawText(
                _ text: String,
                font: UIFont,
                color: UIColor = .label,
                height: CGFloat = 24
            ) {
                ensureSpace(height)
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineBreakMode = .byWordWrapping
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraph
                ]
                let rect = CGRect(x: margin, y: y, width: usableWidth, height: height)
                (text as NSString).draw(in: rect, withAttributes: attributes)
                y += height
            }

            func drawRule() {
                ensureSpace(14)
                context.cgContext.setStrokeColor(UIColor.separator.cgColor)
                context.cgContext.setLineWidth(0.7)
                context.cgContext.move(to: CGPoint(x: margin, y: y + 5))
                context.cgContext.addLine(to: CGPoint(x: pageRect.width - margin, y: y + 5))
                context.cgContext.strokePath()
                y += 14
            }

            startPage()
            drawText(String(localized: "pdf.title"), font: .boldSystemFont(ofSize: 22), height: 32)
            drawText(snapshot.projectName, font: .boldSystemFont(ofSize: 16), height: 24)
            drawText("\(String(localized: "pdf.route")): \(snapshot.routeName)", font: .systemFont(ofSize: 13))

            if !snapshot.clientName.isEmpty {
                drawText("\(String(localized: "pdf.client")): \(snapshot.clientName)", font: .systemFont(ofSize: 11))
            }
            if !snapshot.siteName.isEmpty {
                drawText("\(String(localized: "pdf.site")): \(snapshot.siteName)", font: .systemFont(ofSize: 11))
            }

            drawRule()
            drawText("\(String(localized: "pdf.cable")): \(snapshot.cableProfileName)", font: .systemFont(ofSize: 12))
            drawText("\(String(localized: "pdf.status")): \(snapshot.routeStatus)", font: .systemFont(ofSize: 12))
            drawText(
                "\(String(localized: "pdf.measured")): \(RouteMath.formattedLength(meters: snapshot.baseLengthMeters, unitSystem: unitSystem))",
                font: .systemFont(ofSize: 12)
            )
            drawText(
                "\(String(localized: "pdf.slack")): \(RouteMath.formattedLength(meters: snapshot.fixedSlackMeters, unitSystem: unitSystem)) + \(String(format: "%.1f", snapshot.slackPercent))%",
                font: .systemFont(ofSize: 12)
            )
            drawText(
                "\(String(localized: "pdf.required")): \(RouteMath.formattedLength(meters: snapshot.requiredLengthMeters, unitSystem: unitSystem))",
                font: .boldSystemFont(ofSize: 14),
                height: 28
            )

            if !snapshot.reelName.isEmpty {
                var reelLine = "\(String(localized: "pdf.assignedReel")): \(snapshot.reelName)"
                if let remaining = snapshot.reelRemainingMeters {
                    reelLine += " • \(String(localized: "pdf.remainingAfterPull")): \(RouteMath.formattedLength(meters: remaining, unitSystem: unitSystem))"
                }
                drawText(reelLine, font: .systemFont(ofSize: 12), height: 30)
            }

            drawRule()
            drawText(String(localized: "pdf.segmentLedger"), font: .boldSystemFont(ofSize: 15), height: 28)

            if snapshot.segments.isEmpty {
                drawText(String(localized: "pdf.noSegments"), font: .italicSystemFont(ofSize: 11), color: .secondaryLabel)
            } else {
                for segment in snapshot.segments {
                    let from = segment.fromLabel.isEmpty ? "P\(segment.index)" : segment.fromLabel
                    let to = segment.toLabel.isEmpty ? "P\(segment.index + 1)" : segment.toLabel
                    let length = RouteMath.formattedLength(meters: segment.lengthMeters, unitSystem: unitSystem)
                    drawText("\(segment.index). \(from) → \(to)    \(length)", font: .monospacedSystemFont(ofSize: 10.5, weight: .regular))
                }
            }

            if !snapshot.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                drawRule()
                drawText(String(localized: "pdf.notes"), font: .boldSystemFont(ofSize: 15), height: 28)
                let noteHeight = max(CGFloat(48), CGFloat(snapshot.notes.count / 70 + 1) * 18)
                drawText(snapshot.notes, font: .systemFont(ofSize: 11), height: noteHeight)
            }

            drawRule()
            let dateText = snapshot.generatedAt.formatted(date: .abbreviated, time: .shortened)
            drawText(
                "\(String(localized: "pdf.generated")) \(dateText) • \(String(localized: "pdf.disclaimer"))",
                font: .systemFont(ofSize: 8.5),
                color: .secondaryLabel,
                height: 32
            )
        }
    }
}
