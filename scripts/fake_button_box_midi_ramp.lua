-- fake button box -> fast continuous MIDI ramp
--
-- Put this on a Box or parent container that should behave like a button.
-- It sends a fast CC ramp from 0 to 127 while pressed.
--
-- Configure these:
local MIDI_CHANNEL = 6      -- 1..16
local MIDI_CC = 20          -- target CC number
local SEND_RELEASE_ZERO = true
local BURST_VALUES = { 0, 18, 42, 73, 104, 127 }
local PEAK_HOLD_TICKS = 2

local IDLE_COLOR = Color(0.56, 0.72, 0.88)
local TOUCH_COLOR = Color(1.00, 0.20, 0.20)

local pressed = false
local currentValue = 0
local lastSentValue = -1
local burstActive = false
local burstIndex = 1
local holdTicks = 0

local function midiStatusForChannel(channel)
  return 0xAF + channel
end

local function clamp(value)
  if value < 0 then
    return 0
  end

  if value > 127 then
    return 127
  end

  return value
end

local function sendCurrentValue()
  local value = clamp(math.floor(currentValue + 0.5))

  if value == lastSentValue then
    return
  end

  sendMIDI({ midiStatusForChannel(MIDI_CHANNEL), MIDI_CC, value })
  lastSentValue = value
end

local function sendValue(value)
  currentValue = clamp(value)
  lastSentValue = -1
  sendCurrentValue()
end

function init()
  self.interactive = true
  self.grabFocus = true
  self.visible = true
  self.background = true
  self.color = IDLE_COLOR
  pressed = false
  currentValue = 0
  lastSentValue = -1
  burstActive = false
  burstIndex = 1
  holdTicks = 0
end

function onPointer(pointers)
  if #pointers == 0 then
    return
  end

  local pointer = pointers[1]

  if pointer.state == PointerState.BEGIN then
    if burstActive then
      return
    end

    pressed = true
    self.color = TOUCH_COLOR
    burstActive = true
    burstIndex = 1
    holdTicks = 0
    return
  end

  if pointer.state == PointerState.END or pointer.state == PointerState.CANCEL then
    pressed = false
    self.color = IDLE_COLOR

    if SEND_RELEASE_ZERO and not burstActive then
      sendValue(0)
    end
  end
end

function update()
  if not burstActive then
    return
  end

  if burstIndex <= #BURST_VALUES then
    sendValue(BURST_VALUES[burstIndex])
    burstIndex = burstIndex + 1
    return
  end

  if holdTicks < PEAK_HOLD_TICKS then
    holdTicks = holdTicks + 1
    return
  end

  burstActive = false
  burstIndex = 1
  holdTicks = 0

  if SEND_RELEASE_ZERO then
    sendValue(0)
  end
end
