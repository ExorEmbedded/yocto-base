# Postpone WM startup to avoid glitches
# (e.g. window frames shown for an instant [#1004]
sleep 30

echo "Starting Window Manager" | logger

if [ -x $HOME/.Xsession ]; then
    exec $HOME/.Xsession
elif [ -x /usr/bin/x-session-manager ]; then
    exec /usr/bin/x-session-manager
else
    exec /usr/bin/x-window-manager --no-force-fullscreen
fi
