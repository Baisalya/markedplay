# Video Player UI Improvements Implementation Plan

This plan addresses several UI and functional issues in the Video Player screen, including rotation logic, button placement, bottom sheet overflows, and missing subtitle/audio track options.

## Proposed Changes

### [Video Player Screen](file:///G:/markedplay/lib/Pages/videoplayer/Videoplayer.dart)

#### 1. Improve Button Placement (MX Player style)
- Reposition the rotation and feature buttons to be more "tucked" to the edges.
- Use `SafeArea` and `Padding` instead of just `Center` inside `Positioned` to ensure they are on the sides.
- Adjust button sizes and opacity to be less intrusive when controls are shown.

#### 2. Fix Rotation Logic
- Enhance `_toggleRotation` to handle different orientations more gracefully.
- Ensure the app returns to the previous orientation when exiting the player.

#### 3. Fix Bottom Sheet Overflow
- Wrap `_showModernBottomSheet` content in `SingleChildScrollView` where necessary.
- Adjust the layout of `_showModernBottomSheet` to be more responsive in landscape mode.
- Remove `Center` if it causes overflow issues on small screens.

#### 4. Enhance Subtitle and Audio Track Options
- Ensure `_showAudioTracks` and `_showSubtitleTracks` are easily accessible.
- Improve the track selection UI.
- Verify `media_kit` track retrieval.

---

## Phase-by-Phase Plan

### Phase 1: Layout & Button Positioning
- Reposition `_buildRotationButton` and `_buildExpandableFeatureButton`.
- Fix the `_showModernBottomSheet` overflow issue by making it more responsive.

### Phase 2: Rotation & Orientation
- Fix `_toggleRotation` to actually rotate the screen and update UI state.
- Ensure proper cleanup in `dispose`.

### Phase 3: Subtitles & Audio Tracks
- Populate the subtitle and audio track lists correctly.
- Add "None" option for subtitles.
- Improve the "More Settings" menu to include these options prominently.

---

## Verification Plan

### Manual Verification
- **Rotation**: Toggle rotation and verify the screen rotates. Test both landscape and portrait.
- **Button Placement**: Check if buttons are on the sides and don't overlap with other UI elements.
- **Bottom Sheet**: Open "Settings", "Audio Tracks", and "Subtitles" in both orientations and check for overflows.
- **Subtitles/Audio**: Test switching tracks and verify they change in the player.
- **Gesture Control**: Ensure brightness/volume/seek gestures still work after layout changes.
