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

local function addCommandGroups(prefix, titlePrefix)
  local function name(suffix)
    return prefix .. suffix
  end

  addGroup(titlePrefix .. "Movement", 5, 5, 160, 106)
  button(name("Up"), titlePrefix .. "Movement~Up", "Up", 15, 29, 65, 30, { 46, 125, 50 })
  button(name("Down"), titlePrefix .. "Movement~Down", "Down", 90, 29, 65, 30, { 198, 76, 35 })
  button(name("MovementToggle"), titlePrefix .. "Movement~Toggle", "Up / Down", 15, 67, 140, 30, { 46, 125, 50 })

  addGroup(titlePrefix .. "Display", 175, 5, 160, 106)
  button(name("ScreenOn"), titlePrefix .. "Display~On", "On", 185, 29, 65, 30, { 46, 125, 50 })
  button(name("ScreenOff"), titlePrefix .. "Display~Off", "Off", 260, 29, 65, 30, { 198, 76, 35 })
  button(name("PowerToggle"), titlePrefix .. "Display~Power Toggle", "On / Off", 185, 67, 140, 30, { 46, 125, 50 })

  addGroup(titlePrefix .. "Input", 5, 118, 330, 68)
  button(name("InputVGA"), titlePrefix .. "Input~VGA", "VGA", 15, 142, 95, 30, { 38, 103, 166 })
  button(name("InputDVI"), titlePrefix .. "Input~DVI", "DVI", 120, 142, 95, 30, { 38, 103, 166 })
  button(name("AutoConfig"), titlePrefix .. "Input~Auto Config", "Auto Config", 225, 142, 100, 30, { 38, 103, 166 })

  addGroup(titlePrefix .. "Panel Buttons", 5, 193, 160, 68)
  button(name("Lock"), titlePrefix .. "Buttons~Lock", "Lock", 15, 217, 65, 30, { 120, 83, 42 })
  button(name("Unlock"), titlePrefix .. "Buttons~Unlock", "Unlock", 90, 217, 65, 30, { 120, 83, 42 })

  addGroup(titlePrefix .. "Diagnostics", 175, 193, 160, 105)
  button(name("Inquiry"), titlePrefix .. "Diagnostics~Inquiry", "Inquiry", 185, 217, 65, 30, { 80, 80, 80 })
  button(name("Firmware"), titlePrefix .. "Diagnostics~Firmware", "Firmware", 260, 217, 65, 30, { 80, 80, 80 })
  button(name("FailureReset"), titlePrefix .. "Diagnostics~Failure Reset", "Reset Failure", 185, 255, 140, 30, { 120, 83, 42 })
end

if CurrentPage == "Control" then
  addCommandGroups("", "Broadcast ")
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
    addCommandGroups(prefix, "")
    addGroup("Monitor " .. address .. " Feedback", 345, 5, 300, 293)

    local monitorFeedback = {
      { prefix .. "OnlineFB", "Online", 362, 35 },
      { prefix .. "UpFB", "Up", 362, 70 },
      { prefix .. "DownFB", "Down", 500, 70 },
      { prefix .. "ScreenOnFB", "Screen On", 362, 105 },
      { prefix .. "InputDVIFB", "Input DVI", 500, 105 },
      { prefix .. "LockedFB", "Locked", 362, 140 },
      { prefix .. "FailureFB", "Failure", 500, 140 }
    }

    for _, item in ipairs(monitorFeedback) do
      led(item[1], "Monitor " .. address .. "~" .. item[2], item[3], item[4])
      addLabel(item[2], item[3] + 26, item[4] + 2, 88, 16)
    end

    addLabel("CB", 362, 180, 30, 16, "Right")
    textBox(prefix .. "ControlByte", "Monitor " .. address .. "~Control Byte", 400, 176, 70, 24)
    addLabel("FW", 480, 180, 30, 16, "Right")
    textBox(prefix .. "FirmwareVersion", "Monitor " .. address .. "~Firmware", 518, 176, 100, 24)
    addLabel("Last Rx", 362, 218, 52, 16, "Right")
    textBox(prefix .. "LastRx", "Monitor " .. address .. "~Last Received Frame", 422, 214, 196, 24)
  end
end
