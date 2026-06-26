# TouchOSC Intelligent Controller for Ableton

Current workspace for a TouchOSC-driven Ableton Live controller centered around:

- transport and MIDI clock awareness
- scene / bass-scene launching
- clip store into 3 melodic tracks
- 4 selectable buffer lengths: `1`, `2`, `4`, `8` bars

The current scripted controller logic lives in [root.lua](C:/Users/XMG/Documents/touchOSC%20intelligent%20controller%20for%20ableton/scripts/root.lua).

## Current Structure

- [scripts/root.lua](C:/Users/XMG/Documents/touchOSC%20intelligent%20controller%20for%20ableton/scripts/root.lua)
  Root TouchOSC state machine.
- [scripts/transport_button.lua](C:/Users/XMG/Documents/touchOSC%20intelligent%20controller%20for%20ableton/scripts/transport_button.lua)
  Transport button notify script.
- [scripts/fake_button_box_midi_ramp.lua](C:/Users/XMG/Documents/touchOSC%20intelligent%20controller%20for%20ableton/scripts/fake_button_box_midi_ramp.lua)
  Scripted Box/container that behaves like a button but emits a fast continuous MIDI ramp.
- [scripts/looper](C:/Users/XMG/Documents/touchOSC%20intelligent%20controller%20for%20ableton/scripts/looper)
  Scene, bass scene, track, mode, and bar selector button scripts.
- [scripts/events/event_drop_kick.lua](C:/Users/XMG/Documents/touchOSC%20intelligent%20controller%20for%20ableton/scripts/events/event_drop_kick.lua)
  Example event button behavior.

## Current Docs

- [docs/current-looper-state-machine.md](C:/Users/XMG/Documents/touchOSC%20intelligent%20controller%20for%20ableton/docs/current-looper-state-machine.md)
  Current behavior reference for the looper / buffer state machine.
- [docs/control-map.md](C:/Users/XMG/Documents/touchOSC%20intelligent%20controller%20for%20ableton/docs/control-map.md)
  Current control names and MIDI output map.
- [docs/midi-clock-troubleshooting.md](C:/Users/XMG/Documents/touchOSC%20intelligent%20controller%20for%20ableton/docs/midi-clock-troubleshooting.md)
  Notes for diagnosing duplicate / unstable clock routing.
- [docs/europa-snapshot-device.md](C:/Users/XMG/Documents/touchOSC%20intelligent%20controller%20for%20ableton/docs/europa-snapshot-device.md)
  Separate notes for the Europa snapshot device workflow.

## Current Behavior Summary

- `play`, `freeze`, and `store` are the only active looper modes.
- The old Ableton Looper-device logic has been removed from script.
- Track `1` has an independent bass scene selector.
- Tracks `2` and `3` share the main scene selector.
- Track changes apply immediately.
- Bar-length changes apply immediately.
- Scene and mode changes are adopted by the running state machine at scheduled boundaries.
- Scene play triggers are one-shot launches, not continuous retriggers.
- While stopped, mode is forced back to `play`, and `freeze` / `store` are locked.

## Current Project Status

- The looper is currently buggy in real use.
- A `looper bugfixing` folder exists in the project workflow for bug investigation media and notes.
- After handover, the number one priority should be looper bug-fixing and stabilization before expanding functionality further.

## Buffer CC Families

All looper state-machine output uses MIDI channel 6.

- `1 bar`: rec `CC15`, play `CC16`, mute/unmute `CC17`
- `2 bar`: rec `CC25`, play `CC26`, mute/unmute `CC27`
- `4 bar`: rec `CC35`, play `CC36`, mute/unmute `CC37`
- `8 bar`: rec `CC45`, play `CC46`, mute/unmute `CC47`

Mute / unmute values:

- mute = `0`
- unmute = `127`

## Transport

Transport output uses MIDI channel 2:

- Start = `CC0`, value `127` then `0`
- Stop = `CC1`, value `127` then `0`
