-- looper scene selector button

function onValueChanged(valueName)
  if valueName == 'touch' and self.values[valueName] == true then
    root:notify('looper_scene_pressed', self.name)
  end

  return true
end
