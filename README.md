# OBS-Scene-Switcher
This is a program that sends a certain keystroke to OBS Studio if a keyboard key (excluding modifier keys) or mouse button is pressed or if the mouse moves. It sends a different keystroke if a controller button is pressed or if the analog sticks are moved.

The idea is you setup an OBS scene that has a controller display and another one that has a keybaord/mouse display. Then choose a hotkey for switching to each scene, then follow these steps:

You create a profile by clicking `Create Profile` from the options menu.\
It will open a different window, which will ask you to choose the keystroke that will be sent with keyboard/mouse input and the one that will be sent with controller input.\
The keys you choose should be the same as the hotkeys you set in OBS itself.

Kill-Switch: Shift+F4 will close the program without saving any changes.

\*This script does not work with Streamlabs OBS.*

Original idea for this was by ShikenNuggets
