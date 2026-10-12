# PullPath AR — Apple 4.2.6 / 4.3 Anti-Spam Audit

Date: 2026-10-12
Status: **PASS FOR BUILD — SUBMISSION REMAINS BLOCKED UNTIL REAL XCODE BUILD + DEVICE/SCREENSHOT QA**

## Apple risk being addressed
- 4.2.6: avoid a commercial-template / app-generation appearance.
- 4.3(a): avoid repackaged binaries, assets, metadata or multiple variants of the same product.
- 4.3(b): provide a meaningfully different experience from apps already widely available.

## Closest current App Store overlaps
### Cable Pull Ticket
Overlap: measured runs, slack allowance, reel assignment, shortages, status and crew pull ticket.
PullPath distinction: live ARKit physical-path capture, stored 3D route coordinates, 3D geometry profile, editable route points, site-photo documentation and PDF route record.

### StagePlot Cable Map
Overlap: waypoints, route length, slack and cable inventory fit.
PullPath distinction: StagePlot is a scaled top-down production/stage workspace; PullPath captures a real physical route in AR on site and derives 3D geometry from device-tracked points.

### Cabling Design Pro
Overlap: structured-cabling routes, floor-plan measurement, photos and job records.
PullPath distinction: PullPath does not measure from a 2D plan. It traces the physical installed/planned path in AR, including rises/drops, and connects that 3D path to slack and reel capacity.

### ReelMeter / partial reel calculators
Overlap: cable reel inventory/remaining cable.
PullPath distinction: reel inventory is subordinate to the measured route workflow; it is not the product's primary calculator.

## Product-specific architecture evidence
- Native Swift + SwiftUI + SwiftData.
- ARKit + RealityKit route capture with world-space 3D points and rendered segments.
- 3D geometry summary: horizontal travel, vertical travel, elevation range, direct endpoint distance.
- Manual measurement fallback stores compatible route points in the same model.
- Per-route cable profile + reel capacity assessment.
- Local site photos and route history.
- PDF pull-sheet generation from route segments and material data.
- Metric and imperial units.
- No account, ads, analytics SDK or cloud dependency.

## Factory similarity controls
- No UI copied from ResellCalc, Website Audit Pro, BLINK, NoteJob, OX Invoice, Event Booth or TrimBench.
- No shared product data model or navigation shell from those apps.
- Unique icon, bundle ID, metadata, support site and feature-specific terminology.
- Reusable infrastructure is limited to release/audit conventions, not customer-facing product UI or content.

## Submission gate
Do **not** submit if any of the following is missing:
1. Successful Xcode compile and unit tests on macOS.
2. Physical-device verification of AR placement, undo, clear and route persistence.
3. iPhone and iPad screenshots captured from the real build in FR and en-US.
4. App Privacy still matches the shipping binary.
5. Review Notes remain aligned with actual behavior.

Residual risk can never be reduced to zero because App Review is discretionary, but this product should not be submitted until all five gates above are green.
