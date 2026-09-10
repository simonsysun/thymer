# Unscheduled product ideas

These earlier ideas are preserved for discussion, not committed milestones. The
current public plan lives in the [README](../README.md#looking-ahead).

## After MVP

- [ ] **Confirm transitions** — optional setting, off by default. When a phase reaches its planned duration, offer a transition action; keep counting the current phase until the user confirms.
  - Work ends: **Take a break**, in the rest color (green).
  - Rest ends: **Back to work**, in the work color (blue).
  - Use only those action labels. No explanatory subtitles such as “Work time reached” or “Break time reached.”
  - Normal starts and resumes already show informational phase notices. This idea concerns explicit confirmation at phase boundaries, a separate behavior.
  - Before implementation, resolve interaction with automatic cycling and choose in-app versus system notification delivery.
  - **Explicitly excluded from MVP.** No implementation in the current prototype.

- [ ] **Camera presence sensing** — future, optional, privacy-first module. Use a small local human/body or face detector to help pause work tracking when the user leaves and resume when they return. **Excluded from MVP; idea and research only.**
  - Settings offers explicit download, enable/disable, and removal. The timer remains fully usable without the module. Request camera permission only when the user enables it; do not download or activate automatically.
  - Detect presence, not identity. Face recognition was suggested as a possibility, but identity templates, enrollment, and face embeddings are unnecessary for the current goal and are not planned.
  - Process frames locally in memory, discard them after inference, and never save/upload images, video, or face templates. Store only necessary timer intervals and transition reasons, not a continuous detection history.
  - Removal stops camera capture and unloads inference, then removes all app-owned module files, downloaded weights, compiled model caches, temporary downloads, and module-specific settings. Preserve ordinary time records. Verify removal across restart; do not claim to delete OS-owned frameworks or permissions.
  - Start evaluation with low-rate sampling (for example 1–2 inferences/second), a seated-user region, and a grace period to avoid flicker from brief head turns. These are trial parameters, not validated defaults. Camera capture itself may still consume significant power.
  - An automatic return must only resume a presence-triggered pause, never override manual pause. Rest should normally continue while the user is away; settle phase-transition and automatic-cycle behavior before implementation. Permission denial, camera failure, and uncertain detection must have an explicit fallback rather than silently losing time.
  - Presence is not proof of studying or sitting: test looking down at a book, side profiles, low light, empty chairs, other people, external cameras, camera contention, and sleep/wake. Compare missed/false presence, timing error, CPU, memory, battery, and total installed footprint on actual Macs before choosing a model.

### Camera research — September 7, 2026

Preliminary source review, not an integration or performance test. No camera access or model download performed.

| Candidate | Evidence and fit | Remaining work |
| --- | --- | --- |
| Apple Vision human / face detection | Native framework provides human rectangles and face detection. Apple documents on-device Vision processing. First candidate for native feasibility evaluation; no third-party model package is needed for these built-in requests. | Validate seated upper-body and face behavior on supported macOS versions. System components are not an independently removable download, so this is an alternative to the requested downloadable architecture, not an approved replacement. |
| YuNet via OpenCV | OpenCV Zoo provides face detection examples in C++ and Python. Its specific `face_detection_yunet_2023mar.onnx` file is listed as **227 KB**; the model directory is MIT licensed. A concrete candidate for optional downloadable weights. | This size excludes the inference runtime. Validate macOS/Swift bridging, pin compatible model/runtime versions, and measure full module size. No claim of tested Swift integration or Core ML conversion. |
| BlazeFace short-range | Google describes a lightweight webcam/selfie face detector with 128 × 128 float16 input model. | Official task guides list iOS, Android, Python, and Web, not a ready-made native macOS Swift integration. Evaluate runtime/porting cost and artifact redistribution terms before adoption. Published Pixel timings do not establish Mac performance. |

Sources:

- [Apple human detection](https://developer.apple.com/documentation/vision/detecthumanrectanglesrequest) and [Vision API catalog](https://developer.apple.com/documentation/vision).
- [Apple on-device Vision processing](https://developer.apple.com/documentation/vision/recognizing-text-in-images).
- [YuNet implementation and examples](https://github.com/opencv/opencv_zoo/tree/main/models/face_detection_yunet), [specific model size](https://github.com/opencv/opencv_zoo/blob/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx), and [model license](https://github.com/opencv/opencv_zoo/blob/main/models/face_detection_yunet/LICENSE).
- [Google Face Detector / BlazeFace guide](https://developers.google.com/edge/mediapipe/solutions/vision/face_detector).

Packaging decision remains open: downloading only weights does not remove a runtime bundled in the main app. If removal must include the entire optional runtime, package it separately and validate its loading, distribution, and cleanup on macOS. Clearly distinguish app-owned removable files from OS-managed components and camera permission, which the user controls in System Settings.
