# OBS-Scene-Switcher
This is an AutoHotKey script that sends a certain keystroke to a window with "OBS" in it's title if a keyboard key (excluding modifier keys) or mouse button is pressed or if the mouse moves. It sends a different keystroke if a controller button is pressed or if the analog sticks are moved.

The actual keysrokes that are sent can be modified, to do so change the key **_after_** `{Blind}` in the `OnGamepadUsed()` and `OnKeyPressed()` functions that are towards the end of the script.

Kill-Switch: Shift+F4 will terminate the script.

Original idea for this was by ShikenNuggets
