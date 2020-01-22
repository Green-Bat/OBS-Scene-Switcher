# OBS-Scene-Switcher
This is a relativley simple AutoHotKey script that sends a certain keystroke to a window with "OBS" in it's title if a keyboard key is pressed (excluding modifier keys) or if the mouse moves. It sends a different keystroke if a controller button is pressed or if the analog sticks are moved.

The actual keysrokes that are sent to OBS can be modified, to do so change they key **after** `{Blind}` in the `OnGamepadUsed()` and `OnKeyPressed()` functions that are towards the end of the script.

Original idea for this was by ShikenNuggets
