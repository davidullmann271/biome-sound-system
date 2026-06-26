-- version 1 event_drop_kick
-- name based event

function onValueChanged(valueName)
  local value = self.values[valueName]

  if valueName == 'touch' and value == true then
    root:notify('event_button_pressed', self.name)
  end

  return true
end
