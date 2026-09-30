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

for pageIndex, page in ipairs(pages) do
  props.page_index.Value = pageIndex
  local layout = GetControlLayout(props)
  if page.name == "Monitor 1" then
    assert(layout.Monitor1OnlineFB, "Monitor 1 page has no online indicator")
    assert(layout.Monitor1ControlByte, "Monitor 1 page has no control byte")
  elseif page.name == "Monitor 3" then
    assert(layout.Monitor3FailureFB, "Monitor 3 page has no failure indicator")
    assert(layout.Monitor3LastRx, "Monitor 3 page has no last response")
  end
end

print("plugin structure test passed")
