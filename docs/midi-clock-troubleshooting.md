# MIDI Clock Troubleshooting

## Key Rule

MIDI clock itself should be 24 pulses per quarter-note beat. A MIDI interface should not normally decide to send a different musical clock resolution.

If `CLOCKS_PER_STEP = 24` is too fast, and values like `48` or `72` make it correct, the usual cause is not a different MIDI clock standard. It is usually duplicate clock streams.

Examples:

```text
24 = one real MIDI clock stream
48 = two copies of the same clock
72 = three copies of the same clock
36 = one-and-a-half effective copies, usually a routing/loop/merge problem
```

## Why This Fits The Observed Behavior

The clock value changed after moving between locations and interfaces:

- home setup: M-Audio 2X2M
- brother setup: TASCAM Model 12
- same computer and iPad
- different WiFi

WiFi can affect latency and jitter, but it should not multiply the number of MIDI clock messages by clean ratios. Clean ratios usually mean the script is counting multiple incoming sources.

## Resolved Test Incident

During Windows testing, TouchOSC showed approximately:

```text
240-248 clock messages per second
4 x SONGPOSITION
4 x START
4 x STOP
```

The messages appeared under one TouchOSC connection index and one endpoint label such as `<Bridge 1>`. Switching to `<Bridge 2>` produced the same result.

The clock returned to normal after:

1. Disabling `USB Send` in TouchOSC Bridge.
2. Restarting TouchOSC and TouchOSC Bridge.

The visible Bridge routing otherwise appeared unchanged. This does not prove whether USB Send alone or stale process/routing state was responsible, but it strongly rules out `CLOCKS_PER_STEP`, the audio interface's clock resolution, and the new event-button mapping as root causes.

Until a controlled reproduction identifies the exact mechanism, treat this as the known-good configuration:

```text
TouchOSC Bridge USB Send = Off
one intended Ableton Sync output
one intended TouchOSC receive route
CLOCKS_PER_STEP = 24
```

## Most Likely Causes

### 1. Ableton Is Sending Sync To More Than One Output

In Ableton `Settings > Tempo & MIDI`, check every Output row.

For this TouchOSC beat indicator, only the intended `Output: TouchOSC Bridge` should have `Sync` enabled.

Disable `Sync` for:

```text
M-Audio output
TASCAM output
other virtual MIDI ports
other loopback ports
```

unless they are intentionally driving other hardware.

### 2. TouchOSC Is Listening To More Than One MIDI Input

TouchOSC can have multiple MIDI connections enabled. If several receive ports are enabled, the root script may see clock from more than one route.

For the beat indicator test, use one receive path only:

```text
TouchOSC MIDI receive = TouchOSC Bridge only
```

Disable other TouchOSC MIDI receive ports while diagnosing.

### 3. MIDI Clock Is Being Echoed Back

Ableton or an interface can accidentally create a loop:

```text
Ableton -> interface -> TouchOSC/Ableton input -> Ableton output -> TouchOSC
```

Symptoms:

- clock count is too fast by a stable ratio
- changing interface changes the ratio
- changing routing/settings changes the needed `CLOCKS_PER_STEP`

### 4. Desktop TouchOSC And iPad TouchOSC Both Participate

TouchOSC Bridge is a virtual MIDI interface. If both desktop TouchOSC and iPad TouchOSC are connected/routed at the same time, it is possible to make confusing duplicated paths.

During diagnosis:

```text
Ableton Sync output -> TouchOSC Bridge -> iPad TouchOSC
```

Keep the route that simple until the count is correct.

### 5. Bridge USB Send Or Stale Routing State

If Bridge USB Send is enabled, it can introduce another MIDI path when USB MIDI is also available. Even when the TouchOSC endpoint list shows only one selected Bridge connection, the incoming stream may already have been merged or looped upstream.

For the current WiFi/Bridge setup:

```text
disable USB Send
restart TouchOSC
restart TouchOSC Bridge
retest before changing script constants
```

The endpoint names can differ by layer:

```text
TouchOSC receive UI: <Bridge 1>, <Bridge 2>, ...
Windows/Ableton MIDI port: TouchOSC Bridge
```

This naming difference is normal.

MPE input settings are unrelated to MIDI Clock, Start, Stop, and Song Position. Leave MPE off unless an actual MPE controller requires it.

## Quick Diagnostic

At a fixed Ableton tempo, count how many MIDI clock messages TouchOSC receives per second.

Expected:

```text
expected clocks per second = BPM * 24 / 60
```

Examples:

```text
120 BPM = 48 clocks/second
100 BPM = 40 clocks/second
90 BPM  = 36 clocks/second
```

If TouchOSC sees:

```text
144 clocks/second at 120 BPM
```

then it is receiving 3x clock, which explains why `CLOCKS_PER_STEP = 72` felt correct.

## Diagnostic Root Snippet

Temporarily add this near the top of `scripts/root.lua`:

```lua
local CLOCK_DEBUG = true
local clockDebugCount = 0
local clockDebugLast = nil
```

Then inside the MIDI clock branch, after `clocks = clocks + 1`, add:

```lua
if CLOCK_DEBUG then
  local now = getMillis() / 1000

  if not clockDebugLast then
    clockDebugLast = now
  end

  clockDebugCount = clockDebugCount + 1

  if now - clockDebugLast >= 1 then
    print('clock messages per second', clockDebugCount)
    clockDebugCount = 0
    clockDebugLast = now
  end
end
```

Do not leave this on during performance. Printing every second is fine for testing, but the final performance script should keep debug output off.

## Preferred Fix

Do not keep compensating with `CLOCKS_PER_STEP`.

Use `CLOCKS_PER_STEP = 24` for one rectangle per quarter-note beat, then fix routing until the diagnostic count matches the expected clock rate.

Only use `CLOCKS_PER_STEP = 48`, `72`, etc. as a temporary workaround when a show/session needs to work immediately.

## Next Verification

The resolved incident was tested with TouchOSC running on Windows. When testing the iPad over WiFi:

1. Keep Bridge USB Send off.
2. Start with only one Bridge connection and one Ableton Sync output.
3. Enable clock debug temporarily.
4. Verify the received rate using `BPM * 24 / 60`.
5. Confirm one `START` and one `STOP` per transport action.
