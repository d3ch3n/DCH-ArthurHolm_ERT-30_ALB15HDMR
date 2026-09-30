local StatusState = { OK = 0, COMPROMISED = 1, FAULT = 2, NOTPRESENT = 3, MISSING = 4, INITIALIZING = 5 }
local EmptyIPMessage = "Enter ERT-30 IP"
local TCP = TcpSocket.New()
local PollTimer = Timer.New()
local rxBuffer = ""
local syncingToggles = false
local syncingMonitorToggles = {}
local MonitorCount = tonumber(Properties["Monitor Count"].Value) or 1

local DebugTx = false
local DebugRx = false
local DebugFunction = false
local DebugPrint = Properties["Debug Print"].Value

if DebugPrint == "Tx/Rx" then
  DebugTx, DebugRx = true, true
elseif DebugPrint == "Tx" then
  DebugTx = true
elseif DebugPrint == "Rx" then
  DebugRx = true
elseif DebugPrint == "Function Calls" then
  DebugFunction = true
elseif DebugPrint == "All" then
  DebugTx, DebugRx, DebugFunction = true, true, true
end

TCP.ReadTimeout = 0
TCP.WriteTimeout = 5
TCP.ReconnectTimeout = 5

Controls.DevicePort.String = Controls.DevicePort.String ~= "" and Controls.DevicePort.String or tostring(Properties["Default Port"].Value)
Controls.Address.String = Controls.Address.String ~= "" and Controls.Address.String or "1"
Controls.Broadcast.Boolean = true

local function reportStatus(state, message)
  Controls.Status.Value = StatusState[state]
  Controls.Status.String = message or ""
end

local function byteToHex(byte)
  return string.format("%02X", byte or 0)
end

local function frameToHex(frame)
  local out = {}
  for index = 1, #frame do
    out[#out + 1] = byteToHex(string.byte(frame, index))
  end
  return table.concat(out, " ")
end

local function hasBit(value, bitValue)
  return math.floor(value / bitValue) % 2 == 1
end

local function clampAddress(address)
  address = tonumber(address) or 1
  if address < 1 then
    return 1
  elseif address > MonitorCount then
    return MonitorCount
  end
  return math.floor(address)
end

local function getAddress()
  if Controls.Broadcast.Boolean then
    return 0xF9
  end
  local address = clampAddress(Controls.Address.String)
  Controls.Address.String = tostring(address)
  return address
end

local function connected()
  return TCP.IsConnected
end

local function writeFrame(frame)
  Controls.LastTx.String = frameToHex(frame)
  if DebugTx then print("Tx: " .. Controls.LastTx.String) end

  if connected() then
    TCP:Write(frame)
  else
    reportStatus("MISSING", "Socket disconnected")
  end
end

local function sendAHnet(command, value1, value2)
  if DebugFunction then print("sendAHnet()") end
  writeFrame(string.char(0xFA, getAddress(), command, value1 or 0x00, value2 or 0x00))
end

local function sendAHnetTo(address, command, value1, value2)
  writeFrame(string.char(0xFA, address, command, value1 or 0x00, value2 or 0x00))
end

local function monitorControl(address, suffix)
  return Controls["Monitor" .. address .. suffix]
end

local function setMonitorBoolean(address, suffix, value)
  local control = monitorControl(address, suffix)
  if control then control.Boolean = value end
end

local function setMonitorString(address, suffix, value)
  local control = monitorControl(address, suffix)
  if control then control.String = value end
end

local function isSelectedAddress(address)
  return not Controls.Broadcast.Boolean
    and address == clampAddress(Controls.Address.String)
end

local function syncToggleStates()
  syncingToggles = true
  Controls.MovementToggle.Boolean = Controls.UpFB.Boolean
  Controls.PowerToggle.Boolean = Controls.ScreenOnFB.Boolean
  syncingToggles = false
end

local function setFeedbackFromControlByte(cb1)
  Controls.ControlByte.String = byteToHex(cb1)
  Controls.UpFB.Boolean = hasBit(cb1, 0x01)
  Controls.DownFB.Boolean = hasBit(cb1, 0x02)
  Controls.ScreenOnFB.Boolean = hasBit(cb1, 0x04)
  Controls.LockedFB.Boolean = hasBit(cb1, 0x08)
  Controls.InputDVIFB.Boolean = hasBit(cb1, 0x10)
  Controls.FailureFB.Boolean = hasBit(cb1, 0x20)
  syncToggleStates()
end

local function setMonitorFeedbackFromControlByte(address, cb1)
  setMonitorString(address, "ControlByte", byteToHex(cb1))
  setMonitorBoolean(address, "UpFB", hasBit(cb1, 0x01))
  setMonitorBoolean(address, "DownFB", hasBit(cb1, 0x02))
  setMonitorBoolean(address, "ScreenOnFB", hasBit(cb1, 0x04))
  setMonitorBoolean(address, "LockedFB", hasBit(cb1, 0x08))
  setMonitorBoolean(address, "InputDVIFB", hasBit(cb1, 0x10))
  setMonitorBoolean(address, "FailureFB", hasBit(cb1, 0x20))
  syncingMonitorToggles[address] = true
  setMonitorBoolean(address, "MovementToggle", hasBit(cb1, 0x01))
  setMonitorBoolean(address, "PowerToggle", hasBit(cb1, 0x04))
  syncingMonitorToggles[address] = false
end

local function parseFrame(frame)
  local b0, address, command, value1, value2 = string.byte(frame, 1, 5)
  Controls.LastRx.String = frameToHex(frame)
  if DebugRx then print("Rx: " .. Controls.LastRx.String) end

  if b0 ~= 0xFB then
    reportStatus("COMPROMISED", "Unexpected response")
    return
  end

  reportStatus("OK", "AHnet response from " .. tostring(address))
  if address >= 1 and address <= MonitorCount then
    setMonitorBoolean(address, "OnlineFB", true)
    setMonitorString(address, "LastRx", Controls.LastRx.String)
  end

  if command == 0x14 then
    setMonitorFeedbackFromControlByte(address, value1)
    if isSelectedAddress(address) then setFeedbackFromControlByte(value1) end
  elseif command == 0x15 then
    local version = byteToHex(value1) .. "." .. byteToHex(value2)
    setMonitorString(address, "FirmwareVersion", version)
    if isSelectedAddress(address) then Controls.FirmwareVersion.String = version end
  elseif command == 0x01 then
    setMonitorBoolean(address, "UpFB", value1 == 0x01)
    setMonitorBoolean(address, "DownFB", value1 == 0x00)
    syncingMonitorToggles[address] = true
    setMonitorBoolean(address, "MovementToggle", value1 == 0x01)
    syncingMonitorToggles[address] = false
    if isSelectedAddress(address) then
      Controls.UpFB.Boolean = value1 == 0x01
      Controls.DownFB.Boolean = value1 == 0x00
      syncToggleStates()
    end
  elseif command == 0x02 then
    setMonitorBoolean(address, "ScreenOnFB", value1 == 0x01)
    syncingMonitorToggles[address] = true
    setMonitorBoolean(address, "PowerToggle", value1 == 0x01)
    syncingMonitorToggles[address] = false
    if isSelectedAddress(address) then
      Controls.ScreenOnFB.Boolean = value1 == 0x01
      syncToggleStates()
    end
  elseif command == 0x03 then
    setMonitorBoolean(address, "InputDVIFB", value1 == 0x00)
    if isSelectedAddress(address) then Controls.InputDVIFB.Boolean = value1 == 0x00 end
  elseif command == 0x04 then
    setMonitorBoolean(address, "LockedFB", value1 == 0x01)
    if isSelectedAddress(address) then Controls.LockedFB.Boolean = value1 == 0x01 end
  elseif command == 0x13 then
    setMonitorBoolean(address, "FailureFB", false)
    if isSelectedAddress(address) then Controls.FailureFB.Boolean = false end
  end
end

local function parseResponse()
  if TCP.BufferLength and TCP.BufferLength > 0 then
    rxBuffer = rxBuffer .. TCP:Read(TCP.BufferLength)
  end

  while #rxBuffer >= 5 do
    local start = string.find(rxBuffer, string.char(0xFB), 1, true)
    if not start then
      rxBuffer = ""
      return
    elseif start > 1 then
      rxBuffer = string.sub(rxBuffer, start)
    end

    if #rxBuffer >= 5 then
      local frame = string.sub(rxBuffer, 1, 5)
      rxBuffer = string.sub(rxBuffer, 6)
      parseFrame(frame)
    end
  end
end

local function pollDevice()
  if tonumber(Properties["Poll Interval"].Value) > 0 and connected() then
    for address = 1, MonitorCount do
      setMonitorBoolean(address, "OnlineFB", false)
      sendAHnetTo(address, 0x14, 0x00, 0x00)
    end
  end
end

local function setAllMonitorsOffline()
  for address = 1, MonitorCount do
    setMonitorBoolean(address, "OnlineFB", false)
  end
end

local function disconnect()
  PollTimer:Stop()
  Controls.ConnectedFB.Boolean = false
  setAllMonitorsOffline()
  if connected() then
    TCP:Disconnect()
  end
end

local function connect()
  local ip = Controls.DeviceIP.String
  local port = tonumber(Controls.DevicePort.String) or Properties["Default Port"].Value

  if ip == "" or ip == EmptyIPMessage then
    reportStatus("MISSING", EmptyIPMessage)
    return
  end

  reportStatus("INITIALIZING", "Connecting")
  if DebugFunction then print("Connecting to " .. ip .. ":" .. tostring(port)) end
  TCP:Connect(ip, port)
end

TCP.Connected = function()
  Controls.ConnectedFB.Boolean = true
  reportStatus("OK", "Connected")
  if tonumber(Properties["Poll Interval"].Value) > 0 then
    PollTimer:Start(Properties["Poll Interval"].Value)
  end
  pollDevice()
  for address = 1, MonitorCount do
    sendAHnetTo(address, 0x15, 0x00, 0x00)
  end
end

TCP.Reconnect = function()
  Controls.ConnectedFB.Boolean = false
  setAllMonitorsOffline()
  reportStatus("INITIALIZING", "Reconnecting")
end

TCP.Closed = function()
  Controls.ConnectedFB.Boolean = false
  setAllMonitorsOffline()
  reportStatus("MISSING", "Socket closed")
  PollTimer:Stop()
end

TCP.Error = function()
  Controls.ConnectedFB.Boolean = false
  setAllMonitorsOffline()
  reportStatus("MISSING", "Socket error")
  PollTimer:Stop()
end

TCP.Timeout = function()
  Controls.ConnectedFB.Boolean = false
  setAllMonitorsOffline()
  reportStatus("MISSING", "Socket timeout")
  PollTimer:Stop()
end

TCP.Data = parseResponse
PollTimer.EventHandler = pollDevice

Controls.DeviceIP.EventHandler = function()
  disconnect()
  connect()
end

Controls.DevicePort.EventHandler = function()
  disconnect()
  connect()
end

Controls.Address.EventHandler = function()
  Controls.Address.String = tostring(clampAddress(Controls.Address.String))
end

Controls.Broadcast.EventHandler = function(ctrl)
  if ctrl.Boolean then
    reportStatus("OK", "Broadcast address F9")
  else
    pollDevice()
  end
end

Controls.MovementToggle.EventHandler = function(ctrl)
  if not syncingToggles then
    sendAHnetTo(0xF9, 0x01, ctrl.Boolean and 0x01 or 0x00, 0x00)
  end
end

Controls.PowerToggle.EventHandler = function(ctrl)
  if not syncingToggles then
    sendAHnetTo(0xF9, 0x02, ctrl.Boolean and 0x01 or 0x00, 0x00)
  end
end

local function onPress(handler)
  return function(ctrl)
    if ctrl.Boolean then
      handler()
    end
  end
end

Controls.Up.EventHandler = onPress(function() sendAHnetTo(0xF9, 0x01, 0x01, 0x00) end)
Controls.Down.EventHandler = onPress(function() sendAHnetTo(0xF9, 0x01, 0x00, 0x00) end)
Controls.ScreenOn.EventHandler = onPress(function() sendAHnetTo(0xF9, 0x02, 0x01, 0x00) end)
Controls.ScreenOff.EventHandler = onPress(function() sendAHnetTo(0xF9, 0x02, 0x00, 0x00) end)
Controls.InputVGA.EventHandler = onPress(function() sendAHnetTo(0xF9, 0x03, 0x01, 0x00) end)
Controls.InputDVI.EventHandler = onPress(function() sendAHnetTo(0xF9, 0x03, 0x00, 0x00) end)
Controls.Lock.EventHandler = onPress(function() sendAHnetTo(0xF9, 0x04, 0x01, 0x00) end)
Controls.Unlock.EventHandler = onPress(function() sendAHnetTo(0xF9, 0x04, 0x00, 0x00) end)
Controls.AutoConfig.EventHandler = onPress(function() sendAHnetTo(0xF9, 0x05, 0x00, 0x00) end)
Controls.FailureReset.EventHandler = onPress(function() sendAHnetTo(0xF9, 0x13, 0x00, 0x00) end)
Controls.Inquiry.EventHandler = onPress(function() sendAHnetTo(0xF9, 0x14, 0x00, 0x00) end)
Controls.Firmware.EventHandler = onPress(function() sendAHnetTo(0xF9, 0x15, 0x00, 0x00) end)

local monitorCommands = {
  Up = { 0x01, 0x01, 0x00 },
  Down = { 0x01, 0x00, 0x00 },
  ScreenOn = { 0x02, 0x01, 0x00 },
  ScreenOff = { 0x02, 0x00, 0x00 },
  InputVGA = { 0x03, 0x01, 0x00 },
  InputDVI = { 0x03, 0x00, 0x00 },
  Lock = { 0x04, 0x01, 0x00 },
  Unlock = { 0x04, 0x00, 0x00 },
  AutoConfig = { 0x05, 0x00, 0x00 },
  FailureReset = { 0x13, 0x00, 0x00 },
  Inquiry = { 0x14, 0x00, 0x00 },
  Firmware = { 0x15, 0x00, 0x00 }
}

for address = 1, MonitorCount do
  local monitorAddress = address
  local prefix = "Monitor" .. monitorAddress

  Controls[prefix .. "MovementToggle"].EventHandler = function(ctrl)
    if not syncingMonitorToggles[monitorAddress] then
      sendAHnetTo(monitorAddress, 0x01, ctrl.Boolean and 0x01 or 0x00, 0x00)
    end
  end

  Controls[prefix .. "PowerToggle"].EventHandler = function(ctrl)
    if not syncingMonitorToggles[monitorAddress] then
      sendAHnetTo(monitorAddress, 0x02, ctrl.Boolean and 0x01 or 0x00, 0x00)
    end
  end

  for suffix, frame in pairs(monitorCommands) do
    local commandSuffix = suffix
    local commandFrame = frame
    Controls[prefix .. commandSuffix].EventHandler = onPress(function()
      sendAHnetTo(monitorAddress, commandFrame[1], commandFrame[2], commandFrame[3])
    end)
  end
end

connect()
