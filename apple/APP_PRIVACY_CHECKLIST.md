# App Privacy — PullPath AR 1.0.0 (1)

## App Store Connect answer
**Data Not Collected**

This answer is correct only while the production build remains aligned with the current source: no advertising SDK, no third-party analytics SDK, no account backend and no OperatorX server receiving project data.

## On-device data
The following information is created and stored locally for app functionality and is not transmitted to OperatorX:
- project, site and optional client names;
- cable routes, route points and measurements;
- slack settings, cable profiles and reel inventory;
- route status, notes and local history;
- selected site-photo references / local documentation;
- unit preferences.

## Camera / ARKit
The camera is used for AR route measurement. Camera and motion data is processed by Apple ARKit on device. PullPath AR stores route coordinates created by the user; it does not upload the camera stream.

## Photos
Photo access is user initiated for route documentation. Selected content remains local unless the user explicitly exports or shares it using iOS/iPadOS system UI.

## Export
PDF pull sheets are generated locally. A file leaves the app only when the user explicitly chooses a share/save destination.

## Tracking
- ATT prompt: **No**
- Cross-app tracking: **No**
- Advertising: **No**
- Third-party analytics: **No**

## Re-check before submission
If any network SDK, analytics, crash-reporting service, cloud sync or account backend is added later, this checklist must be reassessed before submission.
