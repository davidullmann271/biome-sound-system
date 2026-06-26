-- version 21 root
-- transport + beat ring + looper state machine

local DEBUG = false
local CLOCK_DEBUG = false

local CLOCKS_PER_BEAT = 24
local BEATS_PER_BAR = 4
local CLOCKS_PER_BAR = CLOCKS_PER_BEAT * BEATS_PER_BAR
local EARLY_TRIGGER_CLOCKS = 1

local beatNames = {
  'beat_ul',
  'beat_ur',
  'beat_rt',
  'beat_rb',
  'beat_br',
  'beat_bl',
  'beat_lb',
  'beat_lt'
}

local displayBarNames = {
  'display_bar_1',
  'display_bar_2',
  'display_bar_3',
  'display_bar_4',
  'display_bar_5',
  'display_bar_6',
  'display_bar_7',
  'display_bar_8'
}

local sceneNames = {
  'looper_scene_1',
  'looper_scene_2',
  'looper_scene_3',
  'looper_scene_4',
  'looper_scene_5',
  'looper_scene_6',
  'looper_scene_7',
  'looper_scene_8'
}

local bassSceneNames = {
  'looper_bass_scene_1',
  'looper_bass_scene_2',
  'looper_bass_scene_3',
  'looper_bass_scene_4',
  'looper_bass_scene_5',
  'looper_bass_scene_6',
  'looper_bass_scene_7',
  'looper_bass_scene_8'
}

local trackDefinitions = {
  { name = 'looper_track_bass', index = 1, color = { 0.52, 1.00, 0.52 } },
  { name = 'looper_track_mid', index = 2, color = { 0.34, 0.54, 1.00 } },
  { name = 'looper_track_high', index = 3, color = { 0.82, 0.28, 1.00 } }
}

local modeDefinitions = {
  { name = 'looper_mode_play', mode = 'play', color = { 0.40, 0.96, 0.40 } },
  { name = 'looper_mode_freeze', mode = 'freeze', color = { 0.20, 0.92, 1.00 } },
  { name = 'looper_mode_store', mode = 'store', color = { 1.00, 0.24, 0.24 } }
}

local barLengthDefinitions = {
  { name = 'looper_bars_1', bars = 1, rec_cc = 15, play_cc = 16, mute_cc = 17 },
  { name = 'looper_bars_2', bars = 2, rec_cc = 25, play_cc = 26, mute_cc = 27 },
  { name = 'looper_bars_4', bars = 4, rec_cc = 35, play_cc = 36, mute_cc = 37 },
  { name = 'looper_bars_8', bars = 8, rec_cc = 45, play_cc = 46, mute_cc = 47 }
}

local lights = {}
local displayBars = {}
local transportButton = nil
local sceneButtons = {}
local bassSceneButtons = {}
local trackButtons = {}
local modeButtons = {}
local barButtons = {}
local trackNameToIndex = {}
local modeNameToValue = {}
local barNameToLength = {}

local step = 1
local beatClocks = 0
local barClocks = 0
local clockDebugCount = 0
local clockDebugLast = nil
local running = false
local isPlaying = false

local idlePhase = 0
local idleSpeed = 0.035
local lastUpdateSeconds = nil

local mode = 'play'
local mode_current = 'play'
local scene_index = 1
local scene_index_current = 1
local bass_scene_index = 1
local bass_scene_index_current = 1
local track_index = 1
local track_index_current = 1
local main_scene_track_index = 2
local selected_bar_length = 8
local selected_bar_length_current = 8
local store_phase = 1
local modePhase = 1 -- bar position inside the 16-bar looper cycle
local selected_clip_free = {}
local main_scene_launch_pending = true
local bass_scene_launch_pending = true

local black = Color(0, 0, 0)
local white = Color(1, 1, 1)
local green = Color(0, 1, 0)
local red = Color(1, 0, 0)
local barYellow = Color(1.0, 0.9, 0.45)

local dayNightStops = {
  { 0.4000, 0.5882, 0.7294 },
  { 0.4000, 0.5882, 0.7294 },
  { 0.4000, 0.5882, 0.7294 },
  { 0.4000, 0.5882, 0.7294 },
  { 0.8863, 0.8902, 0.5451 },
  { 0.9059, 0.6471, 0.3255 },
  { 0.4941, 0.2941, 0.4078 },
  { 0.1608, 0.1608, 0.3961 },
  { 0.1608, 0.1608, 0.3961 },
  { 0.1608, 0.1608, 0.3961 },
  { 0.1608, 0.1608, 0.3961 },
  { 0.4941, 0.2941, 0.4078 },
  { 0.9059, 0.6471, 0.3255 },
  { 0.8863, 0.8902, 0.5451 },
  { 0.4000, 0.5882, 0.7294 },
  { 0.4000, 0.5882, 0.7294 },
  { 0.4000, 0.5882, 0.7294 },
  { 0.4000, 0.5882, 0.7294 }
}

local MIDI_CC_CHANNEL_2 = 0xB1
local MIDI_CC_CHANNEL_6 = 0xB5

local START_CC = 0
local STOP_CC = 1

local LOOPER_CC_SOURCE_RESET = 1
local LOOPER_CC_VALUE_LOW = 0
local LOOPER_CC_VALUE_HIGH = 127

local MT = MIDIMessageType or {}
local SHAPE = Shape or {}

local MIDI_CLOCK = 248
local MIDI_START = 250
local MIDI_CONTINUE = 251
local MIDI_STOP = 252
local MIDI_SONGPOSITION = 242

local eventActions = {
  event_drop_kick = {
    { type = 'set', control = 'perc_groove', values = { x = 0, y = 0 } },
    { type = 'set', control = 'perc_density', values = { x = 0, y = 0 } },
    { type = 'set', control = 'perc_structure', values = { x = 0, y = 0 } },
    { type = 'set', control = 'drums_density', values = { x = 0, y = 0.5 } },
    { type = 'set', control = 'drums_high', values = { x = 0, y = 0 } }
  }
}

local function log(...)
  if DEBUG then
    print(...)
  end
end

local function clamp(value)
  if value < 0 then
    return 0
  end

  if value > 1 then
    return 1
  end

  return value
end

local function nowSeconds()
  if getMillis then
    return getMillis() / 1000
  end

  return nil
end

local function isMessage(message, rawByte, enumValue)
  return message[1] == rawByte or message[1] == enumValue
end

local function connectionList(connections)
  local active = {}

  for i = 1, #connections do
    if connections[i] then
      active[#active + 1] = tostring(i)
    end
  end

  if #active == 0 then
    return 'none'
  end

  return table.concat(active, ',')
end

local function lerp(a, b, t)
  return a + (b - a) * t
end

local function colorAtStop(index)
  return dayNightStops[index]
end

local function dayNightColor(position)
  local segmentCount = #dayNightStops - 1
  local scaled = (position % 1) * segmentCount
  local index = math.floor(scaled) + 1
  local t = scaled - math.floor(scaled)

  if index > segmentCount then
    index = segmentCount
    t = 1
  end

  local a = colorAtStop(index)
  local b = colorAtStop(index + 1)

  return Color(
    lerp(a[1], b[1], t),
    lerp(a[2], b[2], t),
    lerp(a[3], b[3], t)
  )
end

local function scaledColor(rgb, factor)
  return Color(
    clamp(rgb[1] * factor),
    clamp(rgb[2] * factor),
    clamp(rgb[3] * factor)
  )
end

local function setControlColor(control, color)
  if control then
    control.visible = true
    control.background = true
    control.color = color
  end
end

local function pulseBrightness()
  local now = nowSeconds()

  if not now then
    return 0.84
  end

  return 0.62 + 0.38 * ((math.sin(now * 8.5) + 1) * 0.5)
end

local function initClipMatrix()
  selected_clip_free = {}

  for scene = 1, #sceneNames do
    selected_clip_free[scene] = {}

    for track = 1, #trackDefinitions do
      selected_clip_free[scene][track] = true
    end
  end
end

local function setLight(i, color)
  if lights[i] then
    lights[i].visible = true
    lights[i].background = true
    lights[i].outline = false
    lights[i].color = color
  end
end

local function setDisplayBar(i, color)
  if displayBars[i] then
    displayBars[i].visible = true
    displayBars[i].background = true
    displayBars[i].outline = false
    displayBars[i].color = color
  end
end

local function currentDisplayBar()
  return ((modePhase - 1) % 8) + 1
end

local function updateBarIndicator()
  local currentBar = currentDisplayBar()

  for i = 1, #displayBarNames do
    if i < currentBar then
      setDisplayBar(i, white)
    elseif i == currentBar then
      setDisplayBar(i, barYellow)
    else
      setDisplayBar(i, black)
    end
  end
end

local function showIdleSpectrum()
  for i = 1, #beatNames do
    local position = (i - 1) / #beatNames
    local cyclePosition = (position + idlePhase) % 1

    setLight(i, dayNightColor(cyclePosition))
  end
end

local function showStep()
  for i = 1, #beatNames do
    setLight(i, (i == step) and white or black)
  end
end

local function advanceStep()
  step = step + 1

  if step > #beatNames then
    step = 1
  end

  showStep()
end

local function setTransportButtonState()
  if transportButton then
    transportButton.color = isPlaying and red or green

    if SHAPE.RECTANGLE and SHAPE.TRIANGLE then
      transportButton.shape = isPlaying and SHAPE.RECTANGLE or SHAPE.TRIANGLE
    end
  end
end

local function sendMomentaryCC(statusByte, cc)
  sendMIDI({ statusByte, cc, 127 })
  sendMIDI({ statusByte, cc, 0 })
end

local function sendTransportCC(cc)
  sendMomentaryCC(MIDI_CC_CHANNEL_2, cc)
end

local function sendLooperCC(cc)
  sendMomentaryCC(MIDI_CC_CHANNEL_6, cc)
end

local function sendLooperCCValue(cc, value)
  sendMIDI({ MIDI_CC_CHANNEL_6, cc, value })
end

local function barLengthDefinition(length)
  for i = 1, #barLengthDefinitions do
    if barLengthDefinitions[i].bars == length then
      return barLengthDefinitions[i]
    end
  end

  return nil
end

local function isLengthBoundaryPhase(length)
  return ((modePhase - 1) % length) == 0
end

local function isSelectedBoundaryPhase()
  return isLengthBoundaryPhase(selected_bar_length_current)
end

local function hasPendingBarLengthChange()
  return selected_bar_length ~= selected_bar_length_current
end

local function selectedBarDefinition()
  return barLengthDefinition(selected_bar_length_current)
end

local function currentBufferRecCC()
  local definition = selectedBarDefinition()
  return definition and definition.rec_cc or 15
end

local function currentBufferPlayCC()
  local definition = selectedBarDefinition()
  return definition and definition.play_cc or 16
end

local function currentBufferMuteCC()
  local definition = selectedBarDefinition()
  return definition and definition.mute_cc or 17
end

local function sendBufferRecMuteForLength(length)
  local definition = barLengthDefinition(length)

  if definition then
    sendLooperCC(definition.rec_cc)
    sendLooperCCValue(definition.mute_cc, LOOPER_CC_VALUE_LOW)
  end
end

local function sendCurrentBufferRecMute()
  sendLooperCC(currentBufferRecCC())
  sendLooperCCValue(currentBufferMuteCC(), LOOPER_CC_VALUE_LOW)
end

local function sendCurrentBufferPlayUnmute()
  sendLooperCC(currentBufferPlayCC())
  sendLooperCCValue(currentBufferMuteCC(), LOOPER_CC_VALUE_HIGH)
end

local function shouldTriggerInactiveBuffer(length)
  return isLengthBoundaryPhase(length) or isSelectedBoundaryPhase()
end

local function runInactiveBufferUpkeep()
  for i = 1, #barLengthDefinitions do
    local definition = barLengthDefinitions[i]

    if definition.bars ~= selected_bar_length_current and shouldTriggerInactiveBuffer(definition.bars) then
      sendLooperCC(definition.rec_cc)
      sendLooperCCValue(definition.mute_cc, LOOPER_CC_VALUE_LOW)
    end
  end
end

local function canAdoptRequestedBarLength()
  return mode_current == 'play' and hasPendingBarLengthChange() and isLengthBoundaryPhase(selected_bar_length)
end

local function requestedSceneIndexForTrack(track)
  if track == 1 then
    return bass_scene_index
  end

  return scene_index
end

local function currentSceneIndexForTrack(track)
  if track == 1 then
    return bass_scene_index_current
  end

  return scene_index_current
end

local function hasPendingMainSceneChange()
  return scene_index ~= scene_index_current
end

local function hasPendingBassSceneChange()
  return bass_scene_index ~= bass_scene_index_current
end

local function hasPendingSceneChangeForRequestedTrack()
  if track_index == 1 then
    return hasPendingBassSceneChange()
  end

  return hasPendingMainSceneChange()
end

local function currentClipIsFree()
  local sceneRow = selected_clip_free[requestedSceneIndexForTrack(track_index)]

  if not sceneRow then
    return true
  end

  return sceneRow[track_index] ~= false
end

local function activeClipIsFree()
  local sceneRow = selected_clip_free[currentSceneIndexForTrack(track_index_current)]

  if not sceneRow then
    return true
  end

  return sceneRow[track_index_current] ~= false
end

local function hasPendingSceneChange()
  return hasPendingSceneChangeForRequestedTrack()
end

local function hasPendingTrackChange()
  return track_index ~= track_index_current
end

local function hasPendingModeChange()
  return mode ~= mode_current
end

local function isModeLockedWhileIdle(requestedMode)
  return not running and requestedMode ~= 'play'
end

local function syncCurrentSelection()
  local previousTrack = track_index_current

  track_index_current = track_index

  if track_index_current == 1 then
    if bass_scene_index_current ~= bass_scene_index or previousTrack ~= 1 then
      bass_scene_launch_pending = true
    end

    bass_scene_index_current = bass_scene_index
  else
    if scene_index_current ~= scene_index or previousTrack ~= track_index_current then
      main_scene_launch_pending = true
    end

    scene_index_current = scene_index
  end
end

local function scenePlayCCForTrack(track, scene)
  if track == 1 then
    return scene * 10 + 4
  end

  return scene * 10
end

local function clipActionCCForTrack(track, scene)
  return scene * 10 + track
end

local function mainSceneSelectedTrack()
  return main_scene_track_index
end

local function bassSceneSelectedTrack()
  return 1
end

local function nextModePhase()
  local nextValue = modePhase + 1

  if nextValue > 16 then
    nextValue = 1
  end

  modePhase = nextValue
end

local function setPlayRequested()
  mode = 'play'
end

local function applySetAction(action)
  local target = self:findByName(action.control, true)

  if not target then
    print('event target missing', action.control)
    return
  end

  for valueName, value in pairs(action.values or {}) do
    if target.values[valueName] == nil then
      print('event value missing', action.control, valueName)
    else
      target.values[valueName] = value
    end
  end
end

local function applyEventAction(eventName)
  local actions = eventActions[eventName]

  if not actions then
    print('event action missing', eventName)
    return
  end

  for i = 1, #actions do
    local action = actions[i]
    local actionType = action.type or 'set'

    if actionType == 'set' then
      applySetAction(action)
    else
      print('event action type missing', actionType)
    end
  end
end

local function sendMainScenePlay()
  sendLooperCC(scenePlayCCForTrack(mainSceneSelectedTrack(), scene_index_current))
end

local function sendBassScenePlay()
  sendLooperCC(scenePlayCCForTrack(bassSceneSelectedTrack(), bass_scene_index_current))
end

local function sendPendingScenePlays()
  if main_scene_launch_pending then
    sendMainScenePlay()
    main_scene_launch_pending = false
  end

  if bass_scene_launch_pending then
    sendBassScenePlay()
    bass_scene_launch_pending = false
  end
end

local function sendSelectedClipAction()
  sendLooperCC(clipActionCCForTrack(
    track_index_current,
    currentSceneIndexForTrack(track_index_current)
  ))
end

local function runPlayBoundary()
  sendLooperCC(LOOPER_CC_SOURCE_RESET)
  sendPendingScenePlays()
  sendCurrentBufferRecMute()
end

local function runFreezeBoundary()
  sendLooperCC(LOOPER_CC_SOURCE_RESET)
  sendPendingScenePlays()
  sendCurrentBufferPlayUnmute()
end

local function runStorePhaseOne()
  if not activeClipIsFree() then
    mode_current = 'freeze'
    mode = 'freeze'
    runFreezeBoundary()
    return
  end

  sendLooperCC(LOOPER_CC_SOURCE_RESET)
  sendPendingScenePlays()
  sendSelectedClipAction()
  sendCurrentBufferPlayUnmute()
end

local function runStorePhaseOneEarly()
  if not activeClipIsFree() then
    mode_current = 'freeze'
    mode = 'freeze'
    runFreezeBoundary()
    return
  end

  sendLooperCC(LOOPER_CC_SOURCE_RESET)
  sendPendingScenePlays()
  sendSelectedClipAction()
  sendCurrentBufferPlayUnmute()
end

local function runStorePhaseOneExact()
  if not activeClipIsFree() then
    mode_current = 'freeze'
    mode = 'freeze'
  end
end

local function runStorePhaseNine()
  selected_clip_free[currentSceneIndexForTrack(track_index_current)][track_index_current] = false

  sendSelectedClipAction()
  sendCurrentBufferRecMute()

  mode_current = 'freeze'
  mode = 'freeze'
  store_phase = 1
end

local function runStorePhaseNineEarly()
  sendSelectedClipAction()
  sendCurrentBufferRecMute()
end

local function runStorePhaseNineExact()
  selected_clip_free[currentSceneIndexForTrack(track_index_current)][track_index_current] = false
  mode_current = 'freeze'
  mode = 'freeze'
  store_phase = 1
end

local function updateLooperVisuals()
  local pulse = pulseBrightness()

  for i = 1, #trackDefinitions do
    local definition = trackDefinitions[i]
    local control = trackButtons[i]
    local selected = (track_index == definition.index)
    local baseColor = definition.color
    local factor = selected and 1.0 or 0.38

    if selected and mode == 'store' then
      baseColor = { 1.00, 0.18, 0.18 }
    end

    setControlColor(control, scaledColor(baseColor, factor))
  end

  for i = 1, #modeDefinitions do
    local definition = modeDefinitions[i]
    local control = modeButtons[i]
    local selected = (mode == definition.mode)
    local pending = selected and hasPendingModeChange()
    local factor = selected and 1.0 or 0.40

    if pending then
      factor = pulse
    end

    setControlColor(control, scaledColor(definition.color, factor))
  end

  for i = 1, #barLengthDefinitions do
    local definition = barLengthDefinitions[i]
    local control = barButtons[i]
    local active = (selected_bar_length_current == definition.bars)
    local baseColor = active and { 0.94, 0.86, 0.42 } or { 0.42, 0.40, 0.24 }
    local factor = active and 1.0 or 0.52

    setControlColor(control, scaledColor(baseColor, factor))
  end

  for i = 1, #sceneNames do
    local control = sceneButtons[i]
    local selected = (scene_index == i)
    local pending = selected and hasPendingMainSceneChange()
    local clipFree = selected_clip_free[i][mainSceneSelectedTrack()] ~= false
    local baseColor = nil
    local factor = 1.0

    if selected then
      if clipFree then
        if mode == 'store' then
          baseColor = { 1.00, 0.18, 0.18 }
        else
          baseColor = { 1.0, 1.0, 1.0 }
        end
      else
        baseColor = { 0.18, 1.00, 0.30 }
      end
    else
      if clipFree then
        baseColor = { 0.10, 0.42, 0.14 }
      else
        baseColor = { 0.62, 0.62, 0.62 }
      end

      factor = 0.42
    end

    if pending then
      factor = pulse
    end

    setControlColor(control, scaledColor(baseColor, factor))
  end

  for i = 1, #bassSceneNames do
    local control = bassSceneButtons[i]
    local selected = (bass_scene_index == i)
    local pending = selected and hasPendingBassSceneChange()
    local clipFree = selected_clip_free[i][bassSceneSelectedTrack()] ~= false
    local baseColor = nil
    local factor = 1.0

    if selected then
      if clipFree then
        if mode == 'store' then
          baseColor = { 1.00, 0.18, 0.18 }
        else
          baseColor = { 1.00, 0.82, 0.62 }
        end
      else
        baseColor = { 0.98, 0.52, 0.24 }
      end
    else
      if clipFree then
        baseColor = { 0.44, 0.18, 0.08 }
      else
        baseColor = { 0.62, 0.56, 0.52 }
      end

      factor = 0.42
    end

    if pending then
      factor = pulse
    end

    setControlColor(control, scaledColor(baseColor, factor))
  end
end

local function maybeAdoptRequestedCycle()
  if canAdoptRequestedBarLength() then
    selected_bar_length_current = selected_bar_length
    store_phase = 1
  end

  local boundary = isSelectedBoundaryPhase()

  if not boundary then
    return
  end

  if mode_current == 'play' or mode_current == 'freeze' then
    if hasPendingModeChange() then
      syncCurrentSelection()
      mode_current = mode
      store_phase = 1
      return
    end

    if hasPendingSceneChangeForRequestedTrack() or hasPendingTrackChange() then
      syncCurrentSelection()
    end
  end
end

local function isScheduledBoundaryPhase()
  return true
end

local function runBoundaryEarly()
  maybeAdoptRequestedCycle()
  runInactiveBufferUpkeep()

  if not isScheduledBoundaryPhase() then
    return
  end

  if not isSelectedBoundaryPhase() then
    return
  end

  if mode_current == 'play' then
    runPlayBoundary()
  elseif mode_current == 'freeze' then
    runFreezeBoundary()
  elseif mode_current == 'store' then
    if store_phase == 1 then
      runStorePhaseOneEarly()
    elseif store_phase == 2 then
      runStorePhaseNineEarly()
    end
  end
end

local function runBoundaryExact()
  if mode_current == 'store' and isSelectedBoundaryPhase() then
    if store_phase == 1 then
      runStorePhaseOneExact()

      if activeClipIsFree() and mode_current == 'store' then
        store_phase = 2
      end
    elseif store_phase == 2 then
      runStorePhaseNineExact()
    end
  end
end

local function finishBarBoundary()
  runBoundaryExact()

  updateLooperVisuals()
  updateBarIndicator()
  nextModePhase()
end

local function runStartBoundary()
  maybeAdoptRequestedCycle()
  runInactiveBufferUpkeep()

  if not isScheduledBoundaryPhase() then
    return
  end

  if not isSelectedBoundaryPhase() then
    updateLooperVisuals()
    updateBarIndicator()
    nextModePhase()
    return
  end

  if mode_current == 'play' then
    runPlayBoundary()
  elseif mode_current == 'freeze' then
    runFreezeBoundary()
  elseif mode_current == 'store' then
    if store_phase == 1 then
      runStorePhaseOne()
      if activeClipIsFree() and mode_current == 'store' then
        store_phase = 2
      end
    elseif store_phase == 2 then
      runStorePhaseNine()
    end
  end

  updateLooperVisuals()
  updateBarIndicator()
  nextModePhase()
end

local function alignToSongPosition(message)
  local lsb = message[2] or 0
  local msb = message[3] or 0
  local sixteenthNotes = lsb + msb * 128
  local quarterNotes = math.floor(sixteenthNotes / 4)
  local bars = math.floor(sixteenthNotes / 16)

  beatClocks = 0
  barClocks = 0
  step = (quarterNotes % #beatNames) + 1
  modePhase = (bars % 16) + 1
end

function init()
  log('v21 init started')

  lights = {}
  displayBars = {}
  sceneButtons = {}
  bassSceneButtons = {}
  trackButtons = {}
  modeButtons = {}
  barButtons = {}
  trackNameToIndex = {}
  modeNameToValue = {}
  barNameToLength = {}

  for i = 1, #beatNames do
    lights[i] = self:findByName(beatNames[i], true)

    if not lights[i] then
      print('v21 MISSING', beatNames[i])
    end
  end

  for i = 1, #displayBarNames do
    displayBars[i] = self:findByName(displayBarNames[i], true)

    if not displayBars[i] then
      print('v21 MISSING', displayBarNames[i])
    end
  end

  for i = 1, #sceneNames do
    sceneButtons[i] = self:findByName(sceneNames[i], true)

    if not sceneButtons[i] then
      print('v21 MISSING', sceneNames[i])
    end
  end

  for i = 1, #bassSceneNames do
    bassSceneButtons[i] = self:findByName(bassSceneNames[i], true)

    if not bassSceneButtons[i] then
      print('v21 MISSING', bassSceneNames[i])
    end
  end

  for i = 1, #trackDefinitions do
    local definition = trackDefinitions[i]
    trackButtons[i] = self:findByName(definition.name, true)
    trackNameToIndex[definition.name] = definition.index

    if not trackButtons[i] then
      print('v21 MISSING', definition.name)
    end
  end

  for i = 1, #modeDefinitions do
    local definition = modeDefinitions[i]
    modeButtons[i] = self:findByName(definition.name, true)
    modeNameToValue[definition.name] = definition.mode

    if not modeButtons[i] then
      print('v21 MISSING', definition.name)
    end
  end

  for i = 1, #barLengthDefinitions do
    local definition = barLengthDefinitions[i]
    barButtons[i] = self:findByName(definition.name, true)
    barNameToLength[definition.name] = definition.bars

    if not barButtons[i] then
      print('v21 MISSING', definition.name)
    end
  end

  transportButton = self:findByName('transport_btn', true)

  if not transportButton then
    print('v21 MISSING transport_btn')
  end

  initClipMatrix()

  mode = 'play'
  mode_current = 'play'
  scene_index = 1
  scene_index_current = 1
  bass_scene_index = 1
  bass_scene_index_current = 1
  track_index = 1
  track_index_current = 1
  main_scene_track_index = 2
  selected_bar_length = 8
  selected_bar_length_current = 8
  store_phase = 1
  modePhase = 1
  main_scene_launch_pending = true
  bass_scene_launch_pending = true

  running = false
  isPlaying = false
  step = 1
  beatClocks = 0
  barClocks = 0
  clockDebugCount = 0
  clockDebugLast = nil
  lastUpdateSeconds = nowSeconds()

  setTransportButtonState()
  updateLooperVisuals()
  updateBarIndicator()
  showIdle()

  log('v21 init finished')
end

function showIdle()
  running = false
  isPlaying = false
  beatClocks = 0
  barClocks = 0
  step = 1
  mode = 'play'
  mode_current = 'play'
  store_phase = 1
  modePhase = 1
  main_scene_launch_pending = true
  bass_scene_launch_pending = true

  setTransportButtonState()
  updateLooperVisuals()
  updateBarIndicator()
  showIdleSpectrum()
end

function update()
  updateLooperVisuals()

  if running then
    return
  end

  local now = nowSeconds()
  local dt = 0.016

  if now then
    if lastUpdateSeconds then
      dt = now - lastUpdateSeconds
    end

    lastUpdateSeconds = now
  end

  idlePhase = (idlePhase + idleSpeed * dt) % 1
  showIdleSpectrum()
end

function onReceiveMIDI(message, connections)
  if isMessage(message, MIDI_START, MT.START) then
    running = true
    isPlaying = true
    beatClocks = 0
    barClocks = 0
    step = 1
    modePhase = 1

    setTransportButtonState()
    showStep()
    runStartBoundary()
    return
  end

  if isMessage(message, MIDI_CONTINUE, MT.CONTINUE) then
    running = true
    isPlaying = true

    setTransportButtonState()
    showStep()
    return
  end

  if isMessage(message, MIDI_STOP, MT.STOP) then
    showIdle()
    return
  end

  if isMessage(message, MIDI_SONGPOSITION, MT.SONGPOSITION) then
    alignToSongPosition(message)
    showStep()
    updateLooperVisuals()
    updateBarIndicator()
    return
  end

  if isMessage(message, MIDI_CLOCK, MT.CLOCK) and running then
    beatClocks = beatClocks + 1
    barClocks = barClocks + 1

    if CLOCK_DEBUG then
      local now = nowSeconds()

      if now then
        if not clockDebugLast then
          clockDebugLast = now
        end

        clockDebugCount = clockDebugCount + 1

        if now - clockDebugLast >= 1 then
          print('clock messages per second', clockDebugCount, 'connections', connectionList(connections))
          clockDebugCount = 0
          clockDebugLast = now
        end
      end
    end

    if beatClocks >= CLOCKS_PER_BEAT then
      beatClocks = 0
      advanceStep()
    end

    if barClocks == (CLOCKS_PER_BAR - EARLY_TRIGGER_CLOCKS) then
      runBoundaryEarly()
    end

    if barClocks >= CLOCKS_PER_BAR then
      barClocks = 0
      finishBarBoundary()
    end
  end
end

function onReceiveNotify(key, value)
  if key == 'transport_button_pressed' then
    if isPlaying then
      sendTransportCC(STOP_CC)
    else
      sendTransportCC(START_CC)
    end

    return
  end

  if key == 'event_button_pressed' then
    applyEventAction(value)
    return
  end

  if key == 'looper_scene_pressed' then
    local sceneNumber = tonumber(string.match(value or '', '(%d+)$'))

    if sceneNumber and sceneNames[sceneNumber] and scene_index ~= sceneNumber then
      scene_index = sceneNumber
      updateLooperVisuals()
    end

    return
  end

  if key == 'looper_bass_scene_pressed' then
    local sceneNumber = tonumber(string.match(value or '', '(%d+)$'))

    if sceneNumber and bassSceneNames[sceneNumber] and bass_scene_index ~= sceneNumber then
      bass_scene_index = sceneNumber
      updateLooperVisuals()
    end

    return
  end

  if key == 'looper_track_pressed' then
    local requestedTrack = trackNameToIndex[value]

    if requestedTrack and track_index ~= requestedTrack then
      track_index = requestedTrack

      if requestedTrack ~= 1 then
        main_scene_track_index = requestedTrack
      end

      syncCurrentSelection()

      updateLooperVisuals()
    end

    return
  end

  if key == 'looper_bars_pressed' then
    local requestedBars = barNameToLength[value]

    if requestedBars and selected_bar_length ~= requestedBars then
      selected_bar_length = requestedBars
      selected_bar_length_current = requestedBars
      store_phase = 1
      updateLooperVisuals()
    end

    return
  end

  if key == 'looper_mode_pressed' then
    local requestedMode = modeNameToValue[value]

    if requestedMode and not isModeLockedWhileIdle(requestedMode) and mode ~= requestedMode then
      mode = requestedMode
      updateLooperVisuals()
    end

    return
  end
end
