# Control Map

## Root / Scripted Controls

- Root script: [root.lua](C:/Users/XMG/Documents/touchOSC%20intelligent%20controller%20for%20ableton/scripts/root.lua)
- Transport button script: [transport_button.lua](C:/Users/XMG/Documents/touchOSC%20intelligent%20controller%20for%20ableton/scripts/transport_button.lua)
- Fake continuous button script: [fake_button_box_midi_ramp.lua](C:/Users/XMG/Documents/touchOSC%20intelligent%20controller%20for%20ableton/scripts/fake_button_box_midi_ramp.lua)
- Event button script: [event_drop_kick.lua](C:/Users/XMG/Documents/touchOSC%20intelligent%20controller%20for%20ableton/scripts/events/event_drop_kick.lua)
- Looper button scripts:
  - [scene_button.lua](C:/Users/XMG/Documents/touchOSC%20intelligent%20controller%20for%20ableton/scripts/looper/scene_button.lua)
  - [bass_scene_button.lua](C:/Users/XMG/Documents/touchOSC%20intelligent%20controller%20for%20ableton/scripts/looper/bass_scene_button.lua)
  - [track_button.lua](C:/Users/XMG/Documents/touchOSC%20intelligent%20controller%20for%20ableton/scripts/looper/track_button.lua)
  - [mode_button.lua](C:/Users/XMG/Documents/touchOSC%20intelligent%20controller%20for%20ableton/scripts/looper/mode_button.lua)
  - [bars_button.lua](C:/Users/XMG/Documents/touchOSC%20intelligent%20controller%20for%20ableton/scripts/looper/bars_button.lua)

## Beat Edge Boxes

All are TouchOSC Box controls:

```text
beat_ul
beat_ur
beat_rt
beat_rb
beat_br
beat_bl
beat_lb
beat_lt
```

Suggested placement:

```text
beat_ul = top edge, left half
beat_ur = top edge, right half
beat_rt = right edge, upper half
beat_rb = right edge, lower half
beat_br = bottom edge, right half
beat_bl = bottom edge, left half
beat_lb = left edge, lower half
beat_lt = left edge, upper half
```

## Transport

```text
transport_btn = Button, Press / Momentary
```

The button should not send its own MIDI directly. Its script notifies root.

Outgoing transport MIDI on channel 2:

```text
Start = CC 0, value 127 then 0
Stop  = CC 1, value 127 then 0
```

## Event Button

```text
event_drop_kick = Button, Press / Momentary
```

Current scripted target values:

```text
perc_groove    x=0, y=0
perc_density   x=0, y=0
perc_structure x=0, y=0
drums_density  x=0, y=0.5
drums_high     x=0, y=0
```

## Looper UI Controls

Main scene selector:

```text
looper_scene_1
looper_scene_2
looper_scene_3
looper_scene_4
looper_scene_5
looper_scene_6
looper_scene_7
looper_scene_8
```

Bass scene selector:

```text
looper_bass_scene_1
looper_bass_scene_2
looper_bass_scene_3
looper_bass_scene_4
looper_bass_scene_5
looper_bass_scene_6
looper_bass_scene_7
looper_bass_scene_8
```

Track selector:

```text
looper_track_bass
looper_track_mid
looper_track_high
```

Mode selector:

```text
looper_mode_play
looper_mode_freeze
looper_mode_store
```

Bar selector:

```text
looper_bars_1
looper_bars_2
looper_bars_4
looper_bars_8
```

## MIDI Map Summary

All looper state-machine output below is on channel 6.

```text
CC1  = source reset
X0   = main scene play
X4   = bass scene play
XY   = selected clip action
```

Buffer families:

```text
1 bar: rec CC15, play CC16, mute/unmute CC17
2 bar: rec CC25, play CC26, mute/unmute CC27
4 bar: rec CC35, play CC36, mute/unmute CC37
8 bar: rec CC45, play CC46, mute/unmute CC47
```

Mute / unmute values:

```text
mute   = value 0
unmute = value 127
```
