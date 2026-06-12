#SingleInstance Force
SetWorkingDir %A_ScriptDir%

; ============================================================================
; CONFIGURATION
; ============================================================================
global portPIA := ""
global portQbit := ""
global checkInterval := 3600000  ; 1 hour in milliseconds (3600000)
global autoUpdate := true        ; Set to false to require manual confirmation

; Program paths (loaded from settings.ini or defaults)
global piaPath := ""
global qbitPath := ""
global settingsFile := A_ScriptDir . "\settings.ini"

; Initialize and start
LoadSettings()
InitializeTrayMenu()
CheckAndUpdatePorts()
SetTimer, CheckAndUpdatePorts, %checkInterval%
return

; ============================================================================
; FUNCTIONS
; ============================================================================

LoadSettings() {
    global piaPath, qbitPath, settingsFile, checkInterval, autoUpdate

    ; Load PIA path (default if not found)
    IniRead, piaPath, %settingsFile%, Paths, PIAPath, C:\Program Files\Private Internet Access\piactl.exe

    ; Load qBittorrent path (default if not found)
    IniRead, qbitPath, %settingsFile%, Paths, QbitPath, C:\Program Files\qBittorrent\qbittorrent.exe

    ; Load check interval (default 1 hour)
    IniRead, checkInterval, %settingsFile%, Settings, CheckInterval, 3600000

    ; Load auto-update setting
    IniRead, autoUpdate, %settingsFile%, Settings, AutoUpdate, 1
    autoUpdate := (autoUpdate = 1)
}

SaveSettings() {
    global piaPath, qbitPath, settingsFile, checkInterval, autoUpdate

    ; Save paths
    IniWrite, %piaPath%, %settingsFile%, Paths, PIAPath
    IniWrite, %qbitPath%, %settingsFile%, Paths, QbitPath

    ; Save settings
    IniWrite, %checkInterval%, %settingsFile%, Settings, CheckInterval
    autoUpdateValue := autoUpdate ? 1 : 0
    IniWrite, %autoUpdateValue%, %settingsFile%, Settings, AutoUpdate
}

ShowSettingsGUI() {
    global piaPath, qbitPath, settingsFile, checkInterval
    global GuiPiaPath, GuiQbitPath, GuiInterval, GuiIntervalUpDown

    ; Convert interval to minutes for display
    intervalMinutes := checkInterval / 60000

    ; Create GUI
    Gui, Settings:New, , Port Forwarder Settings
    Gui, Settings:Font, s10

    ; PIA Path
    Gui, Settings:Add, Text, x10 y10 w400, Private Internet Access (piactl.exe) Path:
    Gui, Settings:Add, Edit, x10 y30 w400 h25 vGuiPiaPath, %piaPath%
    Gui, Settings:Add, Button, x415 y30 w80 h25 gBrowsePIA, Browse...

    ; qBittorrent Path
    Gui, Settings:Add, Text, x10 y70 w400, qBittorrent Executable Path:
    Gui, Settings:Add, Edit, x10 y90 w400 h25 vGuiQbitPath, %qbitPath%
    Gui, Settings:Add, Button, x415 y90 w80 h25 gBrowseQbit, Browse...

    ; Check Interval
    Gui, Settings:Add, Text, x10 y130 w200, Check Interval (minutes):
    Gui, Settings:Add, Edit, x220 y130 w100 h25 vGuiInterval Number, %intervalMinutes%
    Gui, Settings:Add, UpDown, vGuiIntervalUpDown Range1-1440, %intervalMinutes%
    Gui, Settings:Add, Text, x330 y135 w165 cGray, (1 min - 24 hours)

    ; Info text
    Gui, Settings:Add, Text, x10 y165 w485 +Wrap cGray, Note: Changes will be saved to settings.ini. Restart may be required for interval changes to take effect.

    ; Buttons
    Gui, Settings:Add, Button, x10 y210 w100 h30 gSaveSettingsGUI Default, Save
    Gui, Settings:Add, Button, x120 y210 w100 h30 gCancelSettingsGUI, Cancel
    Gui, Settings:Add, Button, x230 y210 w100 h30 gTestPaths, Test Paths

    ; Show GUI
    Gui, Settings:Show, w510 h255
    return

    TestPaths:
        Gui, Settings:Submit, NoHide

        ; Test PIA path
        if (!FileExist(GuiPiaPath)) {
            MsgBox, 48, Path Not Found, PIA path does not exist:`n%GuiPiaPath%
            return
        }

        ; Test qBittorrent path
        if (!FileExist(GuiQbitPath)) {
            MsgBox, 48, Path Not Found, qBittorrent path does not exist:`n%GuiQbitPath%
            return
        }

        ; Test PIA command
        try {
            shell := ComObjCreate("WScript.Shell")
            exec := shell.Exec("""" . GuiPiaPath . """ get portforward")
            output := exec.StdOut.ReadAll()
            output := Trim(output, " `t`r`n")

            if output is integer
            {
                MsgBox, 64, Success,
                (
                Both paths are valid!

                PIA port forward: %output%
                qBittorrent: Found at specified path

                You can now save these settings.
                )
            } else {
                MsgBox, 48, Warning,
                (
                Paths exist, but PIA returned unexpected output:
                %output%

                Make sure PIA VPN is running and port forwarding is enabled.
                )
            }
        }
        catch e {
            MsgBox, 48, Error, Failed to test PIA command:`n%e%
        }
    return

    BrowsePIA:
        Gui, Settings:Submit, NoHide
        FileSelectFile, SelectedFile, 3, %GuiPiaPath%, Select piactl.exe, Executables (*.exe)
        if (SelectedFile != "") {
            GuiControl, Settings:, GuiPiaPath, %SelectedFile%
        }
    return

    BrowseQbit:
        Gui, Settings:Submit, NoHide
        FileSelectFile, SelectedFile, 3, %GuiQbitPath%, Select qbittorrent.exe, Executables (*.exe)
        if (SelectedFile != "") {
            GuiControl, Settings:, GuiQbitPath, %SelectedFile%
        }
    return

    SaveSettingsGUI:
        Gui, Settings:Submit

        ; Validate paths exist
        if (!FileExist(GuiPiaPath)) {
            MsgBox, 48, Invalid Path, PIA path does not exist:`n%GuiPiaPath%
            return
        }
        if (!FileExist(GuiQbitPath)) {
            MsgBox, 48, Invalid Path, qBittorrent path does not exist:`n%GuiQbitPath%
            return
        }

        ; Validate interval
        if (GuiInterval < 1 || GuiInterval > 1440) {
            MsgBox, 48, Invalid Interval, Check interval must be between 1 and 1440 minutes (24 hours)
            return
        }

        ; Update global variables
        piaPath := GuiPiaPath
        qbitPath := GuiQbitPath

        ; Update check interval and restart timer if changed
        newInterval := GuiInterval * 60000
        if (newInterval != checkInterval) {
            checkInterval := newInterval
            SetTimer, CheckAndUpdatePorts, Off
            SetTimer, CheckAndUpdatePorts, %checkInterval%
        }

        ; Save to file
        SaveSettings()

        ; Close GUI
        Gui, Settings:Destroy

        ; Show confirmation
        TrayTip, Settings Saved, Settings have been updated successfully, 3, 1
    return

    CancelSettingsGUI:
    SettingsGuiClose:
        Gui, Settings:Destroy
    return
}

InitializeTrayMenu() {
    global autoUpdate

    Menu, Tray, NoStandard
    Menu, Tray, Add, PIA Port: ---, MenuHandler
    Menu, Tray, Disable, PIA Port: ---
    Menu, Tray, Add, qBit Port: ---, MenuHandler
    Menu, Tray, Disable, qBit Port: ---
    Menu, Tray, Add
    Menu, Tray, Add, Check Ports Now, MenuHandler
    Menu, Tray, Add, Auto-Update: ON, MenuHandler
    if (autoUpdate)
        Menu, Tray, Check, Auto-Update: ON
    Menu, Tray, Add
    Menu, Tray, Add, Settings, MenuHandler
    Menu, Tray, Add, Exit, MenuHandler
}

UpdateTrayMenu(piaPort, qbitPort) {
    static lastPiaText := "PIA Port: ---"
    static lastQbitText := "qBit Port: ---"

    ; Build new menu text
    newPiaText := "PIA Port: " . (piaPort = "" ? "ERROR" : piaPort)
    newQbitText := "qBit Port: " . (qbitPort = "" ? "ERROR" : qbitPort)

    ; Update PIA port menu item
    Menu, Tray, Rename, %lastPiaText%, %newPiaText%
    lastPiaText := newPiaText

    ; Update qBit port menu item
    Menu, Tray, Rename, %lastQbitText%, %newQbitText%
    lastQbitText := newQbitText
}

MenuHandler:
    global autoUpdate

    if (A_ThisMenuItem = "Check Ports Now") {
        CheckAndUpdatePorts()
    } else if (A_ThisMenuItem = "Auto-Update: ON") {
        ; Toggle auto-update
        autoUpdate := !autoUpdate
        if (autoUpdate) {
            Menu, Tray, Check, Auto-Update: ON
            TrayTip, Auto-Update Enabled, Port changes will be applied automatically, 3, 1
        } else {
            Menu, Tray, Uncheck, Auto-Update: ON
            TrayTip, Auto-Update Disabled, You will be prompted before port changes, 3, 1
        }
        ; Save the setting
        SaveSettings()
    } else if (A_ThisMenuItem = "Settings") {
        ShowSettingsGUI()
    } else if (A_ThisMenuItem = "Exit") {
        ExitApp
    }
return

CheckAndUpdatePorts() {
    global portPIA, portQbit

    ; Get PIA port
    portPIA := GetPIAPort()
    if (portPIA = "") {
        UpdateTrayTooltip("ERROR: Could not get PIA port", "")
        UpdateTrayMenu("ERROR", portQbit)
        return
    }

    ; Get qBittorrent port
    portQbit := GetQbitPort()
    if (portQbit = "") {
        UpdateTrayTooltip(portPIA, "ERROR: Could not read qBit config")
        UpdateTrayMenu(portPIA, "ERROR")
        return
    }

    ; Update tray menu and tooltip
    UpdateTrayTooltip(portPIA, portQbit)
    UpdateTrayMenu(portPIA, portQbit)

    ; Check if ports match
    if (portPIA != portQbit) {
        PromptPortChange(portPIA, portQbit)
    }
}

GetPIAPort() {
    global piaPath

    try {
        ; Check if file exists
        if (!FileExist(piaPath)) {
            MsgBox, 16, Error, PIA executable not found at:`n%piaPath%`n`nPlease configure the correct path in Settings.
            return ""
        }

        ; Execute command and read output
        shell := ComObjCreate("WScript.Shell")
        exec := shell.Exec("""" . piaPath . """ get portforward")
        output := exec.StdOut.ReadAll()

        ; Trim whitespace and newlines
        output := Trim(output, " `t`r`n")

        ; Validate it's a number
        if output is not integer
        {
            MsgBox, 16, Error, Invalid PIA port received: %output%
            return ""
        }

        ; Validate port range (1024-65535)
        if (output < 1024 || output > 65535) {
            MsgBox, 16, Error, PIA port out of valid range: %output%
            return ""
        }

        return output
    }
    catch e {
        MsgBox, 16, Error, Failed to get PIA port:`n%e%
        return ""
    }
}

GetQbitPort() {
    try {
        configPath := A_AppData . "\qBittorrent\qBittorrent.ini"

        ; Check if config file exists
        if (!FileExist(configPath)) {
            MsgBox, 16, Error, qBittorrent config not found at:`n%configPath%
            return ""
        }

        ; Read port from config
        IniRead, port, %configPath%, BitTorrent, Session\Port, ERROR

        if (port = "ERROR") {
            MsgBox, 16, Error, Could not read port from qBittorrent config
            return ""
        }

        ; Validate it's a number
        if port is not integer
        {
            MsgBox, 16, Error, Invalid qBittorrent port in config: %port%
            return ""
        }

        return port
    }
    catch e {
        MsgBox, 16, Error, Failed to get qBittorrent port:`n%e%
        return ""
    }
}

UpdateTrayTooltip(piaPort, qbitPort) {
    if (qbitPort = "") {
        Menu, Tray, Tip, PIA: %piaPort%`nqBIT: ERROR
    } else if (piaPort = qbitPort) {
        Menu, Tray, Tip, PIA: %piaPort%`nqBIT: %qbitPort%`n✓ Ports Match
    } else {
        Menu, Tray, Tip, PIA: %piaPort%`nqBIT: %qbitPort%`n⚠ Ports Mismatch
    }
}

PromptPortChange(newPort, currentPort) {
    global autoUpdate

    ; If autoUpdate is enabled, just update automatically
    if (autoUpdate) {
        TrayTip, Port Change Detected, Automatically updating qBittorrent from %currentPort% to %newPort%, 5, 1
        UpdateQbitPort(newPort)
        return
    }

    ; Otherwise, prompt user
    MsgBox, 4, Port Mismatch Detected,
    (
    Port mismatch detected:

    qBittorrent Port: %currentPort%
    PIA VPN Port: %newPort%

    Do you want to update qBittorrent to use port %newPort%?

    This will:
    - Close qBittorrent
    - Update the port configuration
    - Restart qBittorrent
    )

    IfMsgBox Yes
    {
        UpdateQbitPort(newPort)
    }
    IfMsgBox No
    {
        ; User declined, do nothing
        return
    }
}

UpdateQbitPort(newPort) {
    global portQbit, portPIA

    try {
        oldPort := portQbit

        ; Close qBittorrent
        if (!CloseQbittorrent()) {
            TrayTip, Error, Failed to close qBittorrent, 5, 3
            return
        }

        Sleep, 500  ; Wait for process to fully close

        ; Update config file
        configPath := A_AppData . "\qBittorrent\qBittorrent.ini"
        IniWrite, %newPort%, %configPath%, BitTorrent, Session\Port

        Sleep, 300  ; Wait for file write

        ; Restart qBittorrent
        if (!StartQbittorrent()) {
            TrayTip, Error, Failed to restart qBittorrent, 5, 3
            return
        }

        ; Update global variable
        portQbit := newPort

        ; Show success message with timestamp
        FormatTime, timestamp, , yyyy-MM-dd HH:mm:ss
        TrayTip, Port Updated Successfully,
        (
        %timestamp%
        Changed: %oldPort% → %newPort%
        qBittorrent restarted
        ), 8, 1

        ; Update tooltip
        UpdateTrayTooltip(portPIA, portQbit)

        ; Log to file for debugging
        LogPortChange(oldPort, newPort, timestamp)
    }
    catch e {
        TrayTip, Error, Failed to update qBittorrent port: %e%, 5, 3
    }
}

LogPortChange(oldPort, newPort, timestamp) {
    logFile := A_ScriptDir . "\port_changes.log"
    logLine := timestamp . " - Port changed from " . oldPort . " to " . newPort . "`n"
    FileAppend, %logLine%, %logFile%
}

CloseQbittorrent() {
    try {
        ; Check if qBittorrent is running
        Process, Exist, qbittorrent.exe
        if (ErrorLevel = 0) {
            return true  ; Already closed
        }

        ; Try graceful close first
        WinClose, ahk_exe qbittorrent.exe

        ; Wait up to 5 seconds for graceful close
        timeout := 5000
        elapsed := 0
        while (elapsed < timeout) {
            Process, Exist, qbittorrent.exe
            if (ErrorLevel = 0)
                return true
            Sleep, 100
            elapsed += 100
        }

        ; Force kill if still running
        Run, taskkill /F /IM qbittorrent.exe, , Hide
        Sleep, 500

        ; Verify it's closed
        Process, Exist, qbittorrent.exe
        return (ErrorLevel = 0)
    }
    catch e {
        return false
    }
}

StartQbittorrent() {
    global qbitPath

    try {
        ; Check if file exists
        if (!FileExist(qbitPath)) {
            MsgBox, 16, Error, qBittorrent executable not found at:`n%qbitPath%`n`nPlease configure the correct path in Settings.
            return false
        }

        ; Start qBittorrent
        Run, "%qbitPath%"
        return true
    }
    catch e {
        return false
    }
}

Trim(str, chars := " `t") {
    return RegExReplace(str, "^[" . chars . "]+|[" . chars . "]+$")
}
