# App Review Notes — PullPath AR 1.0.0 (1)

PullPath AR is a native SwiftUI field tool for cable installers. Its core workflow combines physical route capture, cable-length planning, reel inventory and job documentation in one route record.

## No account / no hidden access
- No sign-in or demo account is required.
- No subscription, in-app purchase, advertising or third-party analytics SDK is included.
- Project data is stored locally on the device.

## Recommended review path
1. Open **Projects** and create a project with a project name, site and optional client.
2. Open the project and create a cable route.
3. On the route screen, choose **Manual Measure**. Add at least two route points/segments and confirm the measured total changes.
4. Open **Edit Route** and change fixed slack and/or slack percentage. Confirm the required cable length updates.
5. Open **Settings → Cable Profiles** and create a cable profile.
6. Open **Reels** and create a reel with an available length.
7. Return to the route, assign the cable profile and reel. The route indicates whether the reel has enough remaining cable for measured length + slack.
8. Add a site photo if desired. Photos are selected locally and are not uploaded to an OperatorX server.
9. Export the **PDF pull sheet**. Export becomes available once the route contains at least two points.
10. Route status/history can be edited and reviewed from the route workflow.

## AR workflow
On a physical iPhone/iPad that supports ARKit world tracking, open a route and choose **AR Measure**. Move the device briefly so tracking initializes, then tap along visible surfaces to place route points. PullPath AR renders the points and connecting 3D segments, recalculates the route length, and derives a 3D route profile (horizontal travel, vertical travel, elevation range and direct endpoint distance). Undo and Clear are functional. The manual workflow remains available when AR is unavailable or unsuitable.

## Core differentiation
PullPath AR is not a generic calculator or project-management template. A single route connects: AR/manual physical path capture → editable 3D/route points → AR geometry profile → slack calculation → cable profile → reel-capacity assessment → site photos/history → PDF pull-sheet export. These functions share the same route data model and are designed for cable-pull preparation in the field.

## Permissions
- Camera: requested only for AR route measurement.
- Photo library: used when the reviewer chooses to attach a site photo or save/share an export.
- Tracking permission: not requested.

Support: https://operatorx-pullpath-ar.vercel.app/support
Privacy: https://operatorx-pullpath-ar.vercel.app/privacy
Terms: https://operatorx-pullpath-ar.vercel.app/terms
