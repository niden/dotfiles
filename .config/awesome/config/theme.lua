--[[--

  Theme handling

  Part of Awesome WM config
  by Sergey Yakovlev (me@klay.me)

--]]--

local gears = require("gears")

-- Define colours, icons, and wallpapers
beautiful.init(__dir__ .. "/themes/copyburn/theme.lua")


-- Wallpaper
if beautiful.wallpaper then
  for s = 1, screen.count() do
    gears.wallpaper.maximized(beautiful.wallpaper, s, true)
  end
end