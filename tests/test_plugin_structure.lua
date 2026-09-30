local pluginPath = arg[1] or "DCH-ArthurHolm_ERT-30_ALB15HDMR.qplug"
dofile(pluginPath)

local props = { page_index = { Value = 1 } }
for _, property in ipairs(GetProperties()) do
  props[property.Name] = { Value = property.Value }
end

props["Monitor Count"].Value = 3
RectifyProperties(props)

local pages = GetPages(props)
assert(#pages == 5, "expected Control, Setup and three monitor pages")
assert(pages[3].name == "Monitor 1", "missing Monitor 1 page")
assert(pages[5].name == "Monitor 3", "missing Monitor 3 page")

local controlNames = {}
for _, control in ipairs(GetControls(props)) do
  controlNames[control.Name] = true
end
assert(controlNames.Monitor1OnlineFB, "missing Monitor 1 online feedback")
assert(controlNames.Monitor3LastRx, "missing Monitor 3 last response")
assert(controlNames.Monitor1MovementToggle, "missing Monitor 1 movement toggle")
assert(controlNames.Monitor3ScreenOn, "missing Monitor 3 screen-on command")

for pageIndex, page in ipairs(pages) do
  props.page_index.Value = pageIndex
  local layout = GetControlLayout(props)
  if page.name == "Control" then
    assert(layout.Up, "broadcast page has no movement command")
    assert(layout.PowerToggle, "broadcast page has no power toggle")
    assert(not layout.Address, "broadcast page should not expose an address")
  elseif page.name == "Monitor 1" then
    assert(layout.Monitor1OnlineFB, "Monitor 1 page has no online indicator")
    assert(layout.Monitor1ControlByte, "Monitor 1 page has no control byte")
    assert(layout.Monitor1Up, "Monitor 1 page has no individual up command")
    assert(layout.Monitor1PowerToggle, "Monitor 1 page has no power toggle")
  elseif page.name == "Monitor 3" then
    assert(layout.Monitor3FailureFB, "Monitor 3 page has no failure indicator")
    assert(layout.Monitor3LastRx, "Monitor 3 page has no last response")
  end
end

print("plugin structure test passed")
