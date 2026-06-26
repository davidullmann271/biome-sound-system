-- fake button / continuous sender
--
-- Use this on a fader-style control that exposes:
-- - touch
-- - x
--
-- From the user side it behaves like a momentary button:
-- - press  -> ramps x up to 1
-- - release -> ramps x back down to 0
--
-- From MIDI's side it behaves like a continuous controller move.

local PRESSED_VALUE = 1.0
local RELEASED_VALUE = 0.0
local RAMP_STEP = 0.18

local targetX = RELEASED_VALUE
local internalUpdate = false

local function clamp(value)
  if value < 0 then
    return 0
  end

  if value > 1 then
    return 1
  end

  return value
end

local function approach(current, target, step)
  if current < target then
    local nextValue = current + step

    if nextValue > target then
      return target
    end

    return nextValue
  end

  if current > target then
    local nextValue = current - step

    if nextValue < target then
      return target
    end

    return nextValue
  end

  return current
end

function init()
  self.values.x = RELEASED_VALUE
  targetX = RELEASED_VALUE
end

function onValueChanged(valueName)
  if internalUpdate then
    return true
  end

  if valueName == 'touch' then
    if self.values.touch == true then
      targetX = PRESSED_VALUE
    else
      targetX = RELEASED_VALUE
    end

    return true
  end

  if valueName == 'x' then
    -- Keep the control script in charge of x so native dragging does not fight the ramp.
    internalUpdate = true
    self.values.x = clamp(approach(self.values.x or RELEASED_VALUE, targetX, RAMP_STEP))
    internalUpdate = false
    return true
  end

  return true
end

function update()
  local currentX = self.values.x or RELEASED_VALUE
  local nextX = approach(currentX, targetX, RAMP_STEP)

  if nextX ~= currentX then
    internalUpdate = true
    self.values.x = clamp(nextX)
    internalUpdate = false
  end
end
