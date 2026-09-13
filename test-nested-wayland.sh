#!/bin/bash

EXT_UUID="lan-scanner.anton-lysak"
ACTION="${1:-enable}"

echo "[1/4] Find current display..."
MAIN_WAYLAND="${WAYLAND_DISPLAY:-wayland-0}"
NEXT_NUM=$((${MAIN_WAYLAND#wayland-} + 1))
ENV_WAYLAND="wayland-${NEXT_NUM}"

echo "[2/4] Run nested GNOME Shell..."
dbus-run-session gnome-shell --nested --wayland 2>&1 | grep -E "Gjs|JS ERROR|LANScanner|minimal-test" &
DBUS_PID=$!

# Wait
sleep 3

# Find nested gnome-shell PID
GS_PID=$(pgrep -n -f "gnome-shell --nested")

if [ -z "$GS_PID" ]; then
    echo "Error: Nested GNOME Shell was not started!"
    kill $DBUS_PID 2>/dev/null
    exit 1
fi

echo "[3/4] Read nested session env..."
ENV_BUS=$(tr '\0' '\n' < /proc/$GS_PID/environ | grep '^DBUS_SESSION_BUS_ADDRESS=' | cut -d= -f2-)

if [ -z "$ENV_WAYLAND" ] || [ -z "$ENV_BUS" ]; then
    echo "Error: Can't get env!"
    kill $DBUS_PID 2>/dev/null
    exit 1
fi

echo "-> D-Bus: $ENV_BUS"
echo "-> Wayland: $ENV_WAYLAND"

echo "[4/4] Run: gnome-extensions $ACTION $EXT_UUID"
WAYLAND_DISPLAY="$ENV_WAYLAND" DBUS_SESSION_BUS_ADDRESS="$ENV_BUS" gsettings set org.gnome.shell disable-user-extensions false
WAYLAND_DISPLAY="$ENV_WAYLAND" DBUS_SESSION_BUS_ADDRESS="$ENV_BUS" gnome-extensions $ACTION "$EXT_UUID"

