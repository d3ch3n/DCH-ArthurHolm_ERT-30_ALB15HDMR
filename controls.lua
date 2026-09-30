table.insert(ctrls, {
  Name = "Status",
  ControlType = "Indicator",
  IndicatorType = "Status",
  Count = 1,
  UserPin = true,
  PinStyle = "Output"
})

table.insert(ctrls, {
  Name = "DeviceIP",
  ControlType = "Text",
  Count = 1,
  UserPin = false,
  PinStyle = "none"
})

table.insert(ctrls, {
  Name = "DevicePort",
  ControlType = "Text",
  Count = 1,
  UserPin = false,
  PinStyle = "none"
})

table.insert(ctrls, {
  Name = "Address",
  ControlType = "Text",
  Count = 1,
  UserPin = true,
  PinStyle = "Both"
})

table.insert(ctrls, {
  Name = "Broadcast",
  ControlType = "Button",
  ButtonType = "Toggle",
  Count = 1,
  UserPin = true,
  PinStyle = "Both"
})

for _, name in ipairs({ "MovementToggle", "PowerToggle" }) do
  table.insert(ctrls, {
    Name = name,
    ControlType = "Button",
    ButtonType = "Toggle",
    Count = 1,
    UserPin = true,
    PinStyle = "Both"
  })
end

local commandButtons = {
  "Up",
  "Down",
  "ScreenOn",
  "ScreenOff",
  "InputVGA",
  "InputDVI",
  "Lock",
  "Unlock",
  "AutoConfig",
  "FailureReset",
  "Inquiry",
  "Firmware"
}

for _, name in ipairs(commandButtons) do
  table.insert(ctrls, {
    Name = name,
    ControlType = "Button",
    ButtonType = "Momentary",
    Count = 1,
    UserPin = true,
    PinStyle = "Both"
  })
end

local indicators = {
  "UpFB",
  "DownFB",
  "ScreenOnFB",
  "LockedFB",
  "InputDVIFB",
  "FailureFB",
  "ConnectedFB"
}

for _, name in ipairs(indicators) do
  table.insert(ctrls, {
    Name = name,
    ControlType = "Indicator",
    IndicatorType = "Led",
    Count = 1,
    UserPin = true,
    PinStyle = "Output"
  })
end

for _, name in ipairs({ "LastTx", "LastRx", "ControlByte", "FirmwareVersion" }) do
  table.insert(ctrls, {
    Name = name,
    ControlType = "Text",
    Count = 1,
    UserPin = false,
    PinStyle = "none"
  })
end

local monitorCount = props["Monitor Count"].Value
local monitorIndicators = {
  "OnlineFB",
  "UpFB",
  "DownFB",
  "ScreenOnFB",
  "LockedFB",
  "InputDVIFB",
  "FailureFB"
}

for address = 1, monitorCount do
  for _, suffix in ipairs({ "MovementToggle", "PowerToggle" }) do
    table.insert(ctrls, {
      Name = "Monitor" .. address .. suffix,
      ControlType = "Button",
      ButtonType = "Toggle",
      Count = 1,
      UserPin = true,
      PinStyle = "Both"
    })
  end

  for _, suffix in ipairs(commandButtons) do
    table.insert(ctrls, {
      Name = "Monitor" .. address .. suffix,
      ControlType = "Button",
      ButtonType = "Momentary",
      Count = 1,
      UserPin = true,
      PinStyle = "Both"
    })
  end

  for _, suffix in ipairs(monitorIndicators) do
    table.insert(ctrls, {
      Name = "Monitor" .. address .. suffix,
      ControlType = "Indicator",
      IndicatorType = "Led",
      Count = 1,
      UserPin = true,
      PinStyle = "Output"
    })
  end

  for _, suffix in ipairs({ "ControlByte", "FirmwareVersion", "LastRx" }) do
    table.insert(ctrls, {
      Name = "Monitor" .. address .. suffix,
      ControlType = "Text",
      Count = 1,
      UserPin = true,
      PinStyle = "Output"
    })
  end
end
