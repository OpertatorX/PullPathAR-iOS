# PullPath AR — App Store Screenshot Capture Plan

Status: CAPTURE ONLY FROM THE REAL BUILT APP. Do not use mock UI as App Store screenshots.

## Required Apple sets (checked 2026-10-12)
- iPhone: Dynamic Island medium display. Preferred portrait capture: **1206 × 2622 px** (or another currently accepted medium-Dynamic-Island size such as 1179 × 2556).
- iPad: 13-inch display. Preferred portrait capture: **2064 × 2752 px** (2048 × 2732 also accepted for applicable 13-inch/12.9-inch source sets).
- Format: PNG/JPEG with no alpha.
- Localizations: **en-US + fr-FR**.

## Capture data set
Use a realistic but fictional structured-cabling job so every screen is populated:
- EN project: `North Wing Retrofit` / Site `Building A` / Client `Acme Offices`
- FR project: `Rénovation aile nord` / Site `Bâtiment A` / Client `Bureaux Acme`
- Route: `IDF-02 → Office 214`
- Cable profile: `Cat6A F/UTP`
- Reel: `R-07` with enough remaining cable to show a positive fit
- Route should contain multiple AR points with a visible rise/drop so the 3D profile is non-zero.
- Add one neutral site-reference photo only if it contains no personal/confidential information.

## Five screenshots — en-US
1. **Trace the real route** — AR capture with 3D points/segments and live measured length.
2. **See the 3D path** — Route detail showing required cable plus 3D route profile (horizontal travel, vertical travel, elevation range, endpoint distance).
3. **Know the reel fits** — Cable profile + assigned reel with positive capacity assessment.
4. **Document the pull** — Site photos + recent route activity/status.
5. **Export a field-ready pull sheet** — Real generated PDF visible in the system preview/share flow or a route screen immediately before export.

## Cinq captures — fr-FR
1. **Tracez le chemin réel** — Capture AR avec points/segments 3D et longueur mesurée.
2. **Visualisez le profil 3D** — Fiche tracé avec câble nécessaire + déplacement horizontal/vertical + amplitude d’altitude + distance directe.
3. **Vérifiez la bobine avant tirage** — Profil câble + bobine affectée avec capacité suffisante.
4. **Documentez le chantier** — Photos + historique/statut du tracé.
5. **Exportez la fiche de tirage** — PDF réellement généré ou écran juste avant l’export.

## QA before upload
- Capture from release-equivalent build, not SwiftUI Preview.
- No placeholder/demo/fake buttons.
- No developer overlays, debug labels, console, personal notifications or real customer data.
- All visible strings must match the selected App Store localization.
- iPhone and iPad layouts must be independently checked; do not stretch one device screenshot into the other ratio.
- AR screenshot must come from a physical supported device; simulator screenshot can be used for non-AR screens only after the build is validated.
- Ensure status bar/time/battery presentation is clean and consistent.
- Verify each final PNG has no alpha channel before upload.
