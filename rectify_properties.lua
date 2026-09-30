if props["Default Port"].Value < 1 then
  props["Default Port"].Value = 2002
elseif props["Default Port"].Value > 65535 then
  props["Default Port"].Value = 65535
end

if props["Poll Interval"].Value < 0 then
  props["Poll Interval"].Value = 0
end
