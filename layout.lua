local pageIndex = props["page_index"].Value
local CurrentPage = pageIndex <= #PageNames and PageNames[pageIndex]
  or "Monitor " .. tostring(pageIndex - #PageNames)

local function addLabel(text, x, y, w, h, align)
  table.insert(graphics, {
    Type = "Text",
    Text = text,
    Position = { x, y },
    Size = { w, h },
    FontSize = 12,
    HTextAlign = align or "Left"
  })
end

local function addGroup(text, x, y, w, h)
  table.insert(graphics, {
    Type = "GroupBox",
    Text = text,
    Fill = { 230, 234, 237 },
    StrokeWidth = 1,
    Position = { x, y },
    Size = { w, h }
  })
end

local function button(name, pretty, legend, x, y, w, h, color)
  layout[name] = {
    PrettyName = pretty,
    Style = "Button",
    Legend = legend,
    Position = { x, y },
    Size = { w, h },
    Color = color or { 34, 88, 122 }
  }
end

local function textBox(name, pretty, x, y, w, h)
  layout[name] = {
    PrettyName = pretty,
    Style = "Text",
    Position = { x, y },
    Size = { w, h }
  }
end

local function led(name, pretty, x, y)
  layout[name] = {
    PrettyName = pretty,
    Style = "Led",
    Position = { x, y },
    Size = { 20, 20 },
    Color = { 56, 142, 60 }
  }
end

if CurrentPage == "Control" then
  addGroup("Target", 5, 5, 330, 58)
  addLabel("Address", 18, 31, 64, 16, "Right")
  textBox("Address", "AHnet Address", 88, 27, 46, 24)
  button("Broadcast", "Broadcast", "Broadcast", 146, 27, 96, 24, { 96, 96, 96 })

  addGroup("Movement", 5, 70, 160, 106)
  button("Up", "Movement~Up", "Up", 15, 94, 65, 30, { 46, 125, 50 })
  button("Down", "Movement~Down", "Down", 90, 94, 65, 30, { 198, 76, 35 })
  button("MovementToggle", "Movement~Toggle", "Up / Down", 15, 132, 140, 30, { 46, 125, 50 })

  addGroup("Display", 175, 70, 160, 106)
  button("ScreenOn", "Display~On", "On", 185, 94, 65, 30, { 46, 125, 50 })
  button("ScreenOff", "Display~Off", "Off", 260, 94, 65, 30, { 198, 76, 35 })
  button("PowerToggle", "Display~Power Toggle", "On / Off", 185, 132, 140, 30, { 46, 125, 50 })

  addGroup("Input", 5, 183, 330, 68)
  button("InputVGA", "Input~VGA", "VGA", 15, 207, 95, 30, { 38, 103, 166 })
  button("InputDVI", "Input~DVI", "DVI", 120, 207, 95, 30, { 38, 103, 166 })
  button("AutoConfig", "Input~Auto Config", "Auto Config", 225, 207, 100, 30, { 38, 103, 166 })

  addGroup("Panel Buttons", 5, 258, 160, 68)
  button("Lock", "Buttons~Lock", "Lock", 15, 282, 65, 30, { 120, 83, 42 })
  button("Unlock", "Buttons~Unlock", "Unlock", 90, 282, 65, 30, { 120, 83, 42 })

  addGroup("Diagnostics", 175, 258, 160, 105)
  button("Inquiry", "Diagnostics~Inquiry", "Inquiry", 185, 282, 65, 30, { 80, 80, 80 })
  button("Firmware", "Diagnostics~Firmware", "Firmware", 260, 282, 65, 30, { 80, 80, 80 })
  button("FailureReset", "Diagnostics~Failure Reset", "Reset Failure", 185, 320, 140, 30, { 120, 83, 42 })

  addGroup("Feedback", 345, 5, 300, 358)
  local fb = {
    { "ConnectedFB", "Connected", 362, 34 },
    { "UpFB", "Up", 362, 66 },
    { "DownFB", "Down", 362, 98 },
    { "ScreenOnFB", "Screen On", 362, 130 },
    { "LockedFB", "Locked", 500, 66 },
    { "InputDVIFB", "Input DVI", 500, 98 },
    { "FailureFB", "Failure", 500, 130 }
  }
  for _, item in ipairs(fb) do
    led(item[1], item[2], item[3], item[4])
    addLabel(item[2], item[3] + 26, item[4] + 2, 82, 16)
  end

  addLabel("CB", 362, 168, 24, 16, "Right")
  textBox("ControlByte", "Control Byte", 392, 164, 72, 24)
  addLabel("FW", 470, 168, 24, 16, "Right")
  textBox("FirmwareVersion", "Firmware Version", 500, 164, 100, 24)

  addLabel("Last Tx", 362, 198, 50, 16, "Right")
  textBox("LastTx", "Last Transmitted AHnet Frame", 420, 194, 180, 24)
elseif CurrentPage == "Setup" then
  addGroup("ERT-30 Network", 5, 5, 310, 120)
  addLabel("IP", 18, 34, 66, 16, "Right")
  textBox("DeviceIP", "ERT-30 IP Address", 92, 30, 150, 24)
  addLabel("Port", 18, 68, 66, 16, "Right")
  textBox("DevicePort", "ERT-30 TCP Port", 92, 64, 72, 24)
  layout["Status"] = {
    PrettyName = "Connection Status",
    Style = "Status",
    Position = { 92, 96 },
    Size = { 200, 24 }
  }

  addGroup("Diagnostics", 325, 5, 320, 120)
  addLabel("Last Rx", 340, 34, 58, 16, "Right")
  textBox("LastRx", "Last Received AHnet Frame", 406, 30, 200, 24)
  addLabel("Last Tx", 340, 68, 58, 16, "Right")
  textBox("LastTx", "Last Transmitted AHnet Frame", 406, 64, 200, 24)
else
  local address = tonumber(string.match(CurrentPage, "Monitor (%d+)"))
  if address and address <= props["Monitor Count"].Value then
    local prefix = "Monitor" .. address
    addGroup("Monitor " .. address .. " Feedback", 5, 5, 330, 250)

    local monitorFeedback = {
      { prefix .. "OnlineFB", "Online", 22, 35 },
      { prefix .. "UpFB", "Up", 22, 70 },
      { prefix .. "DownFB", "Down", 170, 70 },
      { prefix .. "ScreenOnFB", "Screen On", 22, 105 },
      { prefix .. "InputDVIFB", "Input DVI", 170, 105 },
      { prefix .. "LockedFB", "Locked", 22, 140 },
      { prefix .. "FailureFB", "Failure", 170, 140 }
    }

    for _, item in ipairs(monitorFeedback) do
      led(item[1], "Monitor " .. address .. "~" .. item[2], item[3], item[4])
      addLabel(item[2], item[3] + 26, item[4] + 2, 88, 16)
    end

    addLabel("CB", 22, 180, 30, 16, "Right")
    textBox(prefix .. "ControlByte", "Monitor " .. address .. "~Control Byte", 60, 176, 70, 24)
    addLabel("FW", 150, 180, 30, 16, "Right")
    textBox(prefix .. "FirmwareVersion", "Monitor " .. address .. "~Firmware", 188, 176, 110, 24)
    addLabel("Last Rx", 22, 218, 52, 16, "Right")
    textBox(prefix .. "LastRx", "Monitor " .. address .. "~Last Received Frame", 82, 214, 216, 24)
  end
end
