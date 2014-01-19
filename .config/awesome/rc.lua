---------------------------------------------------
-- Awesome WM config
-- by Sergey Yakovlev (me@klay.me)
---------------------------------------------------

-- {{{ Libraries
-- Standart Awesome libs
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Mouse finder
local mousefinder = require("awful.mouse.finder")()
-- Widgets and layout library
local wibox = require("wibox")
-- Vicious widget library
local vicious = require("vicious")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
-- Menu
local menubar = require("menubar")
-- Power management
local power = require("power")
-- }}}

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Defaults
terminal    = "urxvtc"
editor      = os.getenv("EDITOR") or "vim"
editor_cmd  = terminal .. " -e " .. editor
browser     = "chromium"
screensaver = "xscreensaver-command -activate"
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init(awful.util.getdir("config") .. "/themes/copyburn/theme.lua")

-- My widget lib
local widgets = require("widgets")

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.floating,         --  1
    awful.layout.suit.tile,             --  2
    awful.layout.suit.tile.left,        --  3
    awful.layout.suit.tile.bottom,      --  4
    awful.layout.suit.tile.top,         --  5
    awful.layout.suit.fair,             --  6
    awful.layout.suit.fair.horizontal,  --  7
    awful.layout.suit.spiral,           --  8
    awful.layout.suit.spiral.dwindle,   --  9
    awful.layout.suit.max,              -- 10
    awful.layout.suit.max.fullscreen,   -- 11
    awful.layout.suit.magnifier         -- 12
}
-- }}}

-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {
    -- Impractical in the tag names use words because they will spend valuable panel space
    names   = {
        "一",   -- Main
        "二",   -- WWW
        "三",   -- IM (eg. Pidgin)
        "四",   -- Media
        "五",   -- Gimp
        "六",   -- Develop (eg. any Java based IDE)
        "七",   -- Files
        "八",   -- Office
        "九"    -- Misc
    },
    layout  = {
        layouts[4],
        layouts[10], -- fullscreen for browsers
        layouts[2],
        layouts[6],
        layouts[10], -- fullscreen for Gimp (I use single windows mode)
        layouts[10], -- fullscreen for IDEs
        layouts[2],
        layouts[10], -- fullscreen for Libre Office
        layouts[2]
    }
}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag( tags.names, s, tags.layout )
    -- Individual clients settings for tags
    -- IM (eg. Pidgin)
    awful.tag.setncol(2, tags[s][3])
    awful.tag.setproperty(tags[s][3], "mwfact", 0.20)

end
-- }}}

-- {{{ Menu
local awesome_menu = {
   { "&Manual",  terminal .. " -e man awesome"         },
   { "&Config",  editor_cmd .. " " .. awesome.conffile },
   { "&Restart", awesome.restart                       },
   { "&Quit",    awesome.quit                          }
}

local develop_menu = {
    { "&PhpStorm",       "/opt/phpstorm/bin/phpstorm.sh" },
    { "&Sublime Text 3", "subl3"                         },
    { "&Vim",            editor_cmd                      }
}

local www_menu = {
    { "&Chromium",     "chromium"         },
    { "&Firefox",      "firefox"          },
    { "&Pidgin",       "pidgin"           },
    { "&Transmission", "transmission-gtk" }
}

local power_menu = {
    { "&Lock Screen", power.screensaver },
    { "&Suspend",     power.suspend     },
    { "&Hibernate",   power.hibernate   },
    { "Sl&eep",       power.sleep       },
    { "&Reboot",      power.reboot      },
    { "&Power Off",   power.poweroff    }
}

-- Create a main menu
mainmenu = awful.menu(
    { items =
        {
            { "&Develop",  develop_menu },
            { "&Internet", www_menu     },
            { "&Awesome",  awesome_menu },
            { "&Power",    power_menu   }
        }
    })

-- Create a laucher widget
launcher = awful.widget.launcher({
    image = beautiful.awesome_icon,
    menu  = mainmenu
})

-- Menubar configuration.
-- Set the terminal for applications that require it
menubar.utils.terminal = terminal
-- }}}

-- {{{ Wibox

-- Create a textclock widget
textclock = awful.widget.textclock(" %H:%M ")

-- Create a wibox for each screen and add it
wiboxes   = {}
wiboxes2  = {}
promptbox = {}
layoutbox = {}

taglist   = {}
taglist.buttons = awful.util.table.join(
        awful.button({        }, 1, awful.tag.viewonly),
        awful.button({ modkey }, 1, awful.client.movetotag),
        awful.button({        }, 3, awful.tag.viewtoggle),
        awful.button({ modkey }, 3, awful.client.toggletag),
        awful.button({        }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
        awful.button({        }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
)

tasklist  = {}
tasklist.buttons = awful.util.table.join(
        awful.button({ }, 1, function (c)
            if c == client.focus then
                c.minimized = true
            else
            -- Without this, the following
            -- :isvisible() makes no sense
                c.minimized = false
                if not c:isvisible() then
                    awful.tag.viewonly(c:tags()[1])
                end
                -- This will also un-minimize
                -- the client, if needed
                client.focus = c
                c:raise()
            end
        end),

        awful.button({ }, 3, function ()
            if instance then
                instance:hide()
                instance = nil
            else
                instance = awful.menu.clients({ width=250 })
            end
        end),

        awful.button({ }, 4, function ()
            awful.client.focus.byidx(1)
            if client.focus then client.focus:raise() end
        end),

        awful.button({ }, 5, function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end)
)

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    promptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    layoutbox[s] = awful.widget.layoutbox(s)
    layoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    taglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist.buttons)

    -- Create a tasklist widget
    tasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist.buttons)

    -- Create the top wibox
    wiboxes[s] = awful.wibox({ position = "top", height="14", screen = s })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(launcher)
    left_layout:add(widgets.spacer)
    left_layout:add(taglist[s])
    left_layout:add(promptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    right_layout:add(widgets.volicon)
    right_layout:add(widgets.volwidget)
    right_layout:add(widgets.separator)
    if s == 1 then right_layout:add(wibox.widget.systray()) end   
    right_layout:add(widgets.separator)
    right_layout:add(textclock)
    right_layout:add(widgets.separator)
    right_layout:add(layoutbox[s])

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(tasklist[s])
    layout:set_right(right_layout)

    wiboxes[s]:set_widget(layout)

    -- Create the bottom wibox
    wiboxes2[s] = awful.wibox({ position = "bottom", height="14", screen = s })

    -- Widgets that are aligned to the left
    local left_layout2 = wibox.layout.fixed.horizontal()

    -- Widgets that are aligned to the right
    local right_layout2 = wibox.layout.fixed.horizontal()
    left_layout2:add(widgets.spacer)
    left_layout2:add(widgets.syswidget)
    left_layout2:add(widgets.separator)
    left_layout2:add(widgets.pkgicon)
    left_layout2:add(widgets.pkgwidget)
    left_layout2:add(widgets.separator)
    left_layout2:add(widgets.gmailicon)
    left_layout2:add(widgets.gmailwidget)
    left_layout2:add(widgets.separator)

    right_layout2:add(widgets.separator)
    right_layout2:add(widgets.ramicon)
    right_layout2:add(widgets.ramwidget)
    right_layout2:add(widgets.separator)
    right_layout2:add(widgets.cpuicon)
    right_layout2:add(widgets.cpuwidget1)
    right_layout2:add(widgets.separator)
    right_layout2:add(widgets.cpuicon)
    right_layout2:add(widgets.cpuwidget2)
    right_layout2:add(widgets.separator)
    right_layout2:add(widgets.batticon)
    right_layout2:add(widgets.battwidget)
    right_layout2:add(widgets.separator)
    right_layout2:add(widgets.mpdicon)
    right_layout2:add(widgets.mpdwidget)
    right_layout2:add(widgets.spacer)

    -- Now bring it all together (with the tasklist in the middle)
    local layout2 = wibox.layout.align.horizontal()
    layout2:set_left(left_layout2)
    layout2:set_right(right_layout2)

    wiboxes2[s]:set_widget(layout2)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mainmenu:show() end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Mouse finder
    awful.key({ modkey,           }, "g" , function () mousefinder.find(mousefinder) end),

    --awful.key({ modkey, }, "p", function()
    --    awful.util.spawn_with_shell("xclip -o | xclip -i -selection clipboard")
    --end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({                   }, "Print",
        function ()
            awful.util.spawn("scrot -e 'mv $f /home/media/pictures/screnshots/ 2>/dev/null'")
        end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "r",     function () promptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  promptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),
    -- Menubar
    awful.key({ modkey            }, "p",     function() menubar.show() end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.movetotag(tag)
                          end
                     end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.toggletag(tag)
                          end
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { tag = tags[1][5] } }, -- I use single windiw mode
    { rule = { class = "Firefox" },
      properties = { tag = tags[1][2] } },
    { rule = { class = "Chromium" },
      properties = { tag = tags[1][2] } },
    { rule = { class = "jetbrains-phpstorm" },
      properties = { tag = tags[1][6] } },
    { rule = { class = "Pidgin", role = "buddy_list" },
      properties = { tag = tags[1][3] } },
    { rule = { class = "Pidgin", role = "conversation" },
      properties = { tag = tags[1][3], callback = awful.client.setslave } }
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
