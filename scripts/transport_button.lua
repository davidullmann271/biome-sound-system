-- version 11 transport button

function init()
  -- Keep this rare startup log while developing; remove if desired.
  print('v11 transport button init')
end

function onValueChanged(valueName)
  local value = self.values[valueName]

  -- React only to finger-down. Ignore x/y/release changes.
  if valueName == 'touch' and value == true then
    root:notify('transport_button_pressed')
  end

  -- Stop normal TouchOSC messages from also firing.
  return true
end
