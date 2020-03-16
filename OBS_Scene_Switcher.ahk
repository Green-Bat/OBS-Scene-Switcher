#Warn
#NoEnv
#SingleInstance, Force

keybdkey := "F13" ; This determines what gets sent from keyboard/mouse inputs
controllerkey := "F14" ; This determines what gets sent from controller inputs

; From the AHK documentation, used to auto-detect the joystick number
JoystickNumber := 0
if (JoystickNumber <= 0){
	Loop 16 {
		if (GetKeyState(A_Index . "JoyName") != ""){
			JoystickNumber := A_Index
			break
		}
	}
	
	if (JoystickNumber <= 0 ){
		MsgBox, 16, OBS Scene Switcher, % "ERROR: Could not detect any joysticks! Program will exit."
		ExitApp
	}
}

SetBatchLines, 20ms
CoordMode, Mouse, Screen
SetTimer, check_mouse, 60 ; A subroutine that checks mouse movement
SetTimer, check_axes, 90 ; A subroutine that checks the state of the various axes/ POV buttons of the controller

MouseGetPos, sx, sy
joy_buttons := GetKeyState(JoystickNumber . "JoyButtons")
joy_info := GetKeyState(JoystickNumber . "JoyInfo")
axis_3 := InStr(joy_info, "Z", true) ; Checks if the third axis exists for the controller
dpad := InStr(joy_info, "P", true) ; Checks if the POV buttons exist fot the controller

previousJoyX := ""
previousJoyY := ""
if (axis_3 != 0){ ; Only create the variables if the axis exists for the controller
	previousJoyZ := ""
	previousJoyR := ""
}

cInput := Func("OnInput").Bind(controllerkey) ; Create bound function object and bind the controller key to it, so it can be used with the Hotkey command

Loop, % joy_buttons { ; Turns all the controller buttons into hotkeys
		Hotkey, % JoystickNumber "Joy" A_Index, % cInput, On
	}

; An input hook used for intercepting all keyboard keys (excluding modifiers)
ih := InputHook("V L0 I")
ih.KeyOpt("{All}", "N")
ih.KeyOpt("{LCtrl}{RCtrl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}", "-N")
ih.OnKeyDown := Func("OnInput").Bind(keybdkey)
ih.Start()
return

~XButton2::
~XButton1::
~MButton::
~RButton::
~LButton::
Sleep, 150
OnInput(keybdkey)
return

;**********************************/Timers/*******************************************************

check_mouse: ; The subroutine that checks mouse movement
	MouseGetPos, cx, cy
	if (cx != sx or cy != sy){
		if (cx > (sx+50) or cx < (sx-50) or cy > (sy+50) or cy < (sy-50)){
			OnInput(keybdkey)
			MouseGetPos, sx, sy
		} 
	}
	return
	
check_axes: ; The subroutine that checks controller axes
	joyX := GetKeyState(JoystickNumber . "JoyX")
	joyY := GetKeyState(JoystickNumber . "JoyY")
	if (!IsValueSimilar(previousJoyX, joyX) || !IsValueSimilar(previousJoyY, joyY)){
		cInput.Call()
		previousJoyX := joyX
		previousJoyY := joyY
	}
	
	if (axis_3 != 0){ ; Only check the state if the axis exists
		joyZ := GetKeyState(JoystickNumber . "JoyZ")
		joyR := GetKeyState(JoystickNumber . "JoyR")
		if (!IsValueSimilar(previousJoyR, joyR) || !IsValueSimilar(previousJoyZ, joyZ)){
			cInput.Call()
			previousJoyZ := joyZ
			previousJoyR := joyR
		}
	}
	
	if (dpad != 0){ ; Only check POV state if it exists
		joy_p := GetKeyState(JoyStickNumber . "JoyPOV")
		if(joy_p != -1 && joy_p != "")
			cInput.Call()
	}
	return
	
;**********************************/Functions/*******************************************************

OnInput(key){
	Critical
	SetKeyDelay, 10
	SetTitleMatchMode, 2
	ControlSend, ahk_parent, {Blind}{%key%}, OBS
}

IsValueSimilar(var1, var2){ ; A function that compares the previous and current states of the controller axes
	return ((var1 - 7) <= var2) && ((var1 + 7) >= var2)
}
;****************************************************************************************************
; Kill-switch Shift+F4
+F4::ExitApp
