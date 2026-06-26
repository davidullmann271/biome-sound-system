# Current Looper State Machine

Short reference for the current TouchOSC looper logic in [root.lua](C:/Users/XMG/Documents/touchOSC%20intelligent%20controller%20for%20ableton/scripts/root.lua).

## Core Model

- No Ableton Looper device logic remains in the script.
- The controller drives 4 buffer variants: `1`, `2`, `4`, and `8` bars.
- One buffer length is active at a time.
- Track `1` uses its own bass scene selector.
- Tracks `2` and `3` share the main scene selector.

## MIDI Output

All looper/control messages below are sent on MIDI channel 6.

### Source / Scene / Clip

- `CC1` = source reset
- `X0` = main scene play
- `X4` = bass scene play
- `XY` = selected clip action

Where:

- `X = scene 1..8`
- `Y = track 1..3`

### Buffer Families

- `1 bar`:
  - `CC15` = rec
  - `CC16` = play
  - `CC17` = mute/unmute
- `2 bar`:
  - `CC25` = rec
  - `CC26` = play
  - `CC27` = mute/unmute
- `4 bar`:
  - `CC35` = rec
  - `CC36` = play
  - `CC37` = mute/unmute
- `8 bar`:
  - `CC45` = rec
  - `CC46` = play
  - `CC47` = mute/unmute

Buffer trigger values:

- `rec` and `play` are sent as momentary CCs: `127` then `0`
- `mute` = value `0`
- `unmute` = value `127`

## Controls

- Main scene buttons: `looper_scene_1..8`
- Bass scene buttons: `looper_bass_scene_1..8`
- Track buttons:
  - `looper_track_bass`
  - `looper_track_mid`
  - `looper_track_high`
- Mode buttons:
  - `looper_mode_play`
  - `looper_mode_freeze`
  - `looper_mode_store`
- Bar buttons:
  - `looper_bars_1`
  - `looper_bars_2`
  - `looper_bars_4`
  - `looper_bars_8`

## Selection Rules

- Scene selection is queued and adopted on scheduled state-machine boundaries.
- Mode selection is queued and adopted on scheduled state-machine boundaries.
- Track selection applies immediately.
- Bar-length selection applies immediately.
- Scene play launches are one-shot, not periodic:
  - they fire only when a scene selection becomes active
  - or after startup / idle reset when launch is pending

## Idle Rules

- While transport is stopped, mode is forced to `play`.
- While stopped, `freeze` and `store` cannot be selected.
- `store` is locked until playback is running.

## Timing Model

- Global counting is continuous.
- `modePhase` is modulo 16.
- So bars `1, 17, 33...` are phase `1`, and bars `9, 25, 41...` are phase `9`.

Selected buffer cadence:

- `1 bar`: every bar
- `2 bar`: `1, 3, 5...`
- `4 bar`: `1, 5, 9...`
- `8 bar`: `1, 9, 17...`

## Inactive Buffer Upkeep

- Every non-selected buffer still receives `rec + mute` upkeep.
- That upkeep fires on:
  - the inactive buffer's own cadence
  - the currently selected buffer cadence

This means shorter selected buffers also force resets into longer inactive buffers.

## Mode Behavior

### Play

At selected-buffer phase 1:

- send source reset
- send pending main scene play if needed
- send pending bass scene play if needed
- send current buffer `rec`
- send current buffer `mute`

### Freeze

At selected-buffer phase 1:

- send source reset
- send pending main scene play if needed
- send pending bass scene play if needed
- send current buffer `play`
- send current buffer `unmute`

### Store

If selected clip is free:

- phase 1:
  - send source reset
  - send pending scene play if needed
  - send selected clip action
  - send current buffer `play`
  - send current buffer `unmute`
- phase 2:
  - send selected clip action
  - send current buffer `rec`
  - send current buffer `mute`
  - mark clip occupied
  - switch to `freeze`

Store phase pairs by selected buffer length:

- `8 bar`: `1 -> 9`
- `4 bar`: `1 -> 5`
- `2 bar`: `1 -> 3`
- `1 bar`: `1 -> 2`

If selected clip is not free:

- no store is performed
- mode switches to `freeze`
- freeze behavior is triggered at that boundary

## Visuals

- Track buttons:
  - selected track uses full brightness
  - non-selected tracks are dimmed
  - selected track turns red in `store`
- Main scene buttons:
  - white when selected and free
  - red when selected and free in `store`
  - green when selected and occupied
  - darker green when free and not selected
  - gray when occupied and not selected
  - pulse when queued
- Bass scene buttons:
  - same state logic as scenes
  - warmer orange palette instead of green
  - pulse when queued
- Mode buttons:
  - selected mode uses full brightness
  - others are dimmed
  - queued mode pulses
- Bar buttons:
  - active = mellow yellow
  - inactive = darker gray-yellow
