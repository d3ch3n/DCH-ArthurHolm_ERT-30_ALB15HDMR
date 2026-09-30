-- DCH Arthur Holm ERT-30 ALB15HDMR Q-SYS Plugin

--[[ #include "info.lua" ]]

function GetColor(props)
  return { 34, 88, 122 }
end

function GetPrettyName(props)
  return "Arthur Holm ERT-30 ALB15HDMR v" .. PluginInfo.Version
end

PageNames = { "Control", "Setup" }

function GetPages(props)
  local pages = {}
  --[[ #include "pages.lua" ]]
  return pages
end

function GetModel(props)
  local model = {}
  --[[ #include "model.lua" ]]
  return model
end

function GetProperties()
  local props = {}
  --[[ #include "properties.lua" ]]
  return props
end

function GetPins(props)
  local pins = {}
  --[[ #include "pins.lua" ]]
  return pins
end

function RectifyProperties(props)
  --[[ #include "rectify_properties.lua" ]]
  return props
end

function GetComponents(props)
  local components = {}
  --[[ #include "components.lua" ]]
  return components
end

function GetWiring(props)
  local wiring = {}
  --[[ #include "wiring.lua" ]]
  return wiring
end

function GetControls(props)
  local ctrls = {}
  --[[ #include "controls.lua" ]]
  return ctrls
end

function GetControlLayout(props)
  local layout = {}
  local graphics = {}
  --[[ #include "layout.lua" ]]
  return layout, graphics
end

if Controls then
  --[[ #include "runtime.lua" ]]
end
