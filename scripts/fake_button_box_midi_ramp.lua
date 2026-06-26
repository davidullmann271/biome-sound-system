-- fake button box -> fast continuous MIDI ramp
--
-- Put this on a Box or parent container that should behave like a button.
-- It sends a fast CC ramp from 0 to 127 while pressed.
--
-- Configure these:
local MIDI_CHANNEL = 6      -- 1..16
local MIDI_CC = 20          -- target CC number
local STEP = 16             -- bigger = faster ramp
local SEND_RELEASE_ZERO = true

local IDLE_COLOR = Color(0.56, 0.72, 0.88)
local TOUCH_COLOR = Color(1.00, 0.20, 0.20)

local pressed = false
local currentValue = 0
local lastSentValue = -1

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

function init()
  self.interactive = true
  self.grabFocus = true
  self.visible = true
  self.background = true
  self.color = IDLE_COLOR
  pressed = false
  currentValue = 0
  lastSentValue = -1
end

function onPointer(pointers)
  if #pointers == 0 then
    return
  end

  local pointer = pointers[1]

  if pointer.state == PointerState.BEGIN then
    pressed = true
    self.color = TOUCH_COLOR
    currentValue = 0
    lastSentValue = -1
    sendCurrentValue()
    return
  end

  if pointer.state == PointerState.END or pointer.state == PointerState.CANCEL then
    pressed = false
    self.color = IDLE_COLOR

    if SEND_RELEASE_ZERO then
      currentValue = 0
      lastSentValue = -1
      sendCurrentValue()
    end
  end
end

function update()
  if not pressed then
    return
  end

  if currentValue < 127 then
    currentValue = clamp(currentValue + STEP)
    sendCurrentValue()
  end
end
