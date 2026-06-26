# Europa Snapshot Device

This is a Max for Live helper for the one-Europa workflow:

- one existing Europa instance
- snapshot the exposed parameter values after you load a Europa patch
- recall those values later without touching Europa's patch browser

Files:

- `max/Europa Snapshot.maxpat`
- `max/europa_snapshot.js`

Keep those two files together. The patch depends on the JavaScript file at runtime.

## What It Does

The device looks at another device on the same Ableton track, reads its exposed parameters through the Live API, and stores those values in an embedded `dict`.

The default target is the **previous device on the track**, so the intended placement is:

1. `Europa`
2. `Europa Snapshot`

If you place the snapshot device somewhere else on the same track, set the target device index manually.

## Basic Use

1. Open `max/Europa Snapshot.maxpat` in Max.
2. Do not move `europa_snapshot.js` away from the patch.
3. Save it from Max as a **Max Audio Effect** `.amxd`.
4. If you save out an `.amxd`, keep the `.amxd` and `europa_snapshot.js` in the same folder, or add that folder to Max's file search path.
5. If Live says it cannot find `europa_snapshot.js`, the device has loaded but the script has not. Fix the file location first before testing anything else.
6. Place the device on the same Ableton track as Europa, ideally directly after Europa.
7. Let the device initialize, or click `rescan`.
8. Set the `slot` number you want.
9. Type a snapshot name if you want something better than the default auto-name.
10. Load a Europa preset manually one time.
11. Press the momentary `Capture` button.
12. Change Europa to another sound and press `Capture` again on another slot.
13. Press `Recall` on any stored slot to push the saved values back into Europa.
14. Use `Prev` / `Next` to step through slots and recall them immediately.

## Notes

- This does **not** load native Europa patch files.
- It stores only what Live exposes as parameters for that device.
- If a Europa patch depends on internal state that is not exposed as parameters, that part cannot be reconstructed by this device.
- Status is mirrored both in-device and to the Max Console through `print europa_snapshot`.
- Recall reports parameter-name mismatches in the device so you can spot cases where the live parameter layout differs from what was captured.
- The patch now includes `plugin~` -> `plugout~` audio pass-through, so it should not silence Europa when used as an audio effect after the instrument.

## Included Now

- momentary `live.button` action buttons instead of latching text toggles
- snapshot name storage per slot
- previous/next slot recall
- in-device mismatch/status display

## Still Worth Adding Later

- direct MIDI input handling inside the device so controller notes/CCs can trigger slots without Live MIDI mapping
- export/import of captured snapshot libraries
- A/B morphing between two stored states
