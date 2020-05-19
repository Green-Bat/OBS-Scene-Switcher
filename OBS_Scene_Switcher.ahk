#Include <JSON>

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
settingsfile.Close()

global HasStarted := false, keybdkey := controllerkey := ""
OnMessage(0x44, "CenterMsgBox") ; Center any MsgBox before it appears

Menu, OptionsMenu, Add, Create profile, CreateProfile
Menu, OptionsMenu, Add, Delete profile, DeleteProfile
Menu, OptionsMenu, Add, Hotkey Setter, HotkeySetter
Menu, MenuBar, Add, &Options, :OptionsMenu
Gui, Main:New, +HwndMainHwnd, OBS Scene Switcher
Gui, Main:Menu, MenuBar
Gui, Font, s11
Gui, Main:Add, Text, xm ym+5, Profiles
Gui, Font
Gui, Main:Add, DDL, xp yp+20 vprofile gchangeprofile
for savedprofile in settings.Profiles {
	GuiControl,, profile, % savedprofile
}
GuiControl, ChooseString, profile, % settings.LastProfile
Gui, Main:Add, Text, xp yp+30, Keyboard Key
Gui, Main:Add, Edit, xp yp+20 w140 +Disabled vsavedkbd, % ChangeHkey(keybdkey := settings.Profiles[settings.LastProfile][1])
Gui, Main:Add, Text, xp yp+30 wp, Controller Key
Gui, Main:Add, Edit, xp yp+20 wp +Disabled vsavedctrlr, % ChangeHkey(controllerkey := settings.Profiles[settings.LastProfile][2])
Gui, Font, s11
Gui, Main:Add, Button, xp+170 yp-90 wp-20 h30 vStartButton gStart, Start
Gui, Main:Add, Button, xp yp+50 wp hp +Disabled vStopButton gStop, Stop
Gui, Main:Show, W320 H175
return

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

CreateProfile:
	Gui, Main:+OwnDialogs
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
	Gui, Font, s10
	Gui, Font, s9
	Gui, HKey:Add, Text, xm ym, Keyboard/mouse hotkey ( to be sent with keyboard/mouse input )
	Gui, HKey:Add, Hotkey, xp yp+20 w110 h20 vkbdHkey
	Gui, Hkey:Add, Checkbox, xp+130 yp+5 vKWin, Use Windows key
	Gui, HKey:Add, Text, xp-130 yp+25, Controller hotkey ( to be sent with controller input )
	Gui, HKey:Add, Hotkey, xp yp+20 w110 h20 vCtrlrHkey
	Gui, Hkey:Add, Checkbox, xp+130 yp+5 vCWin, Use Windows key
	Gui, HKey:Add, Button, xp+90 yp+20 wp hp+10 gSetHKeys, Submit
	Gui, HKey:Show, % "X" (x+(w/2) - 175) " Y" (y + (h/2) - 65) " W350 H130"
	return

SetHKeys:
	Gui, HKey:+OwnDialogs
	Gui, HKey:Submit, NoHide
	if !(kbdHkey){
		MsgBox, 48, Hotkey Selection, You forgot to add a hotkey for keyboard input
		return
	}
	if !(CtrlrHkey){
		MsgBox, 48, Hotkey Selection, You forgot to add a hotkey for controller input
		return
	}

	if (KWin)
		kbdHkey := "#" . kbdHkey
	if (CWin)
		CtrlrHkey := "#" . CtrlrHkey
	
	keybdkey := kbdHkey
	, controllerkey := CtrlrHkey
	, settings.Profiles[ProfileName] := [kbdHkey, CtrlrHkey]
	, settings.LastProfile := ProfileName
	
	GuiControl, Main:, savedkbd, % ChangeHkey(kbdHkey)
	GuiControl, Main:, savedctrlr, % ChangeHkey(CtrlrHkey)
	GuiControl, Main:, profile, |
	for savedprofile in settings.Profiles {
		GuiControl, Main:, profile, % (savedprofile == ProfileName) ? ProfileName "||" : savedprofile
	}
	gosub, HkeyGuiClose
	return

HKeyGuiClose:
	Gui, HKey:Destroy
	Gui, Main:-Disabled
	WinActivate, ahk_id %MainHwnd%
	return
;***************************************************************************************************************************************************

DeleteProfile:
	Gui, Main:Submit, NoHide
	settings.Profiles.Delete(profile)
	settings.LastProfile := ""
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
	if !(profile){
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
	SetTimer, CheckController, % 60000*2 ; Function to check if the controller is still connected

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

Stop:
	GuiControl, Disable, StopButton
	GuiControl, Enable, StartButton
	HasStarted := false
	SetTimer, check_mouse, Off
	SetTimer, check_axes, Off
	SetTimer, CheckController, Off
	Loop, % GetKeyState(JoystickNumber . "JoyButtons") {
		Hotkey, % JoystickNumber "Joy" A_Index, % funcobj, Off
	}
	ih.Stop()
	return
;***************************************************************************************************************************************************

changeprofile:
	if (HasStarted){
		MsgBox, 48, OBS Scene Switcher, % "Please press the stop button before switching profiles"
		return
	}
	Gui, Main:Submit, NoHide
	settings.LastProfile := profile
	GuiControl,, savedkbd, % ChangeHkey(keybdkey := settings.Profiles[profile][1])
	GuiControl,, savedctrlr, % ChangeHkey(controllerkey := settings.Profiles[profile][2])
	return
;***************************************************************************************************************************************************

HotkeySetter:
	WinGetPos, x, y, w, h, ahk_id %MainHwnd%
	Gui, HkeySet:New, +AlwaysOnTop +HwndHwnd3 +OwnerMain, Hotkey Setter
	Gui, HkeySet:Add, Edit, xm ym+20 w80 vOddHkey
	Gui, HkeySet:Add, Button, xp+120 yp wp-10 gSet, Set
	Gui, HkeySet:Show, % "X" (x+(w/2) - 110) " Y" (y + (h/2) - 37.5) " W220 H75"
	return

Set:
	Gui, HkeySet:+OwnDialogs
	MsgBox,, Hotkey Setter, The F1 key will now be temporarily remapped to the key you just entered
	Hotkey, F1, SendOddKey, On
	return

SendOddKey:
	Gui, HkeySet:Submit, NoHide
	Send, {%OddHkey%}
	return

HkeySetGuiClose:
	Gui, HkeySet:+OwnDialogs
	Hotkey, F1, SendOddKey, Off
	MsgBox,, Hotkey Setter, The F1 key now has its normal functionality
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
		You can use Ctrl+Esc to force close the program, but any changes you made will not be saved.
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
	if (!IsValueSimilar(previousJoyX, joyX) || !IsValueSimilar(previousJoyY, joyY)){
		OnInput(controllerkey)
		previousJoyX := joyX
		, previousJoyY := joyY
	}
	; Only check the state if the axis exists
	if (axis_3){
		joyZ := GetKeyState(JoystickNumber . "JoyZ")
		, joyR := GetKeyState(JoystickNumber . "JoyR")
		if !(IsValueSimilar(previousJoyR, joyR)){
			OnInput(controllerkey)
			previousJoyZ := joyZ
			, previousJoyR := joyR
		}
	}
	; Only check POV state if it exists
	if (dpad){
		joy_p := GetKeyState(JoyStickNumber . "JoyPOV")
		if(joy_p != -1 && joy_p != "")
			OnInput(controllerkey)
	}
	return
;****************************************************************** - FUNCTIONS - ******************************************************************

OnInput(key){
	Critical
	Lastkey := StrSplit(key, ["^", "!", "+", "#"])
	, key := StrReplace(key, Lastkey[Lastkey.MakIndex()], "")
	SetTitleMatchMode, 2
	ControlSend, ahk_parent, % "{Blind}" key "{" Lastkey[Lastkey.MaxIndex()] "}", OBS ahk_class Qt5QWindowIcon
}
;***************************************************************************************************************************************************

CheckController(){ ; From the AHK documentation, used to auto-detect the joystick number
	global JoystickNumber := 0
	Loop, 16 {
		if (GetKeyState(A_Index . "JoyName")){
			JoystickNumber := A_Index
			break
		}
	}
	if (JoystickNumber <= 0 ){
		MsgBox, 16, OBS Scene Switcher, % "ERROR: Could not detect any joysticks! Please connect one and try again"
		if (HasStarted)
			gosub, Stop
		return false
	}
	return true
}
;***************************************************************************************************************************************************

ChangeHkey(RawHkey){
	static Modifiers := {"^": "Ctrl + ", "!": "Alt + ", "#": "Win + ", "+": "Shift + "}
	ChangedHkey := ""
	, LastKey := StrSplit(RawHkey, ["^", "!", "+", "#"])

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
!r::Reload
