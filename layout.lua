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

local function button(name, pretty, x, y, w, h, color)
  layout[name] = {
    PrettyName = pretty,
    Style = "Button",
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
  addGroup("Monitor", 5, 5, 330, 225)
  addLabel("Address", 18, 34, 64, 16, "Right")
  textBox("Address", "AHnet Address", 88, 30, 46, 24)
  button("Broadcast", "Broadcast", 146, 30, 86, 24, { 96, 96, 96 })

  button("Up", "Movement~Up", 22, 68, 88, 32, { 46, 125, 50 })
  button("Down", "Movement~Down", 118, 68, 88, 32, { 198, 76, 35 })
  button("Inquiry", "Diagnostics~Inquiry", 214, 68, 88, 32, { 80, 80, 80 })

  button("ScreenOn", "Display~On", 22, 110, 88, 32, { 46, 125, 50 })
  button("ScreenOff", "Display~Off", 118, 110, 88, 32, { 198, 76, 35 })
  button("Firmware", "Diagnostics~Firmware", 214, 110, 88, 32, { 80, 80, 80 })

  button("InputVGA", "Input~VGA", 22, 152, 88, 32, { 38, 103, 166 })
  button("InputDVI", "Input~DVI", 118, 152, 88, 32, { 38, 103, 166 })
  button("AutoConfig", "Input~Auto Config", 214, 152, 88, 32, { 38, 103, 166 })

  button("Lock", "Buttons~Lock", 22, 194, 88, 24, { 120, 83, 42 })
  button("Unlock", "Buttons~Unlock", 118, 194, 88, 24, { 120, 83, 42 })
  button("FailureReset", "Diagnostics~Failure Reset", 214, 194, 88, 24, { 120, 83, 42 })

  addGroup("Feedback", 345, 5, 300, 225)
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
