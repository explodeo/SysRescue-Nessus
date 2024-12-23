#!/bin/sh

# this script launches the debugging tool in a new xfce terminal
xfce4-terminal --command='/opt/oh-switch-disk/arista-debug.sh' \
    --title="\"Oh-Switch-Disk\" Debugging Tool (Arista)" \
    --geometry 120x40+10+10
    --fullscreen