#Warn
#SingleInstance

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
		MsgBox Could not detect any joysticks!
		ExitApp
	}
}

SetBatchLines, 20ms
CoordMode, Mouse, Screen
SetTimer, check, 60 ; A subroutine that checks mouse movement and the POV buttons of the controller
SetTimer, check_axes, 90 ; A subroutine that checks the state of the various axes of the controller
OnExit("Exit")

MouseGetPos, sx, sy
joy_buttons := GetKeyState(JoystickNumber . "JoyButtons")
joy_info := GetKeyState(JoystickNumber . "JoyInfo")
; Checks if a certain axis/POV buttons exist for the controller
; axis_3 := InStr(joy_info, "Z", true)
axis_4 := InStr(joy_info, "R", true)
axis_5 := InStr(joy_info, "U", true)
axis_6 := InStr(joy_info, "V", true)
dpad := InStr(joy_info, "P", true)

previousJoyX := ""
previousJoyY := ""
; Only create the variable if the axis/POV buttons exist for the controller
;if (axis_3 != 0)
;	previousJoyZ := ""
if (axis_4 != 0)
	previousJoyR := ""
if (axis_5 != 0)
	previousJoyU := ""
if (axis_6 != 0)
	previousJoyV := ""

Loop, %joy_buttons% { ; Turns the controller buttons into hotkeys that send the F15 key with an input level of 2
		Hotkey, %JoystickNumber%Joy%A_Index%, trigger_hook, "On I2"
	}

ch := InputHook("V L0 I2") ; An input hook that is used to intercept the F15 that is sent by the controller buttons
ch.KeyOpt("{F15}","NS")
ch.OnKeyDown := Func("OnGamepadUsed")
; A separate input hook used for intercepting all keyboard keys (excluding modifiers)
; it has a different MinSendLevel to avoid any overlap with the other input hook
ih := InputHook("VE L0 I3")
ih.KeyOpt("{All}", "N")
ih.KeyOpt("{LCtrl}{RCtrl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}", "-N")
ih.OnKeyDown := Func("OnKeyPressed")
ih.Start()
ch.Start()
return

check: ; The subroutine that checks the mouse/POV buttons
	Critical
	MouseGetPos, cx, cy
	if (cx != sx or cy != sy){
		if (cx > (sx+50) or cx < (sx-50) or cy > (sy+50) or cy < (sy-50)){
			OnKeyPressed()
			MouseGetPos, sx, sy
		} 
	}
	
	if (GetKeyState("RButton") or GetKeyState("MButton") 
		or GetKeyState("XButton1") or GetKeyState("XButton2")){
		OnKeyPressed()
	}
	
	if (dpad != 0){ ; Only check POV state if it exists
		joy_p := GetKeyState(JoyStickNumber . "JoyPOV")
		if(joy_p != -1 && joy_p != "")
			OnGamepadUsed()
	}
	return
	
	
trigger_hook: ; The subroutine that the controller buttons use to trigger the input hook
	Critical
	SendLevel 2
	SetKeyDelay, 10
	Send, {Blind}{F15}
	return
	
	
check_axes:
	joyX := GetKeyState(JoystickNumber . "JoyX")
	joyY := GetKeyState(JoystickNumber . "JoyY")
	
	if (axis_3 != 0){ ; Only check the state if the axis exists
		joyZ := GetKeyState(JoystickNumber . "JoyZ")
		if (!IsValueSimilar(previousJoyZ, joyZ)){
			OnGamepadUsed()
			previousJoyZ := joyZ
		}
	}
	
	if (axis_4 != 0){
		joyR := GetKeyState(JoystickNumber . "JoyR")
		if (!IsValueSimilar(previousJoyR, joyR)){
			OnGamepadUsed()
			previousJoyR := joyR
		}
	}
	
	if (axis_5 != 0){
		joyU := GetKeyState(JoystickNumber . "JoyU")
		if (!IsValueSimilar(previousJoyU, joyU)){
			OnGamepadUsed()
			previousJoyU := joyU
		}
	}
	
	if (axis_6 != 0){
		joyV := GetKeyState(JoystickNumber . "JoyV")
		if (!IsValueSimilar(previousJoyV, joyV)){
			OnGamepadUsed()
			previousJoyV := joyV
		}
	}
	
	if (!IsValueSimilar(previousJoyX, joyX) || !IsValueSimilar(previousJoyY, joyY))
		OnGamepadUsed()
	
	previousJoyX := joyX
	previousJoyY := joyY
	return


OnKeyPressed(){ ; A function that sends a keystroke to OBS when a keyboard key is pressed/the mouse has moved
	Critical
	SetKeyDelay, 10
	SetTitleMatchMode, 2
	ControlSend, ahk_parent, {Blind}{F13}, OBS ; 'F13' can be changed to whatever key you want
}


OnGamepadUsed(){ ; A function that sends a keystroke to OBS when a controller button is pressed/an analog stick has moved
	Critical
	SetKeyDelay, 10
	SetTitleMatchMode, 2
	ControlSend, ahk_parent, {Blind}{F14}, OBS ; 'F14' can be changed to whatever key you want
}


IsValueSimilar(var1, var2){ ; A function that compares the previous and current states of the controller axes
	return ((var1 - 7) <= var2) && ((var1 + 7) >= var2)
}


Exit(){
	global
	; Technically speaking the input hook starts collecting input and never stops, as there are no end keys or anything that stops input collection
	; which means the input is never terminated, so I am unsure if these two lines are necessary, so I left them just in case.
	ch.Stop()
	ih.Stop()
}
