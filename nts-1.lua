-- Control the
-- Korg NTS-1 (mk 1)
--
-- by handeyeco
--
-- Guide
--
-- All screens:
-- - E1: change page
-- - E2: select parameter
-- - E3: change parameter
--
-- Help screen:
-- - K2: reset NTS-1 parameters
--
-- NTS-1 screen:
-- - K2: send all parameters
-- - K3: create random patch

controls = {
  { name = "osc type", cc = 53, id = "osc-type", default = 0 },
  { name = "osc shape", cc = 54, id = "osc-shape", default = 0 },
  { name = "osc alt", cc = 55, id = "osc-alt", default = 0 },
  { name = "osc lfo rate", cc = 24, id = "osc-lfo-rate", default = 0 },
  { name = "osc lfo depth", cc = 26, id = "osc-lfo-depth", default = 64 },

  { name = "filt type", cc = 42, id = "filt-type", default = 0 },
  { name = "filt cutoff", cc = 43, id = "filt-cutoff", default = 127 },
  { name = "filt resonance", cc = 44, id = "filt-resonance", default = 0 },
  { name = "filt sweep depth", cc = 45, id = "filt-sweep-depth", default = 64 },
  { name = "filt sweep rate", cc = 46, id = "filt-sweep-rate", default = 0 },

  { name = "eg type", cc = 14, id = "eg-type", default = 0 },
  { name = "eg attack", cc = 16, id = "eg-attack", default = 0 },
  { name = "eg release", cc = 19, id = "eg-release", default = 64 },
  { name = "trem rate", cc = 20, id = "trem-rate", default = 0 },
  { name = "trem depth", cc = 21, id = "trem-depth", default = 0 },

  { name = "mod type", cc = 88, id = "mod-type", default = 0 },
  { name = "mod time", cc = 28, id = "mod-time", default = 64 },
  { name = "mod depth", cc = 29, id = "mod-depth", default = 64 },

  { name = "delay type", cc = 89, id = "delay-type", default = 0 },
  { name = "delay time", cc = 30, id = "delay-time", default = 64 },
  { name = "delay depth", cc = 31, id = "delay-depth", default = 64 },
  { name = "delay mix", cc = 33, id = "delay-mix", default = 64 },

  { name = "reverb type", cc = 90, id = "reverb-type", default = 0 },
  { name = "reverb time", cc = 34, id = "reverb-time", default = 64 },
  { name = "reverb depth", cc = 35, id = "reverb-depth", default = 64 },
  { name = "reverb mix", cc = 36, id = "reverb-mix", default = 64 },

  { name = "arp pattern", cc = 117, id = "arp-pattern", default = 64 },
  { name = "arp interval", cc = 118, id = "arp-interval", default = 64 },
  { name = "arp length", cc = 119, id = "arp-length", default = 64 },
}

page = 1

active_control_index = 1
confirming_reset_values = false
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
  for i=1, #controls do
    local control = controls[i]
    local yPos = 0
    if active_control_index < 4 then
      yPos = (i - 1) * 10
    else
      yPos = ((i - active_control_index + 3) * 10)
    end
    drawLine(
      yPos,
      control.name,
      params:get(control.id),
      active_control_index == i
    )
  end
end

function drawHelp()
  drawLine(0, "all pages", "", false)
  drawLine(10, "", "e1:page e2:select e3:change", false)
  drawLine(20, "nts-1 page", "", false)
  drawLine(30, "", "k2:send k3:random", false)
  drawLine(40, "this page", "", false)
  drawLine(50, "", "k2:reset", false)
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
  elseif confirming_reset_values then
    confirm("reset all values?")
  elseif page == 0 then
    drawHelp()
  elseif page == 1 then
    drawMenu()
  elseif page == 2 then
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
    resetConfirm()
    page = util.clamp(page + d, 0, 2)
  elseif (page == 1) then
    handleMenuEncoder(n,d)
  elseif (page == 2) then
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

function resetParams()
  for _, control in pairs(controls) do
    params:set(control.id, control.default)
  end
end

function resetConfirm()
  confirming_reset_values = false
  confirming_send_values = false
  confirming_random_patch = false
end

function handleHelpKey(n,z)
  if z == 1 then
    if n == 2 then
      if confirming_reset_values then
        resetConfirm()
      else
        confirming_reset_values = true
      end
    elseif n == 3 then
      if confirming_reset_values then
        resetConfirm()
        resetParams()
      end
    end
  end
end

function handleMenuKey(n,z)
  if z == 1 then
    if n == 2 then
      if confirming_send_values or confirming_random_patch then
        resetConfirm()
      else
        confirming_send_values = true
      end
    elseif n == 3 then
      if confirming_send_values then
        resetConfirm()
        sendValues()
      elseif confirming_random_patch then
        resetConfirm()
        randomPatch()
      else
        confirming_random_patch = true
      end
    end
  end
end

function handleMidiKey(n,z)
  print("these don't do anything")
end

function key(n,z)
  if (page == 0) then
    handleHelpKey(n,z)
  elseif (page == 1) then
    handleMenuKey(n,z)
  elseif (page == 2) then
    handleMidiKey(n,z)
  end
  redraw()
end