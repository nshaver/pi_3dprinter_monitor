# pi_3dprinter_monitor
curses-based 3d printer monitor

The start_monitor.sh script creates tmux windows that display two different 3d printer statuses, with a raspberry pi status on the button line.

To make it run automatically upon login, add this to the bottom of ~/.bashrc
if [[ -z "$TMUX" ]]; then
    bash ~/your_script_name.sh
fi

Use raspi-config display options to disable screen blanking.

Use raspi-config system options to configure console autologin.

To configure the console font to a larger font, use:
sudo dpkg-reconfigure console-setup

Modify the qidi_monitor.sh and makerselect_monitor.sh as needed to customize the two printer instance monitors.
The qidi one supports dual extruders.
Each gets its own api key from octoprint's setup.
octoprint_deploy was used to create the two octoprint instances.
