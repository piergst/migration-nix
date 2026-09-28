
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- Hyprland config, ported from the old i3 setup.        --
-- See https://wiki.hypr.land/Configuring/ for reference. --
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --


------------------
---- MONITORS ----
------------------

-- Fallback: whatever is plugged, use its preferred mode/position, auto scale.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- Layout des ecrans + repartition des workspaces : generes par nwg-displays
-- (GUI), ne pas editer a la main. Pour changer la disposition : lancer
-- `nwg-displays`, deplacer les ecrans, "Apply", puis sauver un profil.
-- Voir NOTES.md, section "Ecrans multiples".
require("monitors")
require("workspaces")

-- Auto-switch du profil ecran au branchement/debranchement.
-- Les profils vivent dans ~/.config/nwg-displays/profiles/<nom>.json ; on
-- choisit ici lequel appliquer selon le nombre d'ecrans detectes. Un profil
-- absent est ignore silencieusement (nwg-displays-apply sortirait en erreur).
local function profile_for_current_screens()
    local count = #hl.get_monitors()
    if count >= 3 then
        return "m3"
    elseif count == 2 then
        return "m2"
    end
    return "laptop"
end

local function apply_screen_profile()
    local name = profile_for_current_screens()
    local path = os.getenv("HOME") .. "/.config/nwg-displays/profiles/" .. name .. ".json"
    local f = io.open(path, "r")
    if not f then
        return
    end
    f:close()
    hl.exec_cmd("nwg-displays-apply -p " .. name)
end

hl.on("monitor.added", apply_screen_profile)
hl.on("monitor.removed", apply_screen_profile)


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "alacritty"
local fileManager  = "nautilus"
local menu        = "wofi --show drun --allow-images"
local browser     = "firefox"


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function ()
    -- Status bar (configured/managed through its own settings UI)
    hl.exec_cmd("wayle panel start")

    -- Window switcher / overview
    hl.exec_cmd("hyprshell run")

    -- Notifications
    hl.exec_cmd("dunst")

    -- Clipboard history (replaces clipmenud)
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Wallpaper (replaces xwallpaper, awww is the swww successor)
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("sleep 1 && awww img ~/Pictures/wallpapers/trees.png --resize crop")

    -- Idle / lock / DPMS daemon (replaces xset s off / -dpms)
    -- Deferred: needs pkgs.hypridle, not installed yet (deprioritized for now)
    -- hl.exec_cmd("hypridle")

    -- Tray applet for NetworkManager
    hl.exec_cmd("nm-applet")

    -- Keyboard repeat rate is set declaratively below (input.repeat_rate/delay),
    -- no need for `xset r rate` anymore.

    -- Startup layout, mirrors the old i3 exec block
    hl.dispatch(hl.dsp.exec_cmd_on_workspace({ workspace = 1, cmd = terminal }))
    hl.dispatch(hl.dsp.exec_cmd_on_workspace({ workspace = 6, cmd = browser }))
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 20,

        border_size = 2,

        col = {
            -- Catppuccin Mocha blue, matches the wofi theme
            active_border   = "rgba(89b4faee)",
            inactive_border = "rgba(45475aaa)",
        },

        resize_on_border = false,
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Default curves and animations
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })

hl.config({
    dwindle = {
        preserve_split = true,
    },
})

hl.config({
    master = {
        new_status = "master",
    },
})

hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})

hl.config({
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = false,
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        -- Both layouts loaded; mainMod+q / mainMod+a switch between them
        -- (see KEYBINDINGS), same physical keys as the old i3 bindcode setup.
        kb_layout  = "fr,us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity  = 0,

        -- Old: xset r rate 200 55 (200ms delay, 55 repeats/sec)
        repeat_rate  = 55,
        repeat_delay = 200,

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

-- Core apps
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + G",      hl.dsp.window.close())                                  -- was $mod+g kill
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + D",      hl.dsp.exec_cmd(menu))                                  -- was rofi -show drun
hl.bind(mainMod .. " + M",      hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"))

-- Clipboard history (was $mod+c clipmenu)
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("cliphist list | wofi --dmenu --allow-images | cliphist decode | wl-copy"))

-- Screenshot (was $mod+Shift+s flameshot gui)
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | satty --filename - --output-filename $HOME/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"))

-- Lock screen
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.exec_cmd("hyprlock"))

-- Keyboard layout switch on the same physical keys as before (fr='q' pos, us='a' pos)
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("hyprctl switchxkblayout all 0"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("hyprctl switchxkblayout all 1"))

-- Floating / pseudotile
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())                                  -- was $mod+f fullscreen toggle
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))                                -- dwindle only

-- Focus with hjkl (vim-style, wasn't in the autogenerated default) + arrows
hl.bind(mainMod .. " + h",    hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + j",    hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + k",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + l",    hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Move focused window with hjkl/arrows + SHIFT
hl.bind(mainMod .. " + SHIFT + h",    hl.dsp.window.move_into_direction({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + j",    hl.dsp.window.move_into_direction({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + k",    hl.dsp.window.move_into_direction({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + l",    hl.dsp.window.move_into_direction({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move_into_direction({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move_into_direction({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move_into_direction({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move_into_direction({ direction = "down" }))

-- Workspaces on physical top-row keys regardless of layout (was bindcode 10..19).
-- Les codes 20 et 21 sont les deux touches apres le "0", soit ")" et "=" en
-- AZERTY -> workspaces 11 et 12 (ceux de l'ecran du laptop).
for i = 1, 12 do
    local code = 9 + i
    hl.bind(mainMod .. " + code:" .. code,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + code:" .. code, hl.dsp.window.move({ workspace = i }))
end

-- Back and forth between the last two workspaces (was $mod+Tab)
hl.bind(mainMod .. " + Tab", hl.dsp.workspace.previous())

-- Move focused window / whole workspace to the monitor left/right
-- (was $mod+Shift+p/o move container, $mod+Shift+i/u move workspace)
--
-- L'API est `.move({ monitor = ... })`, PAS `.move_to_monitor({ direction })`
-- qui n'existe pas (verifie par introspection de hl.dsp).
-- "l"/"r" sont des selecteurs relatifs d'Hyprland : ils suivent la position
-- reelle des ecrans, donc ca marche a 2 comme a 3 ecrans, sans dependre des
-- noms de sortie.
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.window.move({ monitor = "r" }))
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.window.move({ monitor = "l" }))

-- Deplacer le workspace courant vers l'ecran de gauche / de droite.
hl.bind(mainMod .. " + ALT + SHIFT + h", hl.dsp.workspace.move({ monitor = "l" }))
hl.bind(mainMod .. " + ALT + SHIFT + l", hl.dsp.workspace.move({ monitor = "r" }))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + Z",         hl.dsp.workspace.toggle_special("magic"))            -- moved off S (screenshot uses SHIFT+S)
hl.bind(mainMod .. " + SHIFT + Z", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Resize submap (was i3's "resize" mode, $mod+r)
hl.submap("resize", function ()
    hl.bind("h", hl.dsp.resize_active({ x = -10 }))
    hl.bind("l", hl.dsp.resize_active({ x = 10 }))
    hl.bind("k", hl.dsp.resize_active({ y = -10 }))
    hl.bind("j", hl.dsp.resize_active({ y = 10 }))
    hl.bind("left",  hl.dsp.resize_active({ x = -10 }))
    hl.bind("right", hl.dsp.resize_active({ x = 10 }))
    hl.bind("up",    hl.dsp.resize_active({ y = -10 }))
    hl.bind("down",  hl.dsp.resize_active({ y = 10 }))
    hl.bind("Return", hl.dsp.submap("reset"))
    hl.bind("Escape", hl.dsp.submap("reset"))
end)
hl.bind(mainMod .. " + R", hl.dsp.submap("resize"))

-- Laptop multimedia keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires the playerctl package (not currently in home.nix, add it if you want these)
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})
