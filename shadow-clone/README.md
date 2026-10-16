# Shadow Clone

A lightweight Godot 4.x 2D puzzle-platformer prototype with a dark-fantasy palette. The forest background uses the imported layered Free Pixel Art Forest artwork, while the moon, fog, warrior, stonework, switches, and doors use lightweight Godot 2D drawing. No plugins or external runtime dependencies are required. The project uses the Compatibility renderer.

The prototype uses a fixed 1280 x 720 room and does not currently have a camera-follow system.

## Run

1. Open `project.godot` with Godot 4.x Standard.
2. Press **F6** to run the current scene or **F5** to run the project.
3. Select **BẮT ĐẦU**. Move with **A/D** or the arrow keys, jump with **Space**, press **R** to start/stop recording (up to eight seconds), **E** to create/replay the saved echo, and **Q** to remove the echo. The HUD shows recording time and state; touch controls are available on screen. A new recording replaces the saved sequence only when a non-empty capture completes. An empty capture keeps the previous sequence; failure/respawn clears it because the saved path is relative to its recording start.
4. The player and echo can both activate the pressure plate. Record an approach to the plate, then replay it with **E**; while the echo holds the plate, move the player across the gap and reach the open door. The echo stops after one replay and remains where its final action leaves it.
5. Restart with **CHƠI LẠI**. Falling into the gap or touching the spikes triggers checkpoint respawn.

The far side of the gap has a rune checkpoint followed by a clearly visible, jumpable spike trap. Falling into the pit or touching the spikes briefly disables control, removes the old echo, resets the switch/door puzzle, and respawns at the latest checkpoint (or the start if none was activated). The recording is cleared on respawn because it is relative to the previous start position. Reach the open exit sensor to display the existing victory panel; the result panel offers replay or return to the menu.

Touch buttons are available on-screen for Android; they can also be used while testing on PC.

The background uses the licensed layered **Free Pixel Art Forest** artwork under `assets/art/backgrounds/Free Pixel Art Forest/PNG/Background layers/`, with parallax from distant forest to foreground. The provided moonlit sky and drifting fog remain procedural because the asset pack has no moon, mountain, ruin, or fog artwork. Two flat blue sky layers from the pack are intentionally not used; the procedural night sky is retained instead. Horizontal mirroring is configured for the parallax artwork; the current fixed-room scene has no Camera2D, so parallax does not scroll during normal play.

See [ASSET_CREDITS.md](./ASSET_CREDITS.md) for the artwork attribution and usage terms.

The player and echo are assembled from original lightweight Godot 2D polygon/line nodes; there is no imported character sprite sheet or frame-based animation. Idle breathing, run cycle, rising jump, falling, landing response, and a recording glow are procedural pose animations. The echo reuses those poses and retains its cyan light, trail, spawn/dissolve effects, and pressure-plate emphasis. For a sprite-based art pass, add a transparent sprite sheet with a consistent frame size and matching idle/run/jump/fall/land poses; no character image is currently used.

Light2D textures are generated once and shared; echo trails, landing rings, and door/switch glows are visual-only. This single-room prototype has no camera-follow system, custom shaders, or particle emitters.

The start, pause, and result panels are centered and scale down to stay inside smaller window and mobile viewports.

The checked-in/pre-existing `ShadowClone.exe` and `ShadowClone.apk` are not rebuilt by source edits. Run the project with **F5** to see these changes, then export fresh builds when ready. Godot 4.7.2 headless import, startup, and gameplay smoke tests were run for the current source; window resizing, visual presentation on a GPU, and Android device/export behavior have not been verified.

## Android export

After the PC prototype runs:

1. In Godot, install the matching **Export Templates** from **Editor > Manage Export Templates**.
2. Install/configure Android SDK and JDK from **Editor > Editor Settings > Export > Android**. Keep any existing Android Studio setup unchanged; point Godot to the already installed tools.
3. Open **Project > Export**, add an **Android** preset, then configure package name, version, screen orientation, and signing. For local device testing, use a debug build.
4. Choose **Export Project**, save an `.apk`, and install it on a connected Android device. Enable developer options/USB debugging as required by the device.

The Android SDK/JDK paths and export preset are machine-specific and are intentionally not committed in the project.
