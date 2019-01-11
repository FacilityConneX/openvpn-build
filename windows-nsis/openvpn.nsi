; ****************************************************************************
; * Copyright (C) 2002-2010 OpenVPN Technologies, Inc.                       *
; * Copyright (C)      2012 Alon Bar-Lev <alon.barlev@gmail.com>             *
; *  This program is free software; you can redistribute it and/or modify    *
; *  it under the terms of the GNU General Public License version 2          *
; *  as published by the Free Software Foundation.                           *
; ****************************************************************************

; OpenVPN install script for Windows, using NSIS

SetCompressor /SOLID lzma

!define PRODUCT_PUBLISHER "FacilityConnex LLC"

;define PACKAGE_NAME2 for replacement of visible text where possible
!define PACKAGE_NAME2 "FCXTunnel"

;define PACKAGE_NAME0 for replacement of visible text where possible
!define PACKAGE_NAME0 "OpenVPN"

; !addplugindir ensures that nsProcess.nsh and DotNetChecker.nsh can be included
!addplugindir .

; Modern user interface
!include "MUI2.nsh"

; Install for all users. MultiUser.nsh also calls SetShellVarContext to point 
; the installer to global directories (e.g. Start menu, desktop, etc.)
!define MULTIUSER_EXECUTIONLEVEL Admin
!include "MultiUser.nsh"

; WinMessages.nsh is needed to send WM_CLOSE to the GUI if it is still running
!include "WinMessages.nsh"

; nsProcess.nsh to detect whether OpenVPN process is running ( http://nsis.sourceforge.net/NsProcess_plugin )
!include "nsProcess.nsh"

; DotNetChecker.nsh to detect whether .net 4.0 is enabled, which is required for openvpnserv2 ( https://github.com/ReVolly/NsisDotNetChecker )
!include "DotNetChecker.nsh"

; x64.nsh for architecture detection
!include "x64.nsh"

; Read the command-line parameters
!insertmacro GetParameters
!insertmacro GetOptions

; Default service settings
!define OPENVPN_CONFIG_EXT "ovpn"

;--------------------------------
;Configuration

;General

; Package name as shown in the installer GUI
Name "${PACKAGE_NAME2} ${VERSION_STRING}"

; On 64-bit Windows the constant $PROGRAMFILES defaults to
; C:\Program Files (x86) and on 32-bit Windows to C:\Program Files. However,
; the .onInit function (see below) takes care of changing this for 64-bit 
; Windows.
InstallDir "$PROGRAMFILES\${PACKAGE_NAME2}"

; Installer filename
OutFile "${OUTPUT}"

ShowInstDetails show
ShowUninstDetails show

;Remember install folder
InstallDirRegKey HKLM "SOFTWARE\${PACKAGE_NAME0}" ""

;--------------------------------
;Modern UI Configuration

; Compile-time constants which we'll need during install
!define MUI_WELCOMEPAGE_TEXT "This wizard will guide you through the installation of ${PACKAGE_NAME2} ${SPECIAL_BUILD}, an Encrypted Tunnel VPN package by FacilityConneX LLC.$\r$\n$\r$\nNote that the Windows version of ${PACKAGE_NAME2} will only run on Windows Vista, or higher.$\r$\n$\r$\n$\r$\n"

!define MUI_COMPONENTSPAGE_TEXT_TOP "Select the components to install/upgrade.  Stop any ${PACKAGE_NAME2} processes or the ${PACKAGE_NAME2} service if it is running.  All DLLs are installed locally."

!define MUI_COMPONENTSPAGE_SMALLDESC
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\doc\INSTALL-win32.txt"

!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_ABORTWARNING
!define MUI_ICON "icon.ico"
!define MUI_UNICON "icon.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "install-whirl.bmp"
!define MUI_UNFINISHPAGE_NOAUTOCLOSE

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${OPENVPN_ROOT}\share\doc\openvpn\license.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

;--------------------------------
;Languages
 
!insertmacro MUI_LANGUAGE "English"
  
;--------------------------------
;Language Strings

LangString DESC_SecOpenVPNUserSpace ${LANG_ENGLISH} "Install ${PACKAGE_NAME2} user-space components."

LangString DESC_SecOpenVPNGUI ${LANG_ENGLISH} "Install ${PACKAGE_NAME2} GUI"

LangString DESC_SecTAP ${LANG_ENGLISH} "Install/upgrade the TAP virtual device driver."

LangString DESC_SecOpenVPNEasyRSA ${LANG_ENGLISH} "Install EasyRSA 2 scripts for X509 certificate management."

LangString DESC_SecOpenSSLDLLs ${LANG_ENGLISH} "Install OpenSSL DLLs locally (may be omitted if DLLs are already installed globally)."

LangString DESC_SecLZODLLs ${LANG_ENGLISH} "Install LZO DLLs locally (may be omitted if DLLs are already installed globally)."

LangString DESC_SecPKCS11DLLs ${LANG_ENGLISH} "Install PKCS#11 helper DLLs locally (may be omitted if DLLs are already installed globally)."

LangString DESC_SecService ${LANG_ENGLISH} "Install the ${PACKAGE_NAME2} service wrappers"

LangString DESC_SecInteractiveService ${LANG_ENGLISH} "Install the ${PACKAGE_NAME2} Interactive Service"

LangString DESC_SecOpenSSLUtilities ${LANG_ENGLISH} "Install the OpenSSL Utilities (used for generating public/private key pairs)."

LangString DESC_SecAddShortcuts ${LANG_ENGLISH} "Add ${PACKAGE_NAME2} shortcuts to the current user's Start Menu."

LangString DESC_SecFileAssociation ${LANG_ENGLISH} "Register ${PACKAGE_NAME2} config file association (*.${OPENVPN_CONFIG_EXT})"

LangString DESC_SecLaunchGUIOnLogon ${LANG_ENGLISH} "Launch ${PACKAGE_NAME2} GUI on user logon."

LangString DESC_SecDisableSavePass ${LANG_ENGLISH} "Do not allow passwords to be saved in ${PACKAGE_NAME2} GUI."
;--------------------------------
;Reserve Files
  
;Things that need to be extracted on first (keep these lines before any File command!)
;Only useful for BZIP2 compression

ReserveFile "install-whirl.bmp"

;--------------------------------
;Macros

!macro SelectByParameter SECT PARAMETER DEFAULT
	${GetOptions} $R0 "/${PARAMETER}=" $0
	${If} ${DEFAULT} == 0
		${If} $0 == 1
			!insertmacro SelectSection ${SECT}
		${EndIf}
	${Else}
		${If} $0 != 0
			!insertmacro SelectSection ${SECT}
		${EndIf}
	${EndIf}
!macroend

!macro WriteRegStringIfUndef ROOT SUBKEY KEY VALUE
	Push $R0
	ReadRegStr $R0 "${ROOT}" "${SUBKEY}" "${KEY}"
	${If} $R0 == ""
		WriteRegStr "${ROOT}" "${SUBKEY}" "${KEY}" '${VALUE}'
	${EndIf}
	Pop $R0
!macroend

!macro WriteRegDWORDIfUndef ROOT SUBKEY KEY VALUE
	Push $R0
	ReadRegDWORD $R0 "${ROOT}" "${SUBKEY}" "${KEY}"
	${If} $R0 == ""
		WriteRegDWORD "${ROOT}" "${SUBKEY}" "${KEY}" '${VALUE}'
	${EndIf}
	Pop $R0
!macroend

!macro DelRegKeyIfUnchanged ROOT SUBKEY VALUE
	Push $R0
	ReadRegStr $R0 "${ROOT}" "${SUBKEY}" ""
	${If} $R0 == '${VALUE}'
		DeleteRegKey "${ROOT}" "${SUBKEY}"
	${EndIf}
	Pop $R0
!macroend

Function CacheServiceState
	; We will set the defaults for a service only if it did not exist before:
	; otherwise we restore the previous state. Startuptype is cached for
	; OpenVPNService as we need to reinstall it, and it might be pointing to
	; the old legacy service.
	Var /GLOBAL iservice_existed
	Var /GLOBAL iservice_was_running
	Var /GLOBAL legacy_service_existed
	Var /GLOBAL legacy_service_was_running
	Var /GLOBAL service_existed
	Var /GLOBAL service_starttype
	Var /GLOBAL service_was_running

	DetailPrint "Caching service states"

	SimpleSC::ExistsService "FCXTunnelServiceInteractive"
	Pop $iservice_existed
	SimpleSC::GetServiceStatus "FCXTunnelServiceInteractive"
	Pop $0
	Pop $iservice_was_running

	SimpleSC::ExistsService "FCXTunnelServiceLegacy"
	Pop $legacy_service_existed
	SimpleSC::GetServiceStatus "FCXTunnelServiceLegacy"
	Pop $0
	Pop $legacy_service_was_running

	SimpleSC::ExistsService "FCXTunnelService"
	Pop $service_existed
	SimpleSC::GetServiceStartType "FCXTunnelService"
	Pop $0
	Pop $service_starttype
	SimpleSC::GetServiceStatus "FCXTunnelService"
	Pop $0
	Pop $service_was_running
FunctionEnd

Function RestoreServiceState

	${If} $iservice_was_running == 4
	${OrIf} $iservice_existed != 0
		DetailPrint "Starting FCXTunnel Interactive Service"
		SimpleSC::StartService "FCXTunnelServiceInteractive" "" 5
	${EndIf}

	${If} $legacy_service_was_running == 4
		DetailPrint "Restarting FCXTunnel Legacy Service"
		SimpleSC::StartService "FCXTunnelServiceLegacy" "" 10
	${EndIf}

	${If} $service_existed == 0
		DetailPrint "Restoring starttype of FCXTunnel Service"
		SimpleSC::SetServiceStartType "FCXTunnelService" $service_starttype

		${If} $service_was_running == 4
			DetailPrint "Restarting FCXTunnel Service"
			SimpleSC::StartService "FCXTunnelService" "" 10
		${EndIf}
	${EndIf}

FunctionEnd

Function StopServices
	DetailPrint "Stopping FCXTunnel services..."
	SimpleSC::StopService "FCXTunnelServiceInteractive" 0 10
	SimpleSC::StopService "FCXTunnelServiceLegacy" 0 10
	SimpleSC::StopService "FCXTunnelService" 0 10
FunctionEnd

;--------------------
;Pre-install section

Section -pre
	Push $0 ; for FindWindow
	FindWindow $0 "OpenVPN-GUI"
	StrCmp $0 0 guiNotRunning

	MessageBox MB_YESNO|MB_ICONEXCLAMATION "To perform the specified operation, the FCXTunnel GUI needs to be closed. You will have to restart it manually after the installation has completed. Shall I close it?" /SD IDYES IDYES guiEndYes
	Quit

	guiEndYes:
		DetailPrint "Closing FCXTunnel-GUI..."
		; user wants to close GUI as part of install/upgrade
		FindWindow $0 "OpenVPN-GUI"
		IntCmp $0 0 guiNotRunning
		SendMessage $0 ${WM_CLOSE} 0 0
		Sleep 100
		Goto guiEndYes

	guiNotRunning:
		; Store the current state of OpenVPN services
		Call CacheServiceState
		Call StopServices

		Sleep 3000

		; check for running openvpn.exe processes
		${nsProcess::FindProcess} "openvpn.exe" $R0
		${If} $R0 == 0
			MessageBox MB_OK|MB_ICONEXCLAMATION "The installation cannot continue as FCXTunnel is currently running. Please close all FCXTunnel instances and re-run the installer."
			Call RestoreServiceState
			Quit
		${EndIf}

		; openvpn.exe + GUI not running/closed successfully, carry on with install/upgrade
	
		; Delete previous start menu folder
		RMDir /r "$SMPROGRAMS\${PACKAGE_NAME2}"

	Pop $0 ; for FindWindow

SectionEnd

Section /o "-workaround" SecAddShortcutsWorkaround
	; this section should be selected as SecAddShortcuts
	; as we don't want to move SecAddShortcuts to top of selection
SectionEnd

Section /o "-launchondummy" SecLaunchGUIOnLogon0
	; this section should be selected as SecLaunchGUIOnLogon
	; this is here as we don't want to move that section to the top
SectionEnd

; We do not make this hidden as its informative to have displayed, but make it readonly (always selected)
Section "${PACKAGE_NAME2} User-Space Components" SecOpenVPNUserSpace

	SectionIn RO ; section cannot be unchecked by user
	SetOverwrite on

	SetOutPath "$INSTDIR\bin"
	${If} ${RunningX64}
		File "${OPENVPN_ROOT_X86_64}\bin\openvpn.exe"
	${Else}
		File "${OPENVPN_ROOT_I686}\bin\openvpn.exe"
	${EndIf}

	SetOutPath "$INSTDIR\doc"
	File "INSTALL-win32.txt"
	File "${OPENVPN_ROOT_I686}\share\doc\openvpn\openvpn.8.html"

	${If} ${SectionIsSelected} ${SecAddShortcutsWorkaround}
		CreateDirectory "$SMPROGRAMS\${PACKAGE_NAME2}\Documentation"
		CreateShortCut "$SMPROGRAMS\${PACKAGE_NAME2}\Documentation\${PACKAGE_NAME2} Manual Page.lnk" "$INSTDIR\doc\openvpn.8.html"
		CreateShortCut "$SMPROGRAMS\${PACKAGE_NAME2}\Documentation\${PACKAGE_NAME2} Windows Notes.lnk" "$INSTDIR\doc\INSTALL-win32.txt"
	${EndIf}

	; Setup config, log directories, utilities and interactive service
	Call CoreSetup

SectionEnd

Section /o "${PACKAGE_NAME2} Service" SecService

	SetOverwrite on

	DetailPrint "Removing FCXTunnel Service..."
	SimpleSC::RemoveService "FCXTunnelService"

	SetOutPath "$INSTDIR\bin"
	; Copy openvpnserv2.exe for automatic service
	File /oname=openvpnserv2.exe "${OPENVPNSERV2_EXECUTABLE}"

	DetailPrint "Installing FCXTunnel Service..."
	;JP11Jan2019 - Set Tunnel to auto-start (2). from manual (3)
	SimpleSC::InstallService "FCXTunnelService" "FCXTunnelService" "16" "2" '"$INSTDIR\bin\openvpnserv2.exe"' "tap0901/dhcp" "" ""
SectionEnd

Function CoreSetup

	SetOverwrite on

	SetOutPath "$INSTDIR\bin"
	; Copy openvpnserv.exe for interactive service
	${If} ${RunningX64}
		File "${OPENVPN_ROOT_X86_64}\bin\openvpnserv.exe"
	${Else}
		File "${OPENVPN_ROOT_I686}\bin\openvpnserv.exe"
	${EndIf}

	SetOutPath "$INSTDIR\config"

	FileOpen $R0 "$INSTDIR\config\README.txt" w
	FileWrite $R0 "This directory or its subdirectories should contain ${PACKAGE_NAME2}$\r$\n"
	FileWrite $R0 "configuration files each having an extension of .${OPENVPN_CONFIG_EXT}$\r$\n"
	FileWrite $R0 "$\r$\n"
	FileWrite $R0 "When ${PACKAGE_NAME2} is started as a service, a separate ${PACKAGE_NAME2}$\r$\n"
	FileWrite $R0 "process will be instantiated for each configuration file.$\r$\n"
	FileWrite $R0 "$\r$\n"
	FileWrite $R0 "When ${PACKAGE_NAME2} GUI is started configs in this directory are added$\r$\n"
	FileWrite $R0 "to the list of available connections$\r$\n"
	FileClose $R0

	SetOutPath "$INSTDIR\sample-config"
	File "${OPENVPN_ROOT_I686}\share\doc\openvpn\sample\sample.${OPENVPN_CONFIG_EXT}"
	File "${OPENVPN_ROOT_I686}\share\doc\openvpn\sample\client.${OPENVPN_CONFIG_EXT}"
	File "${OPENVPN_ROOT_I686}\share\doc\openvpn\sample\server.${OPENVPN_CONFIG_EXT}"

	CreateDirectory "$INSTDIR\log"
	FileOpen $R0 "$INSTDIR\log\README.txt" w
	FileWrite $R0 "This directory will contain the log files for ${PACKAGE_NAME2}$\r$\n"
	FileWrite $R0 "sessions which are being run as a service.$\r$\n"
	FileWrite $R0 "Logs for connections started by the GUI are kept in USERPROFILE\OpenVPN\log$\r$\n"
	FileClose $R0

	${If} ${SectionIsSelected} ${SecAddShortcutsWorkaround}
		CreateDirectory "$SMPROGRAMS\${PACKAGE_NAME2}\Utilities"
		CreateShortCut "$SMPROGRAMS\${PACKAGE_NAME2}\Utilities\Generate a static ${PACKAGE_NAME2} key.lnk" "$INSTDIR\bin\openvpn.exe" '--pause-exit --verb 3 --genkey --secret "$INSTDIR\config\key.txt"' "$INSTDIR\icon.ico" 0
		CreateDirectory "$SMPROGRAMS\${PACKAGE_NAME2}\Shortcuts"
		CreateShortCut "$SMPROGRAMS\${PACKAGE_NAME2}\Shortcuts\${PACKAGE_NAME2} Sample Configuration Files.lnk" "$INSTDIR\sample-config" ""
		CreateShortCut "$SMPROGRAMS\${PACKAGE_NAME2}\Shortcuts\${PACKAGE_NAME2} log file directory.lnk" "$INSTDIR\log" ""
		CreateShortCut "$SMPROGRAMS\${PACKAGE_NAME2}\Shortcuts\${PACKAGE_NAME2} configuration file directory.lnk" "$INSTDIR\config" ""
	${EndIf}

	; set registry parameters for services and GUI
	!insertmacro WriteRegStringIfUndef HKLM "SOFTWARE\${PACKAGE_NAME0}" "config_dir" "$INSTDIR\config" 
	!insertmacro WriteRegStringIfUndef HKLM "SOFTWARE\${PACKAGE_NAME0}" "config_ext"  "${OPENVPN_CONFIG_EXT}"
	WriteRegStr HKLM "SOFTWARE\${PACKAGE_NAME0}" "exe_path"    "$INSTDIR\bin\openvpn.exe"
	!insertmacro WriteRegStringIfUndef HKLM "SOFTWARE\${PACKAGE_NAME0}" "log_dir"     "$INSTDIR\log"
	!insertmacro WriteRegStringIfUndef HKLM "SOFTWARE\${PACKAGE_NAME0}" "priority"    "NORMAL_PRIORITY_CLASS"
	!insertmacro WriteRegStringIfUndef HKLM "SOFTWARE\${PACKAGE_NAME0}" "log_append"  "0"
	!insertmacro WriteRegStringIfUndef HKLM "SOFTWARE\${PACKAGE_NAME0}" "ovpn_admin_group" "OpenVPN Administrators"
	!insertmacro WriteRegDWORDIfUndef  HKLM "SOFTWARE\${PACKAGE_NAME0}" "disable_save_passwords"  0

	${If} $iservice_existed == 0
		; This is required because the install directory may have changed
		SimpleSC::SetServiceBinaryPath "FCXTunnelServiceInteractive" '"$INSTDIR\bin\openvpnserv.exe"'
	${Else}
		;JP11Jan2019 - set to manual start (3)
		DetailPrint "Installing FCXTunnel Interactive Service..."
		SimpleSC::InstallService "FCXTunnelServiceInteractive" "FCXTunnel Interactive Service" "32" "3" '"$INSTDIR\bin\openvpnserv.exe"' "tap0901/dhcp" "" ""
	${EndIf}

	${If} $legacy_service_existed == 0
		SimpleSC::SetServiceBinaryPath "FCXTunnelServiceLegacy" '"$INSTDIR\bin\openvpnserv.exe"'
	${Else}
		DetailPrint "Installing FCXTunnel Legacy Service..."
		SimpleSC::InstallService "FCXTunnelServiceLegacy" "FCXTunnel Legacy Service" "32" "3" '"$INSTDIR\bin\openvpnserv.exe"' "tap0901/dhcp" "" ""
	${EndIf}

FunctionEnd

Section /o "TAP Virtual Ethernet Adapter" SecTAP

	SetOverwrite on
	SetOutPath "$TEMP"

	File /oname=tap-windows.exe "${TAP_WINDOWS_INSTALLER}"

	DetailPrint "Installing TAP (may need confirmation)..."
	nsExec::ExecToLog /OEM '"$TEMP\tap-windows.exe" /S /SELECT_UTILITIES=1'
	Pop $R0 # return value/error/timeout

	Delete "$TEMP\tap-windows.exe"

	WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME0}" "tap" "installed"
SectionEnd

Section /o "${PACKAGE_NAME2} GUI" SecOpenVPNGUI

	SetOverwrite on
	SetOutPath "$INSTDIR\bin"

	${If} ${RunningX64}
		File "${OPENVPN_ROOT_X86_64}\bin\openvpn-gui.exe"
	${Else}
		File "${OPENVPN_ROOT_I686}\bin\openvpn-gui.exe"
	${EndIf}

	${If} ${SectionIsSelected} ${SecAddShortcutsWorkaround}
		CreateDirectory "$SMPROGRAMS\${PACKAGE_NAME2}"
		CreateShortCut "$SMPROGRAMS\${PACKAGE_NAME2}\${PACKAGE_NAME2} GUI.lnk" "$INSTDIR\bin\openvpn-gui.exe" ""
		CreateShortcut "$DESKTOP\${PACKAGE_NAME2} GUI.lnk" "$INSTDIR\bin\openvpn-gui.exe"
	${EndIf}

	; Using active setup registry entries to set/unset GUI to launch on logon for each user.
	; If the user removes the GUI from startup items it will not be re-added or removed on subsequent
	; installs unless the value of "Version" is updated (do this only if/when really necessary).
	; Ref: https://helgeklein.com/blog/2010/04/active-setup-explained/
	WriteRegStr HKLM "Software\Microsoft\Active Setup\Installed Components\${PACKAGE_NAME0}_UserSetup" "" "OpenVPN Setup"
	WriteRegStr HKLM "Software\Microsoft\Active Setup\Installed Components\${PACKAGE_NAME0}_UserSetup" "Version" "2,4,0,0"
	WriteRegDword HKLM "Software\Microsoft\Active Setup\Installed Components\${PACKAGE_NAME0}_UserSetup" "IsInstalled" 0x1
        ; DontAsk = 2 is used to not prompt the user
	WriteRegDword HKLM "Software\Microsoft\Active Setup\Installed Components\${PACKAGE_NAME0}_UserSetup" "DontAsk" 0x2
	${If} ${SectionIsSelected} ${SecLaunchGUIOnLogon0}
		WriteRegStr HKLM "Software\Microsoft\Active Setup\Installed Components\${PACKAGE_NAME0}_UserSetup" "StubPath" "reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v OPENVPN-GUI /t REG_SZ /d $\"$INSTDIR\bin\openvpn-gui.exe$\" /f"
	${Else}
		WriteRegStr HKLM "Software\Microsoft\Active Setup\Installed Components\${PACKAGE_NAME0}_UserSetup" "StubPath" "reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v OPENVPN-GUI /f"
	${EndIf}
SectionEnd

Section "-OpenSSL Utilities" SecOpenSSLUtilities

	SetOverwrite on
	SetOutPath "$INSTDIR\bin"
	${If} ${RunningX64}
		File "${OPENVPN_ROOT_X86_64}\bin\openssl.exe"
	${Else}
		File "${OPENVPN_ROOT_I686}\bin\openssl.exe"
	${EndIf}

SectionEnd

Section /o "EasyRSA 2 Certificate Management Scripts" SecOpenVPNEasyRSA

	SetOverwrite on
	SetOutPath "$INSTDIR\easy-rsa"

	File "${EASYRSA_ROOT}\2.0\openssl-1.0.0.cnf"
	File "${EASYRSA_ROOT}\Windows\vars.bat.sample"

	File "${EASYRSA_ROOT}\Windows\init-config.bat"

	File "${EASYRSA_ROOT}\Windows\README.txt"
	File "${EASYRSA_ROOT}\Windows\build-ca.bat"
	File "${EASYRSA_ROOT}\Windows\build-dh.bat"
	File "${EASYRSA_ROOT}\Windows\build-key-server.bat"
	File "${EASYRSA_ROOT}\Windows\build-key.bat"
	File "${EASYRSA_ROOT}\Windows\build-key-pass.bat"
	File "${EASYRSA_ROOT}\Windows\build-key-pkcs12.bat"
	File "${EASYRSA_ROOT}\Windows\clean-all.bat"
	File "${EASYRSA_ROOT}\Windows\index.txt.start"
	File "${EASYRSA_ROOT}\Windows\revoke-full.bat"
	File "${EASYRSA_ROOT}\Windows\serial.start"

SectionEnd

SectionGroup "!Advanced"

	Section /o "${PACKAGE_NAME2} File Associations" SecFileAssociation
		WriteRegStr HKCR ".${OPENVPN_CONFIG_EXT}" "" "${PACKAGE_NAME0}File"
		WriteRegStr HKCR "${PACKAGE_NAME0}File" "" "${PACKAGE_NAME0} Config File"
		WriteRegStr HKCR "${PACKAGE_NAME0}File\shell" "" "open"
		WriteRegStr HKCR "${PACKAGE_NAME0}File\DefaultIcon" "" "$INSTDIR\icon.ico,0"
		WriteRegStr HKCR "${PACKAGE_NAME0}File\shell\open\command" "" 'notepad.exe "%1"'
		WriteRegStr HKCR "${PACKAGE_NAME0}File\shell\run" "" "Start ${PACKAGE_NAME0} on this config file"
		WriteRegStr HKCR "${PACKAGE_NAME0}File\shell\run\command" "" '"$INSTDIR\bin\openvpn.exe" --pause-exit --config "%1"'
	SectionEnd

	Section /o "Add Shortcuts to Start Menu" SecAddShortcuts

		SetOverwrite on
		CreateDirectory "$SMPROGRAMS\${PACKAGE_NAME2}\Documentation"
		WriteINIStr "$SMPROGRAMS\${PACKAGE_NAME2}\Documentation\${PACKAGE_NAME2} HOWTO.url" "InternetShortcut" "URL" "https://openvpn.net/howto.html"
		WriteINIStr "$SMPROGRAMS\${PACKAGE_NAME2}\Documentation\${PACKAGE_NAME2} Web Site.url" "InternetShortcut" "URL" "https://openvpn.net/"
		WriteINIStr "$SMPROGRAMS\${PACKAGE_NAME2}\Documentation\${PACKAGE_NAME2} Wiki.url" "InternetShortcut" "URL" "https://community.openvpn.net/openvpn/wiki/"
		WriteINIStr "$SMPROGRAMS\${PACKAGE_NAME2}\Documentation\${PACKAGE_NAME2} Support.url" "InternetShortcut" "URL" "https://community.openvpn.net/openvpn/wiki/GettingHelp"

		CreateShortCut "$SMPROGRAMS\${PACKAGE_NAME2}\Uninstall ${PACKAGE_NAME2}.lnk" "$INSTDIR\Uninstall.exe"
	SectionEnd

	Section /o "Launch ${PACKAGE_NAME2} GUI on User Logon" SecLaunchGUIOnLogon
	SectionEnd

	Section /o "Disable Password Save Feature in ${PACKAGE_NAME2} GUI" SecDisableSavePass
		WriteRegDWORD HKLM "SOFTWARE\${PACKAGE_NAME2}" "disable_save_passwords"  1
	SectionEnd

SectionGroupEnd


Section "-OpenSSL DLLs" SecOpenSSLDLLs

	SetOverwrite on
	SetOutPath "$INSTDIR\bin"
	${If} ${RunningX64}
		File /x liblzo2-2.dll /x libpkcs11-helper-1.dll "${OPENVPN_ROOT_X86_64}\bin\*.dll"
	${Else}
		File /x liblzo2-2.dll /x libpkcs11-helper-1.dll "${OPENVPN_ROOT_I686}\bin\*.dll"
	${EndIf}

SectionEnd

Section "-LZO DLLs" SecLZODLLs

	SetOverwrite on
	SetOutPath "$INSTDIR\bin"
	${If} ${RunningX64}
		File "${OPENVPN_ROOT_X86_64}\bin\liblzo2-2.dll"
	${Else}
		File "${OPENVPN_ROOT_I686}\bin\liblzo2-2.dll"
	${EndIf}

SectionEnd

Section "-PKCS#11 DLLs" SecPKCS11DLLs

	SetOverwrite on
	SetOutPath "$INSTDIR\bin"
	${If} ${RunningX64}
		File "${OPENVPN_ROOT_X86_64}\bin\libpkcs11-helper-1.dll"
	${Else}
		File "${OPENVPN_ROOT_I686}\bin\libpkcs11-helper-1.dll"
	${EndIf}

SectionEnd


;--------------------------------
;Installer Sections

Function .onInit
	${GetParameters} $R0
	ClearErrors

${IfNot} ${AtLeastWinVista}

	MessageBox MB_YESNO|MB_ICONEXCLAMATION "This package does not work on your operating system.  The last version of FCXTunnel supported on your OS is 2.3. Shall I open a web browser for you to download it?" /SD IDNO IDYES DownloadForWinXP
	Quit

	DownloadForWinXP:
	DetailPrint "Downloading the latest WinXP build ..."
	${If} ${RunningX64}
		ExecShell "open" "https://build.openvpn.net/downloads/releases/latest/openvpn-install-latest-winxp-x86_64.exe" 
	${Else}
		ExecShell "open" "https://build.openvpn.net/downloads/releases/latest/openvpn-install-latest-winxp-i686.exe"
	${EndIf}

	Quit

${EndIf}

	${If} ${RunningX64}
		SetRegView 64
		; Change the installation directory to C:\Program Files, but only if the
		; user has not provided a custom install location.
		${If} "$INSTDIR" == "$PROGRAMFILES\${PACKAGE_NAME2}"
			StrCpy $INSTDIR "$PROGRAMFILES64\${PACKAGE_NAME2}"
		${EndIf}
	${EndIf}

	!insertmacro SelectByParameter ${SecAddShortcutsWorkaround} SELECT_SHORTCUTS 1
	!insertmacro SelectByParameter ${SecOpenVPNUserSpace} SELECT_OPENVPN 1
	!insertmacro SelectByParameter ${SecService} SELECT_SERVICE 1
	!insertmacro SelectByParameter ${SecTAP} SELECT_TAP 1
	!insertmacro SelectByParameter ${SecOpenVPNGUI} SELECT_OPENVPNGUI 0
	!insertmacro SelectByParameter ${SecFileAssociation} SELECT_ASSOCIATIONS 1
	!insertmacro SelectByParameter ${SecOpenSSLUtilities} SELECT_OPENSSL_UTILITIES 1
	!insertmacro SelectByParameter ${SecOpenVPNEasyRSA} SELECT_EASYRSA 0
	!insertmacro SelectByParameter ${SecAddShortcuts} SELECT_SHORTCUTS 0
	!insertmacro SelectByParameter ${SecLaunchGUIOnLogon} SELECT_LAUNCH 0
	!insertmacro SelectByParameter ${SecLaunchGUIOnLogon0} SELECT_LAUNCH 0
	!insertmacro SelectByParameter ${SecDisableSavePass} SELECT_DISABLE_SAVEPASS 0
	!insertmacro SelectByParameter ${SecOpenSSLDLLs} SELECT_OPENSSLDLLS 1
	!insertmacro SelectByParameter ${SecLZODLLs} SELECT_LZODLLS 1
	!insertmacro SelectByParameter ${SecPKCS11DLLs} SELECT_PKCS11DLLS 1

	!insertmacro MULTIUSER_INIT
	SetShellVarContext all

FunctionEnd

;--------------------------------
;Dependencies

Function .onSelChange
	${If} ${SectionIsSelected} ${SecService}
		!insertmacro SelectSection ${SecOpenVPNUserSpace}
	${EndIf}
	${If} ${SectionIsSelected} ${SecOpenVPNGUI}
		!insertmacro SelectSection ${SecOpenVPNUserSpace}
	${EndIf}
	${If} ${SectionIsSelected} ${SecOpenVPNEasyRSA}
		!insertmacro SelectSection ${SecOpenSSLUtilities}
	${EndIf}
	${If} ${SectionIsSelected} ${SecAddShortcuts}
		!insertmacro SelectSection ${SecAddShortcutsWorkaround}
	${Else}
		!insertmacro UnselectSection ${SecAddShortcutsWorkaround}
	${EndIf}
	${If} ${SectionIsSelected} ${SecLaunchGUIOnLogon}
		!insertmacro SelectSection ${SecLaunchGUIOnLogon0}
	${Else}
		!insertmacro UnSelectSection ${SecLaunchGUIOnLogon0}
	${EndIf}
FunctionEnd

;--------------------
;Post-install section

Section -post

	SetOverwrite on
	SetOutPath "$INSTDIR"
	File "icon.ico"
	SetOutPath "$INSTDIR\doc"
	File "${OPENVPN_ROOT}\share\doc\openvpn\license.txt"

	; Store install folder in registry
	WriteRegStr HKLM "SOFTWARE\${PACKAGE_NAME0}" "" "$INSTDIR"

	; Create uninstaller
	WriteUninstaller "$INSTDIR\Uninstall.exe"

	; Show up in Add/Remove programs
	WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME0}" "DisplayName" "${PACKAGE_NAME} ${VERSION_STRING} ${SPECIAL_BUILD}"
	WriteRegExpandStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME0}" "UninstallString" "$INSTDIR\Uninstall.exe"
	WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME0}" "DisplayIcon" "$INSTDIR\icon.ico"
	WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME0}" "DisplayVersion" "${VERSION_STRING}"
	WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME0}" "HelpLink" "https://openvpn.net/index.php/open-source.html"
	WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME0}" "InstallLocation" "$INSTDIR\"
	WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME0}" "Language" 1033
	WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME0}" "NoModify" 1
	WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME0}" "NoRepair" 1
	WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME0}" "Publisher" "${PRODUCT_PUBLISHER}"
	WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME0}" "UninstallString" "$INSTDIR\Uninstall.exe"
	WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME0}" "URLInfoAbout" "https://openvpn.net"

	${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
	IntFmt $0 "0x%08X" $0
	WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME0}" "EstimatedSize" "$0"

	Call RestoreServiceState

	; if no .NET 4, offer to  install it unless silent install
	IfSilent 0 +2
	Goto skipNet40
	${If} ${SectionIsSelected} ${SecService}
		!insertmacro CheckNetFramework 40Full
	${Endif}

	skipNet40:

SectionEnd

;--------------------------------
;Descriptions

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
	!insertmacro MUI_DESCRIPTION_TEXT ${SecOpenVPNUserSpace} $(DESC_SecOpenVPNUserSpace)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecService} $(DESC_SecService)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecOpenVPNGUI} $(DESC_SecOpenVPNGUI)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecTAP} $(DESC_SecTAP)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecOpenVPNEasyRSA} $(DESC_SecOpenVPNEasyRSA)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecOpenSSLUtilities} $(DESC_SecOpenSSLUtilities)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecOpenSSLDLLs} $(DESC_SecOpenSSLDLLs)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecLZODLLs} $(DESC_SecLZODLLs)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecPKCS11DLLs} $(DESC_SecPKCS11DLLs)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecAddShortcuts} $(DESC_SecAddShortcuts)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecLaunchGUIOnLogon} $(DESC_SecLaunchGUIOnLogon)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecDisableSavePass} $(DESC_SecDisableSavePass)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecFileAssociation} $(DESC_SecFileAssociation)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------
;Uninstaller Section

Function un.onInit
	ClearErrors
	!insertmacro MULTIUSER_UNINIT
	SetShellVarContext all
	${If} ${RunningX64}
		SetRegView 64
	${EndIf}
FunctionEnd

Section "Uninstall"

	; Stop OpenVPN-GUI if currently running
	DetailPrint "Stopping FCXTunnel-GUI..."
	StopGUI:

	FindWindow $0 "OpenVPN-GUI"
	IntCmp $0 0 guiClosed
	SendMessage $0 ${WM_CLOSE} 0 0
	Sleep 100
	Goto StopGUI

	guiClosed:

	; Services have to be explicitly stopped before they are removed
	DetailPrint "Stopping FCXTunnel Services..."
	SimpleSC::StopService "FCXTunnelService" 0 10
	SimpleSC::StopService "FCXTunnelServiceInteractive" 0 10
	SimpleSC::StopService "FCXTunnelServiceLegacy" 0 10
	DetailPrint "Removing FCXTunnel Services..."
	SimpleSC::RemoveService "FCXTunnelService"
	SimpleSC::RemoveService "FCXTunnelServiceInteractive"
	SimpleSC::RemoveService "FCXTunnelServiceLegacy"
	Sleep 3000

	ReadRegStr $R0 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME0}" "tap"
	${If} $R0 == "installed"
		ReadRegStr $R0 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\TAP-Windows" "UninstallString"
		${If} $R0 != ""
			DetailPrint "Uninstalling TAP..."
			nsExec::ExecToLog /OEM '"$R0" /S'
			Pop $R0 # return value/error/timeout
		${EndIf}
	${EndIf}

	Delete "$INSTDIR\bin\openvpn-gui.exe"
	Delete "$DESKTOP\${PACKAGE_NAME2} GUI.lnk"

	Delete "$INSTDIR\bin\openvpn.exe"
	Delete "$INSTDIR\bin\openvpnserv.exe"
	Delete "$INSTDIR\bin\openvpnserv2.exe"
	Delete "$INSTDIR\bin\libeay32.dll"
	Delete "$INSTDIR\bin\ssleay32.dll"
	Delete "$INSTDIR\bin\liblzo2-2.dll"
	Delete "$INSTDIR\bin\libpkcs11-helper-1.dll"
	Delete "$INSTDIR\bin\libcrypto-1_1.dll"
	Delete "$INSTDIR\bin\libcrypto-1_1-x64.dll"
	Delete "$INSTDIR\bin\libssl-1_1.dll"
	Delete "$INSTDIR\bin\libssl-1_1-x64.dll"

	Delete "$INSTDIR\config\README.txt"
	Delete "$INSTDIR\config\sample.${OPENVPN_CONFIG_EXT}.txt"

	Delete "$INSTDIR\log\README.txt"

	Delete "$INSTDIR\bin\openssl.exe"

	Delete "$INSTDIR\doc\license.txt"
	Delete "$INSTDIR\doc\INSTALL-win32.txt"
	Delete "$INSTDIR\doc\openvpn.8.html"
	Delete "$INSTDIR\icon.ico"
	Delete "$INSTDIR\Uninstall.exe"

	Delete "$INSTDIR\easy-rsa\openssl-1.0.0.cnf"
	Delete "$INSTDIR\easy-rsa\vars.bat.sample"
	Delete "$INSTDIR\easy-rsa\init-config.bat"
	Delete "$INSTDIR\easy-rsa\README.txt"
	Delete "$INSTDIR\easy-rsa\build-ca.bat"
	Delete "$INSTDIR\easy-rsa\build-dh.bat"
	Delete "$INSTDIR\easy-rsa\build-key-server.bat"
	Delete "$INSTDIR\easy-rsa\build-key.bat"
	Delete "$INSTDIR\easy-rsa\build-key-pass.bat"
	Delete "$INSTDIR\easy-rsa\build-key-pkcs12.bat"
	Delete "$INSTDIR\easy-rsa\clean-all.bat"
	Delete "$INSTDIR\easy-rsa\index.txt.start"
	Delete "$INSTDIR\easy-rsa\revoke-full.bat"
	Delete "$INSTDIR\easy-rsa\serial.start"

	Delete "$INSTDIR\sample-config\*.${OPENVPN_CONFIG_EXT}"

	RMDir "$INSTDIR\bin"
	RMDir "$INSTDIR\doc"
	RMDir "$INSTDIR\config"
	RMDir "$INSTDIR\easy-rsa"
	RMDir "$INSTDIR\sample-config"
	RMDir /r "$INSTDIR\log"
	RMDir "$INSTDIR"
	RMDir /r "$SMPROGRAMS\${PACKAGE_NAME2}"

	!insertmacro DelRegKeyIfUnchanged HKCR ".${OPENVPN_CONFIG_EXT}" "${PACKAGE_NAME0}File"
	DeleteRegKey HKCR "${PACKAGE_NAME0}File"
	DeleteRegKey HKLM "SOFTWARE\${PACKAGE_NAME0}"
	DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${PACKAGE_NAME0}"
        ; Set installed status to 0 in Active Setup
	WriteRegDword HKLM "Software\Microsoft\Active Setup\Installed Components\${PACKAGE_NAME0}_UserSetup" "IsInstalled" 0x0
	WriteRegStr HKLM "Software\Microsoft\Active Setup\Installed Components\${PACKAGE_NAME0}_UserSetup" "StubPath" "reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v OPENVPN-GUI /f"
SectionEnd
