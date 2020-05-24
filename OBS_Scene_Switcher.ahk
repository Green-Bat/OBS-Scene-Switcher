#Include <JSON>

/*
*	OBS Scene Switcher
*	By GreenBat
*	Version:
*		2.6 (Last updated 24/05/2020)
*		https://github.com/Green-Bat/OBS-Scene-Switcher
*	Requirements:
*		AutoHotkey v1.1.32.00+
*		JSON.ahk
*/

#Warn
#NoEnv
#SingleInstance, Force
ListLines, Off
SetBatchLines, 20ms
CoordMode, Mouse, Screen
SetWorkingDir, % A_ScriptDir

settingsfile := FileOpen(A_ScriptDir "\settings.JSON" , "r")
if !(IsObject(settingsfile)){
	MsgBox, 16, OBS Scene Switcher, ERROR: Failed to load settings file! Please make sure it's in the same directory as the program's exe file.
	ExitApp
}
global settings := JSON.Load(settingsfile.Read())
	, HasStarted := false, keybdkey := controllerkey := ""
	, JoystickNumber := 0
settingsfile.Close()

OnMessage(0x44, "CenterMsgBox") ; Center any MsgBox before it appears

Menu, OptionsMenu, Add, Create profile, CreateProfile
Menu, OptionsMenu, Add, Edit profile, EditProfile
Menu, OptionsMenu, Add, Delete profile, DeleteProfile
Menu, OptionsMenu, Add, Hotkey Setter, HotkeySetter
Menu, MenuBar, Add, &Options, :OptionsMenu
Gui, Main:New, +HwndMainHwnd, OBS Scene Switcher
Gui, Main:Menu, MenuBar
Gui, Font, s11
Gui, Main:Add, Text, xm ym+5, Profiles
Gui, Font
Gui, Main:Add, DDL, xp yp+20 vprofile gchangeprofile
for savedprofile in settings.Profiles { ; Fill up the DDL with the saved profiles
	GuiControl,, profile, % savedprofile
}
GuiControl, ChooseString, profile, % settings.LastProfile ; Choose whichever profile was last chosen
Gui, Main:Add, Text, xp yp+30, Keyboard Key
Gui, Main:Add, Edit, xp yp+20 w140 +Disabled vsavedkbd, % ChangeHkey(keybdkey := settings.Profiles[settings.LastProfile][1])
Gui, Main:Add, Text, xp yp+30 wp, Controller Key
Gui, Main:Add, Edit, xp yp+20 wp +Disabled vsavedctrlr, % ChangeHkey(controllerkey := settings.Profiles[settings.LastProfile][2])
Gui, Font, s11
Gui, Main:Add, Button, xp+170 yp-90 wp-20 h30 vStartButton gStart, Start
Gui, Main:Add, Button, xp yp+50 wp hp +Disabled vStopButton gStop, Stop
Gui, Main:Show, W320 H175
return

; Make the mouse buttons hotkeys only if the start button was pressed
#If HasStarted
~XButton2::
~XButton1::
~MButton::
~RButton::
~LButton::
	Sleep, 150
	OnInput(keybdkey)
	return
#If

;****************************************************************** - G-LABELS - ******************************************************************

;******************************************************************| - PROFILE CREATION/DELETION - |******************************************************************

CreateProfile:
	Gui, Main:+OwnDialogs
	; Stop the scene switcher if it was started
	if (HasStarted)
		gosub, Stop

	WinGetPos, x, y, w, h, ahk_id %MainHwnd%
	Loop {
		InputBox, ProfileName, Profile Creation, Enter a name for the profile,, 200, 150, x + ((w/2) - 100), y + ((h/2) - 75)
		if (settings.Profiles.HasKey(ProfileName)){
			MsgBox, 48, OBS Scene Switcher, This profile name already exists, please choose another one
			ProfileName := ""
			continue
		}
	} until (ProfileName || ErrorLevel)
	if (ErrorLevel == 1)
		return

	Gui, Main:+Disabled
	Gui, HKey:New, +HwndHwnd2 +OwnerMain, Hotkey Selection
	Gui, Font, s9
	Gui, HKey:Add, Text, xm ym, Keyboard/mouse hotkey ( to be sent with keyboard/mouse input )
	Gui, HKey:Add, Hotkey, xp yp+20 w110 h20 vkbdHkey +HwndKID
	Gui, Hkey:Add, Edit, xp yp wp hp Hidden vAltKHkey
	Gui, Hkey:Add, Checkbox, xp+130 yp+5 vKWin, Use Windows key
	Gui, Hkey:Add, Button, xp+115 yp-5 vTypeK gTypeHkey, Type manually
	Gui, HKey:Add, Text, xp-245 yp+25, Controller hotkey ( to be sent with controller input )
	Gui, HKey:Add, Hotkey, xp yp+20 w110 h20 vCtrlrHkey +HwndCID
	Gui, Hkey:Add, Edit, xp yp wp hp Hidden vAltCHkey
	Gui, Hkey:Add, Checkbox, xp+130 yp+5 vCWin, Use Windows key
	Gui, Hkey:Add, Button, xp+115 yp-5 vTypeC gTypeHkey, Type manually
	Gui, HKey:Add, Button, xp-120 yp+30 wp hp gSetHKeys, Submit
	Gui, HKey:Show, % "X" (x+(w/2) - 175) " Y" (y + (h/2) - 65) " W350 H130"
	return

SetHKeys:
	Gui, HKey:+OwnDialogs
	Gui, HKey:Submit, NoHide
	key1 := (kbdHkey) ? kbdHkey : AltKHkey
	key2 := (CtrlrHkey) ? CtrlrHkey : AltCHkey
	if !(key1){
		MsgBox, 48, Hotkey Selection, You forgot to add a hotkey for keyboard input
		return
	}
	if !(key2){
		MsgBox, 48, Hotkey Selection, You forgot to add a hotkey for controller input
		return
	}
	; Add the windows key if the user checked the checkbox
	if (KWin)
		key1 := "#" . key1
	if (CWin)
		key2 := "#" . key2
	
	settings.Profiles[ProfileName] := [keybdkey := key1, controllerkey := key2]
	, settings.LastProfile := ProfileName
	; Update the main GUI
	GuiControl, Main:, savedkbd, % ChangeHkey(key1)
	GuiControl, Main:, savedctrlr, % ChangeHkey(key2)
	; Empty the DDL, refill it, and choose the profile the user just created
	GuiControl, Main:, profile, |
	for savedprofile in settings.Profiles {
		GuiControl, Main:, profile, % (savedprofile == ProfileName) ? ProfileName "||" : savedprofile
	}
	gosub, HkeyGuiClose
	return

TypeHkey(CtrlHwnd, GuiEvent, EventInfo, Errlvl:=""){
	GuiControlGet, BtnV, Name, % CtrlHwnd ; Get the associated var of the button
	GuiControlGet, BtnTxt,, % CtrlHwnd ; Get the text of the button
	; Figure out which button was pressed using it's associated var and set the variables accordingly
	Switch (BtnV)
	{
		Case "TypeK":
			Control1 := "kbdHkey"
			Control2 := "AltKHkey"
			Check := "KWin"
		Case "TypeC":
			Control1 := "CtrlrHkey"
			Control2 := "AltCHkey"
			Check := "CWin"
	}
	; Hide and uncheck the checkbox
	GuiControl, Hide, % Check
	GuiControl,, % Check, 0
	; Revert the changes if the button is pressed again
	if (BtnTxt == "Type as Hotkey"){
		Revert(Control1, Control2, BtnV, Check)
		return
	}
	; Change the text of the button
	GuiControl,, %BtnV%, Type as Hotkey
	GuiControl, Hide, % Control1
	GuiControl,, % Control1 ; Empty the hotkey control
	GuiControl, Show, % Control2
	GuiControl, Focus, % Control2
	return
}
	
Revert(Control1, Control2, BtnV, Check){
	GuiControl,, %BtnV%, Type manually
	GuiControl, Show, % Check
	GuiControl, Show, % Control1
	GuiControl, Hide, % Control2
	GuiControl,, % Control2 ; Empty the edit control
	GuiControl, Focus, % Control1
	return
}

HKeyGuiClose:
	Gui, HKey:Destroy
	Gui, Main:-Disabled
	WinActivate, ahk_id %MainHwnd%
	return
;***************************************************************************************************************************************************

EditProfile:
	Gui, Main:+OwnDialogs
	if !(settings.LastProfile){
		MsgBox, 48, OBS Scene Switcher, No profile is selected
		return
	}
	if (HasStarted)
		gosub, Stop
	WinGetPos, x, y, w, h, ahk_id %MainHwnd%

	Gui, Main:+Disabled
	Gui, HKey:New, +HwndHwnd2 +OwnerMain, Hotkey Selection
	Gui, Font, s9
	Gui, HKey:Add, Text, xm ym, Keyboard/mouse hotkey ( to be sent with keyboard/mouse input )
	Gui, HKey:Add, Hotkey, xp yp+20 w110 h20 vkbdHkey +HwndKID, % settings.Profiles[settings.LastProfile][1]
	Gui, Hkey:Add, Edit, xp yp wp hp Hidden vAltKHkey
	Gui, Hkey:Add, Checkbox, xp+130 yp+5 vKWin, Use Windows key
	Gui, Hkey:Add, Button, xp+115 yp-5 vTypeK gTypeHkey, Type manually
	Gui, HKey:Add, Text, xp-245 yp+25, Controller hotkey ( to be sent with controller input )
	Gui, HKey:Add, Hotkey, xp yp+20 w110 h20 vCtrlrHkey +HwndCID, % settings.Profiles[settings.LastProfile][2]
	Gui, Hkey:Add, Edit, xp yp wp hp Hidden vAltCHkey
	Gui, Hkey:Add, Checkbox, xp+130 yp+5 vCWin, Use Windows key
	Gui, Hkey:Add, Button, xp+115 yp-5 vTypeC gTypeHkey, Type manually
	Gui, HKey:Add, Button, xp-120 yp+30 wp hp gSetHKeys, Submit
	Gui, HKey:Show, % "X" (x+(w/2) - 175) " Y" (y + (h/2) - 65) " W350 H130"

	ProfileName := settings.LastProfile
	return
;***************************************************************************************************************************************************

DeleteProfile:
	Gui, Main:+OwnDialogs
	if !(settings.LastProfile){
		MsgBox, 48, OBS Scene Switcher, No profile is selected
		return
	}
	MsgBox, 52, OBS Scene Switcher, % "Are you sure you want to delete this profile: """ settings.LastProfile """"
	IfMsgBox, No
		return
	if (HasStarted)
		gosub, Stop
	Gui, Main:Submit, NoHide
	settings.Profiles.Delete(profile)
	settings.LastProfile := ""
	; Empty the DDL and refill it
	GuiControl,, profile, |
	for savedprofile in settings.Profiles {
		GuiControl,, profile, % savedprofile
	}
	GuiControl,, savedkbd, % ""
	GuiControl,, savedctrlr, % ""
	return
;***************************************************************************************************************************************************

Start:
	Gui, Main:Submit, NoHide
	Gui, Main:+OwnDialogs
	if !(settings.Profiles.Count()){
		gosub, CreateProfile
		return
	} else if !(profile){
		MsgBox, 0, OBS SceneSwitcher, % "You forgot to choose a profile silly"
		return
	}
	if !(CheckController())
		return
	GuiControl, Disable, StartButton
	GuiControl, Enable, StopButton
	HasStarted := true
	SetTimer, check_mouse, 60 ; A subroutine that checks mouse movement
	SetTimer, check_axes, 90 ; A subroutine that checks the state of the various axes/ POV buttons of the controller

	MouseGetPos, sx, sy ; Get the mouse coords for later
	joy_info := GetKeyState(JoystickNumber . "JoyInfo")
	, axis_3 := InStr(joy_info, "Z", true) ; Checks if the third axis exists for the controller
	, dpad := InStr(joy_info, "P", true) ; Checks if the POV buttons exist fot the controller
	, previousJoyX := previousJoyY := ""
	; Only create the variables if the axis exists for the controller
	if (axis_3)
		previousJoyZ := previousJoyR := ""

	; Turns all the controller buttons into hotkeys
	funcobj :=  Func("OnInput").Bind(controllerkey)
	Loop, % GetKeyState(JoystickNumber . "JoyButtons") {
		Hotkey, % JoystickNumber "Joy" A_Index, % funcobj, On
	}

	; An input hook used for intercepting all keyboard keys (excluding modifiers)
	ih := InputHook("V L0 I")
	ih.KeyOpt("{All}", "N")
	ih.KeyOpt("{LCtrl}{RCtrl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}", "-N")
	ih.OnKeyDown := Func("OnInput").Bind(keybdkey)
	ih.Start()
	return
;***************************************************************************************************************************************************

Stop: ; Turns off all timers and hotkeys, and stops the input hook
	GuiControl, Disable, StopButton
	GuiControl, Enable, StartButton
	HasStarted := false
	SetTimer, check_mouse, Off
	SetTimer, check_axes, Off
	Loop, % GetKeyState(JoystickNumber . "JoyButtons") {
		Hotkey, % JoystickNumber "Joy" A_Index, % funcobj, Off
	}
	ih.Stop()
	return
;***************************************************************************************************************************************************

changeprofile:
	if (HasStarted)
		gosub, Stop
	Gui, Main:Submit, NoHide
	settings.LastProfile := profile
	GuiControl,, savedkbd, % ChangeHkey(keybdkey := settings.Profiles[profile][1])
	GuiControl,, savedctrlr, % ChangeHkey(controllerkey := settings.Profiles[profile][2])
	return
;******************************************************************| - HOTKEY SETTER - |******************************************************************

; Used to send unusal hotkeys, for example, F13-F24
; It'll bind whatever key the user enters to the F1 key and unbind it once the user closes the window
HotkeySetter:
	WinGetPos, x, y, w, h, ahk_id %MainHwnd%
	Gui, HkeySet:New, +AlwaysOnTop +HwndHwnd3, Hotkey Setter
	Gui, Font, s10
	Gui, HkeySet:Add, Text, xm ym,
	( LTrim
	This is used to send unusual keys (e.g. F13-F24). 
	It will temporarily remap the F1 key to whatever key you type in.
	)
	Gui, HkeySet:Add, Edit, xp yp+40 w80 vOddHkey
	Gui, HkeySet:Add, Button, xp+190 yp-2.5 wp-10 gSet, Set
	Gui, HkeySet:Show, % "X" (x+(w/2) - 200) " Y" (y + (h/2) - 40) " W400 H80"
	count := 0
	return

Set:
	count++
	Gui, HkeySet:+OwnDialogs
	MsgBox,, Hotkey Setter, The key you just entered will now be temporarily remapped to the F1 key
	Hotkey, $F1, SendOddKey, On
	return

SendOddKey:
	Gui, HkeySet:Submit, NoHide
	Send, {%OddHkey%}
	return

HkeySetGuiClose:
	Gui, HkeySet:+OwnDialogs
	Hotkey, F1, SendOddKey, Off
	if (count > 0){
		MsgBox,, Hotkey Setter, The F1 key now has its normal functionality
		count := ""
	}
	Gui, HkeySet:Destroy
	WinActivate, ahk_id %MainHwnd%
	return
;***************************************************************************************************************************************************

MainGuiClose:
	settingsfile := FileOpen(A_ScriptDir "\settings.JSON" , "w")
	if !(IsObject(settingsfile)){
		MsgBox, 16, Savefile Replacer, 
		( LTrim
		ERROR: Failed to load settings file! Please make sure it's in the correct directory.
		You can use Shift+F4 to force close the program, but any changes you made will not be saved.
		)
		return
	}
	settingsfile.Seek(0)
	settingsfile.Write((JSON.Dump(settings,, 4)))
	settingsfile.Close()
	ExitApp

;****************************************************************** - TIMERS - ******************************************************************

check_mouse: ; The subroutine that checks mouse movement
	MouseGetPos, cx, cy
	if (cx != sx or cy != sy){
		if (cx > (sx+50) or cx < (sx-50) or cy > (sy+50) or cy < (sy-50)){
			OnInput(keybdkey)
			MouseGetPos, sx, sy
		} 
	}
	return
;***************************************************************************************************************************************************

check_axes:
	joyX := GetKeyState(JoystickNumber . "JoyX")
	, joyY := GetKeyState(JoystickNumber . "JoyY")
	if !(IsValueSimilar(previousJoyX, joyX) && IsValueSimilar(previousJoyY, joyY)){
		OnInput(controllerkey)
		previousJoyX := joyX
		, previousJoyY := joyY
	}
	; Only check the state if the axis exists
	if (axis_3){
		joyZ := GetKeyState(JoystickNumber . "JoyZ")
		, joyR := GetKeyState(JoystickNumber . "JoyR")
		if !(IsValueSimilar(previousJoyR, joyR) && IsValueSimilar(previousJoyZ, joyZ)){
			OnInput(controllerkey)
			previousJoyZ := joyZ
			, previousJoyR := joyR
		}
	}
	; Only check POV state if it exists
	if (dpad){
		joy_p := GetKeyState(JoyStickNumber . "JoyPOV")
		if (joy_p != -1 && joy_p != "")
			OnInput(controllerkey)
	}
	return
;****************************************************************** - FUNCTIONS - ******************************************************************

OnInput(key){
	Critical
	Lastkey := StrSplit(key, ["^", "!", "+", "#"]) ; Split the key by modifier to get the key without any modifiers
	key := StrReplace(key, Lastkey[Lastkey.MaxIndex()]) ; Remove the key from the string and keep the modifiers
	SetTitleMatchMode, 2
	ControlSend, ahk_parent, % "{Blind}" key "{" Lastkey[Lastkey.MaxIndex()] "}", OBS ahk_class Qt5QWindowIcon
}
;***************************************************************************************************************************************************

CheckController(){ ; From the AHK documentation, used to auto-detect the joystick number
	Loop, 16 {
		if (GetKeyState(A_Index . "JoyName")){
			JoystickNumber := A_Index
			break
		}
	}
	if (JoystickNumber <= 0 ){
		Gui, +OwnDialogs
		MsgBox, 16, OBS Scene Switcher, % "ERROR: Could not detect any joysticks! Please connect one and try again"
		return false
	}
	return true
}
;***************************************************************************************************************************************************

ChangeHkey(RawHkey){ ; Function that changes modifier symbols into literal text for display purposes in the main GUI window
	static Modifiers := {"^": "Ctrl + ", "!": "Alt + ", "#": "Win + ", "+": "Shift + "}
	ChangedHkey := ""
	, LastKey := StrSplit(RawHkey, ["^", "!", "+", "#"]) ; Split the key by modifier to get the key without any modifiers

	for symbol, modifier in Modifiers {
		if (InStr(RawHkey, symbol))
			ChangedHkey .= modifier
	}
	ChangedHkey .= LastKey[LastKey.MaxIndex()]

	return ChangedHkey
}
;***************************************************************************************************************************************************

IsValueSimilar(var1, var2){ ; A function that compares the previous and current states of the controller axes
	return ((var1 - 7) <= var2) && ((var1 + 7) >= var2)
}
;***************************************************************************************************************************************************

CenterMsgBox(P){
	global MainHwnd
	if (P == 1027){
		Process, Exist ; Get the PID of program, which is set to ErrorLevel
		DetectHiddenWindows, On
		WinGetPos, x1, y1, w1, h1, ahk_id %MainHwnd%
		if WinExist("ahk_class #32770 ahk_pid " ErrorLevel){
			WinGetPos,,, w2, h2 ; Get dimensions of the MsgBox
			WinMove, x1 + ((w1/2) - (w2/2)), y1 + ((h1/2) - (h2/2))
		}
	}
	DetectHiddenWindows, Off
}

; Kill-switch Shift+F4
+F4::ExitApp
