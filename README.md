# OBS-Scene-Switcher
This is a program that sends a certain keystroke to OBS Studio if a keyboard key (excluding modifier keys) or mouse button is pressed or if the mouse moves. It sends a different keystroke if a controller button is pressed or if the analog sticks are moved.

The idea is you setup an OBS scene that has a controller display and another one that has a keybaord/mouse display. Then choose a hotkey for switching to each scene, then follow these steps:

You create a profile by clicking `Create profile` from the options menu.\
It will open a different window, which will ask you to choose the keystroke that will be sent with keyboard/mouse input and the one that will be sent with controller input.\
The keys you choose should be the same as the hotkeys you set in OBS itself.\
You also have the option to type the keys manually by pressing the `Type manually` button, which means you can use a virtual key code or scan code.

## Additional Features

### Editing Profiles

When you choose the `Edit profile` option from the options menu, a new window (that is the same as the one for file creation) will pop up proptming you to enter the hotkeys you want to use.\
Once you submit, whichever profile tyou had selected will be updated with your new choices.\
Leaving one of the hotkeys blank will not cause any errors, which means you have the option to just edit one of the hotkeys without having to change the other.

### Deleting Profiles

The `Delete profile` option will delete the profile you currently have selected.

### Hotkey Setter

This allows you to use keys that aren't on your keyboard layout as hotkeys, things like F13-F24 or you can use a virtual key code or scan code.\
After choosing the the `Hotkey Setter` option from the options menu a new window will open with a text field telling you to type the key you want to use, after submitting, the **F1** key will temporarily be bound to whatever key you just typed.\
Once you close the window the F1 key will retain its original functionality

### Hotkeys

**Kill-Switch:** Shift+F4 will close the program without saving any changes.\
**Toggle Start/Stop:** Alt+s

\*This program does not work with Streamlabs OBS.*

Original idea for this was by ShikenNuggets
