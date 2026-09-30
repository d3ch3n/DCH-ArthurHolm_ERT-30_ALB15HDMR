for ix, name in ipairs(PageNames) do
  table.insert(pages, { name = name })
end

for address = 1, props["Monitor Count"].Value do
  table.insert(pages, { name = "Monitor " .. address })
end
