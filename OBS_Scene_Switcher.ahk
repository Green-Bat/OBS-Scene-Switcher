#Warn
#SingleInstance, Force

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
		MsgBox, Could not detect any joysticks!
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

Loop, % joy_buttons { ; Turns all the controller buttons into hotkeys
		Hotkey, % JoystickNumber "Joy" A_Index, OnGamepadUsed, On
	}

; An input hook used for intercepting all keyboard keys (excluding modifiers)
ih := InputHook("V L0 I")
ih.KeyOpt("{All}", "N")
ih.KeyOpt("{LCtrl}{RCtrl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}", "-N")
ih.OnKeyDown := Func("OnKeyPressed")
ih.Start()
return

~XButton2::
~XButton1::
~MButton::
~RButton::
~LButton::
Sleep, 150
OnKeyPressed()
return

;**********************************/Timers/*******************************************************

check_mouse: ; The subroutine that checks mouse movement
	MouseGetPos, cx, cy
	if (cx != sx or cy != sy){
		if (cx > (sx+50) or cx < (sx-50) or cy > (sy+50) or cy < (sy-50)){
			OnKeyPressed()
			MouseGetPos, sx, sy
		} 
	}
	return
	
check_axes:
	joyX := GetKeyState(JoystickNumber . "JoyX")
	joyY := GetKeyState(JoystickNumber . "JoyY")
	if (!IsValueSimilar(previousJoyX, joyX) || !IsValueSimilar(previousJoyY, joyY)){
		OnGamepadUsed()
		previousJoyX := joyX
		previousJoyY := joyY
	}
	
	if (axis_3 != 0){ ; Only check the state if the axis exists
		joyZ := GetKeyState(JoystickNumber . "JoyZ")
		joyR := GetKeyState(JoystickNumber . "JoyR")
		if (!IsValueSimilar(previousJoyZ, joyZ) || !IsValueSimilar(previousJoyR, joyR)){
			OnGamepadUsed()
			previousJoyZ := joyZ
			previousJoyR := joyR
		}
	}
	
	if (dpad != 0){ ; Only check POV state if it exists
		joy_p := GetKeyState(JoyStickNumber . "JoyPOV")
		if(joy_p != -1 && joy_p != "")
			OnGamepadUsed()
	}
	return
	
;**********************************/Functions/*******************************************************

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

; Kill-switch Shift+F4
+F4::ExitApp
