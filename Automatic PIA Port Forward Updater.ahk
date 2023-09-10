#SingleInstance Force
SetWorkingDir %A_ScriptDir%

gosub MAIN

MAIN:

portPIA := ComObjCreate("WScript.Shell").Exec("C:\Progra~1\PRIVAT~1\piactl get portforward").StdOut.ReadAll()
StringTrimRight, portPIA_CLEAN, portPIA, 2
IniRead, Qport, %AppData%\qBittorrent\qBittorrent.ini, BitTorrent, Session\Port
Menu, tray, Add, PIA: %portPIA_CLEAN%, RunCommand
Menu, tray, Add, qBIT: %Qport%, RunCommand
Menu, tray, Add, Check Ports Now, RunCommand
Menu, Tray, Tip , PIA: %portPIA_CLEAN%`nqBIT: %Qport%
sleep, 100
If Qport = %portPIA_CLEAN%
	gosub Sleep
else
	gosub Setport
RunCommand:
    if (A_ThisMenuItem = "Check Ports Now")
        gosub MAIN
Return

Setport:
MsgBox, 1, PF_Watchdog, qBittorent Port: %Qport%`nPIA VPN Port: %portPIA_CLEAN%`nQuitting qBittorent and changing port., 5
IfMsgBox OK
{
	gosub updatePORT
}
IfMsgBox Cancel
{
	ExitApp
}
gosub updatePORT

updatePORT:
Runwait, Taskkill /IM qBit* /F
Sleep, 300
IniWrite, %portPIA_CLEAN%, %AppData%\qBittorrent\qBittorrent.ini, BitTorrent, Session\Port
Sleep, 300
Run, C:\Program Files\qBittorrent\qbittorrent.exe
gosub Sleep


Sleep:
Sleep, 3600000
gosub MAIN