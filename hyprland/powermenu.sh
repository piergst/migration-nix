#!/usr/bin/env sh
# Power menu via wofi, replaces the old i3-nagbar exit confirmation.
# Install at e.g. ~/.local/bin/powermenu.sh (chmod +x) and bind it in hyprland.lua:
#   hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("$HOME/.local/bin/powermenu.sh"))

set -eu

choice=$(printf 'Lock\nLogout\nSuspend\nReboot\nShutdown' | wofi --dmenu --prompt "Power")

case "$choice" in
    Lock)     hyprlock ;;
    Logout)   hyprctl dispatch exit ;;
    Suspend)  systemctl suspend ;;
    Reboot)   systemctl reboot ;;
    Shutdown) systemctl poweroff ;;
    *)        exit 0 ;;
esac
