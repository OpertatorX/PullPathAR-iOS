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
            drawText("PullPath AR — Pull Sheet", font: .boldSystemFont(ofSize: 22), height: 32)
            drawText(snapshot.projectName, font: .boldSystemFont(ofSize: 16), height: 24)
            drawText("Route: \(snapshot.routeName)", font: .systemFont(ofSize: 13))

            if !snapshot.clientName.isEmpty {
                drawText("Client: \(snapshot.clientName)", font: .systemFont(ofSize: 11))
            }
            if !snapshot.siteName.isEmpty {
                drawText("Site: \(snapshot.siteName)", font: .systemFont(ofSize: 11))
            }

            drawRule()
            drawText("Cable: \(snapshot.cableProfileName)", font: .systemFont(ofSize: 12))
            drawText("Status: \(snapshot.routeStatus)", font: .systemFont(ofSize: 12))
            drawText(
                "Measured: \(RouteMath.formattedLength(meters: snapshot.baseLengthMeters, unitSystem: unitSystem))",
                font: .systemFont(ofSize: 12)
            )
            drawText(
                "Slack: \(RouteMath.formattedLength(meters: snapshot.fixedSlackMeters, unitSystem: unitSystem)) + \(String(format: "%.1f", snapshot.slackPercent))%",
                font: .systemFont(ofSize: 12)
            )
            drawText(
                "Required: \(RouteMath.formattedLength(meters: snapshot.requiredLengthMeters, unitSystem: unitSystem))",
                font: .boldSystemFont(ofSize: 14),
                height: 28
            )

            if !snapshot.reelName.isEmpty {
                var reelLine = "Assigned reel: \(snapshot.reelName)"
                if let remaining = snapshot.reelRemainingMeters {
                    reelLine += " • Remaining after pull: \(RouteMath.formattedLength(meters: remaining, unitSystem: unitSystem))"
                }
                drawText(reelLine, font: .systemFont(ofSize: 12), height: 30)
            }

            drawRule()
            drawText("Segment ledger", font: .boldSystemFont(ofSize: 15), height: 28)

            if snapshot.segments.isEmpty {
                drawText("No measured segments.", font: .italicSystemFont(ofSize: 11), color: .secondaryLabel)
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
                drawText("Notes", font: .boldSystemFont(ofSize: 15), height: 28)
                let noteHeight = max(CGFloat(48), CGFloat(snapshot.notes.count / 70 + 1) * 18)
                drawText(snapshot.notes, font: .systemFont(ofSize: 11), height: noteHeight)
            }

            drawRule()
            let dateText = snapshot.generatedAt.formatted(date: .abbreviated, time: .shortened)
            drawText(
                "Generated \(dateText) • AR measurements are planning aids and can be manually verified or corrected.",
                font: .systemFont(ofSize: 8.5),
                color: .secondaryLabel,
                height: 32
            )
        }
    }
}
