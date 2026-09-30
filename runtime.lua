local StatusState = { OK = 0, COMPROMISED = 1, FAULT = 2, NOTPRESENT = 3, MISSING = 4, INITIALIZING = 5 }
local EmptyIPMessage = "Enter ERT-30 IP"
local TCP = TcpSocket.New()
local PollTimer = Timer.New()
local rxBuffer = ""

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

TCP.ReadTimeout = 5
TCP.WriteTimeout = 5
TCP.ReconnectTimeout = 5

Controls.DevicePort.String = Controls.DevicePort.String ~= "" and Controls.DevicePort.String or tostring(Properties["Default Port"].Value)
Controls.Address.String = Controls.Address.String ~= "" and Controls.Address.String or "1"

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
  elseif address > 30 then
    return 30
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

local function setFeedbackFromControlByte(cb1)
  Controls.ControlByte.String = byteToHex(cb1)
  Controls.UpFB.Boolean = hasBit(cb1, 0x01)
  Controls.DownFB.Boolean = hasBit(cb1, 0x02)
  Controls.ScreenOnFB.Boolean = hasBit(cb1, 0x04)
  Controls.LockedFB.Boolean = hasBit(cb1, 0x08)
  Controls.InputDVIFB.Boolean = hasBit(cb1, 0x10)
  Controls.FailureFB.Boolean = hasBit(cb1, 0x20)
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

  if command == 0x14 then
    setFeedbackFromControlByte(value1)
  elseif command == 0x15 then
    Controls.FirmwareVersion.String = byteToHex(value1) .. "." .. byteToHex(value2)
  elseif command == 0x01 then
    Controls.UpFB.Boolean = value1 == 0x01
    Controls.DownFB.Boolean = value1 == 0x00
  elseif command == 0x02 then
    Controls.ScreenOnFB.Boolean = value1 == 0x01
  elseif command == 0x03 then
    Controls.InputDVIFB.Boolean = value1 == 0x00
  elseif command == 0x04 then
    Controls.LockedFB.Boolean = value1 == 0x01
  elseif command == 0x13 then
    Controls.FailureFB.Boolean = false
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
  if tonumber(Properties["Poll Interval"].Value) > 0 and connected() and not Controls.Broadcast.Boolean then
    sendAHnet(0x14, 0x00, 0x00)
  end
end

local function disconnect()
  PollTimer:Stop()
  Controls.ConnectedFB.Boolean = false
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
end

TCP.Reconnect = function()
  Controls.ConnectedFB.Boolean = false
  reportStatus("INITIALIZING", "Reconnecting")
end

TCP.Closed = function()
  Controls.ConnectedFB.Boolean = false
  reportStatus("MISSING", "Socket closed")
  PollTimer:Stop()
end

TCP.Error = function()
  Controls.ConnectedFB.Boolean = false
  reportStatus("MISSING", "Socket error")
  PollTimer:Stop()
end

TCP.Timeout = function()
  Controls.ConnectedFB.Boolean = false
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

local function onPress(handler)
  return function(ctrl)
    if ctrl.Boolean then
      handler()
    end
  end
end

Controls.Up.EventHandler = onPress(function() sendAHnet(0x01, 0x01, 0x00) end)
Controls.Down.EventHandler = onPress(function() sendAHnet(0x01, 0x00, 0x00) end)
Controls.ScreenOn.EventHandler = onPress(function() sendAHnet(0x02, 0x01, 0x00) end)
Controls.ScreenOff.EventHandler = onPress(function() sendAHnet(0x02, 0x00, 0x00) end)
Controls.InputVGA.EventHandler = onPress(function() sendAHnet(0x03, 0x01, 0x00) end)
Controls.InputDVI.EventHandler = onPress(function() sendAHnet(0x03, 0x00, 0x00) end)
Controls.Lock.EventHandler = onPress(function() sendAHnet(0x04, 0x01, 0x00) end)
Controls.Unlock.EventHandler = onPress(function() sendAHnet(0x04, 0x00, 0x00) end)
Controls.AutoConfig.EventHandler = onPress(function() sendAHnet(0x05, 0x00, 0x00) end)
Controls.FailureReset.EventHandler = onPress(function() sendAHnet(0x13, 0x00, 0x00) end)
Controls.Inquiry.EventHandler = onPress(function() sendAHnet(0x14, 0x00, 0x00) end)
Controls.Firmware.EventHandler = onPress(function() sendAHnet(0x15, 0x00, 0x00) end)

connect()
