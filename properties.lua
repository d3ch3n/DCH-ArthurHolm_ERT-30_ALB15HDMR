table.insert(props, {
  Name = "Debug Print",
  Type = "enum",
  Choices = { "None", "Tx/Rx", "Tx", "Rx", "Function Calls", "All" },
  Value = "None"
})

table.insert(props, {
  Name = "Default Port",
  Type = "integer",
  Min = 1,
  Max = 65535,
  Value = 2002
})

table.insert(props, {
  Name = "Poll Interval",
  Type = "integer",
  Min = 0,
  Max = 300,
  Value = 10
})
