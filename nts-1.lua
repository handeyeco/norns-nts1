-- Korg NTS-1 (mk 1) Controller

controls = {
  { name = "osc type", cc = 53, id = "osc-type", default = 0 },
  { name = "osc shape", cc = 54, id = "osc-shape", default = 0 },
  { name = "osc alt", cc = 55, id = "osc-alt", default = 0 },
  { name = "osc lfo rate", cc = 24, id = "osc-lfo-rate", default = 0 },
  { name = "osc lfo depth", cc = 26, id = "osc-lfo-depth", default = 0 },
  { name = "filt type", cc = 42, id = "filt-type", default = 0 },
  { name = "filt cutoff", cc = 43, id = "filt-cutoff", default = 0 },
  { name = "filt resonance", cc = 55, id = "filt-resonance", default = 0 },
}

page = 0

active_control_index = 1
confirming_send_values = false
confirming_random_patch = false

active_midi_index = 1

in_midi_index = 1
in_midi_channel = 1
in_midi = midi.connect(in_midi_index)

out_midi_index = 1
out_midi_channel = 1
out_midi = midi.connect(out_midi_index)

function setupMidiCallback()
  in_midi.event = function(data)
    local message = midi.to_msg(data)
    if (message.ch == in_midi_channel) then
      message.ch = out_midi_channel
      out_midi:send(midi.to_data(message))
    end
  end
end

function init()
  for _, control in pairs(controls) do
    params:add{
      type="number",
      id=control.id,
      min=0,
      max=127,
      default=control.default,
      action=function(x) out_midi:cc(control.cc, x) end
    }
  end
  setupMidiCallback()
end

function drawLine(yPos, leftText, rightText, active)
  local textPos = yPos + 7
  if active then
    screen.level(15)
    screen.rect(0,yPos,256,9)
    screen.fill()
    screen.level(0)
  else
    screen.level(2)
  end

  screen.move(1, textPos)
  screen.text(leftText)
  screen.move(128-1, textPos)
  screen.text_right(rightText)
end

function drawMenu()
  for i=active_control_index, #controls do
    local control = controls[i]
    drawLine(
      ((i - active_control_index) * 10),
      control.name,
      params:get(control.id),
      active_control_index == i
    )
  end
end

function drawMidiOptions()
  drawLine(0, "in:", in_midi_index .. " " .. midi.devices[in_midi_index].name, active_midi_index==1)
  drawLine(10, "in ch:", in_midi_channel, active_midi_index==2)
  drawLine(20, "out:", out_midi_index .. " " .. midi.devices[out_midi_index].name, active_midi_index==3)
  drawLine(30, "out ch:", out_midi_channel, active_midi_index==4)
end

function confirm(text)
  screen.level(15)
  screen.move(128/2, 64/2)
  screen.text_center(text)
  screen.move(128/2, 64/2 + 10)
  screen.level(1)
  screen.text_center("k2=back, k3=confirm")
end

function redraw()
  screen.clear()
  screen.fill()
  if confirming_send_values then
    confirm("send all values?")
  elseif confirming_random_patch then
    confirm("create random patch?")
  elseif page == 0 then
    drawMenu()
  elseif page == 1 then
    drawMidiOptions()
  end
  screen.update()
end

function handleMenuEncoder(n,d)
  if n == 2 then
    active_control_index = util.clamp(active_control_index + d, 1, #controls)
  elseif n == 3 then
    params:delta(controls[active_control_index].id, d)
  end
end

function handleMidiEncoder(n,d)
  if n == 2 then
    active_midi_index = util.clamp(active_midi_index + d, 1, 4)
  elseif n == 3 then
    if (active_midi_index == 1) then
      in_midi_index = util.clamp(in_midi_index + d, 1, #midi.devices)
      in_midi = midi.connect(in_midi_index)
      setupMidiCallback()
    elseif (active_midi_index == 2) then
      in_midi_channel = util.clamp(in_midi_channel + d, 1, 16)
    elseif (active_midi_index == 3) then
      out_midi_index = util.clamp(out_midi_index + d, 1, #midi.devices)
      out_midi = midi.connect(out_midi_index)
    elseif (active_midi_index == 4) then
      out_midi_channel = util.clamp(out_midi_channel + d, 1, 16)
    end
  end
end

function enc(n,d)
  if (n == 1) then
    page = util.clamp(page + d, 0, 1)
  elseif (page == 0) then
    handleMenuEncoder(n,d)
  elseif (page == 1) then
    handleMidiEncoder(n,d)
  end
  redraw()
end

function sendValues()
  params:bang()
end

function randomPatch()
  for _, control in pairs(controls) do
    params:set(control.id, math.random(1, 127))
  end
end

function handleMenuKey(n,z)
  if n == 2 and z == 1 then
    if confirming_send_values or confirming_random_patch then
      confirming_send_values = false
      confirming_random_patch = false
    else
      confirming_send_values = true
    end
  elseif n==3 and z == 1 then
    if confirming_send_values then
      confirming_send_values = false
      confirming_random_patch = false
      sendValues()
    elseif confirming_random_patch then
      confirming_send_values = false
      confirming_random_patch = false
      randomPatch()
    else
      confirming_random_patch = true
    end
  end
end

function handleMidiKey(n,z)
  print("these don't do anything")
end

function key(n,z)
  if (page == 0) then
    handleMenuKey(n,z)
  elseif (page == 1) then
    handleMidiKey(n,z)
  end
  redraw()
end