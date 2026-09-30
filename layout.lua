local CurrentPage = PageNames[props["page_index"].Value]

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

  addGroup("Movement", 5, 70, 160, 68)
  button("Up", "Movement~Up", "Up", 15, 94, 65, 30, { 46, 125, 50 })
  button("Down", "Movement~Down", "Down", 90, 94, 65, 30, { 198, 76, 35 })

  addGroup("Display", 175, 70, 160, 68)
  button("ScreenOn", "Display~On", "On", 185, 94, 65, 30, { 46, 125, 50 })
  button("ScreenOff", "Display~Off", "Off", 260, 94, 65, 30, { 198, 76, 35 })

  addGroup("Input", 5, 145, 330, 68)
  button("InputVGA", "Input~VGA", "VGA", 15, 169, 95, 30, { 38, 103, 166 })
  button("InputDVI", "Input~DVI", "DVI", 120, 169, 95, 30, { 38, 103, 166 })
  button("AutoConfig", "Input~Auto Config", "Auto Config", 225, 169, 100, 30, { 38, 103, 166 })

  addGroup("Panel Buttons", 5, 220, 160, 68)
  button("Lock", "Buttons~Lock", "Lock", 15, 244, 65, 30, { 120, 83, 42 })
  button("Unlock", "Buttons~Unlock", "Unlock", 90, 244, 65, 30, { 120, 83, 42 })

  addGroup("Diagnostics", 175, 220, 160, 105)
  button("Inquiry", "Diagnostics~Inquiry", "Inquiry", 185, 244, 65, 30, { 80, 80, 80 })
  button("Firmware", "Diagnostics~Firmware", "Firmware", 260, 244, 65, 30, { 80, 80, 80 })
  button("FailureReset", "Diagnostics~Failure Reset", "Reset Failure", 185, 282, 140, 30, { 120, 83, 42 })

  addGroup("Feedback", 345, 5, 300, 320)
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
end
