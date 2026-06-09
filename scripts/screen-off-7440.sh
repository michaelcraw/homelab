#!/bin/bash
ssh michael@100.106.110.55 "WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR=/run/user/1000 gdbus call --session --dest org.gnome.ScreenSaver --object-path /org/gnome/ScreenSaver --method org.gnome.ScreenSaver.SetActive true"
