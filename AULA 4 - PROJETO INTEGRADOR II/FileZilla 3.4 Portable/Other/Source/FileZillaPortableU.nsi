;Copyright (C) 2004-2010 John T. Haller

;Website: http://PortableApps.com/FileZillaPortable

;This software is OSI Certified Open Source Software.
;OSI Certified is a certification mark of the Open Source Initiative.

;This program is free software; you can redistribute it and/or
;modify it under the terms of the GNU General Public License
;as published by the Free Software Foundation; either version 2
;of the License, or (at your option) any later version.

;This program is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;GNU General Public License for more details.

;You should have received a copy of the GNU General Public License
;along with this program; if not, write to the Free Software
;Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

!define PORTABLEAPPNAME "FileZilla Portable"
!define APPNAME "FileZilla"
!define NAME "FileZillaPortable"
!define VER "1.6.11.0"
!define WEBSITE "PortableApps.com/FileZillaPortable"
!define DEFAULTEXE "FileZilla.exe"
!define DEFAULTAPPDIR "filezilla"
!define DEFAULTSETTINGSDIR "settings"
!define LAUNCHERLANGUAGE "English"

;=== Program Details
Name "${PORTABLEAPPNAME}"
OutFile "..\..\${NAME}.exe"
Caption "${PORTABLEAPPNAME} | PortableApps.com"
VIProductVersion "${VER}"
VIAddVersionKey ProductName "${PORTABLEAPPNAME}"
VIAddVersionKey Comments "Allows ${APPNAME} to be run from a removable drive.  For additional details, visit ${WEBSITE}"
VIAddVersionKey CompanyName "PortableApps.com"
VIAddVersionKey LegalCopyright "John T. Haller"
VIAddVersionKey FileDescription "${PORTABLEAPPNAME}"
VIAddVersionKey FileVersion "${VER}"
VIAddVersionKey ProductVersion "${VER}"
VIAddVersionKey InternalName "${PORTABLEAPPNAME}"
VIAddVersionKey LegalTrademarks "PortableApps.com is a Trademark of Rare Ideas, LLC."
VIAddVersionKey OriginalFilename "${NAME}.exe"
;VIAddVersionKey PrivateBuild ""
;VIAddVersionKey SpecialBuild ""


;=== Runtime Switches
CRCCheck On
WindowIcon Off
SilentInstall Silent
AutoCloseWindow True
RequestExecutionLevel user
XPStyle on

; Best Compression
SetCompress Auto
SetCompressor /SOLID lzma
SetCompressorDictSize 32
SetDatablockOptimize On

;=== Include
;(Standard NSIS)
!include TextFunc.nsh
!insertmacro ConfigRead
!insertmacro ConfigWrite
!include FileFunc.nsh
!insertmacro GetParameters ;NSIS 2.4.0 and up ONLY
!insertmacro GetRoot
!include Registry.nsh

;(NSIS Plugins)
!include TextReplace.nsh

;(Custom)
!include CheckForPlatformSplashDisable.nsh
!include ReadINIStrWithDefault.nsh
!include ReplaceInFileWithTextReplace.nsh


;=== Program Icon
Icon "..\..\App\AppInfo\appicon.ico"

;=== Icon & Stye ===
;!define MUI_ICON "..\..\App\AppInfo\appicon.ico"

;=== Languages
;!insertmacro MUI_LANGUAGE "${LAUNCHERLANGUAGE}"
LoadLanguageFile "${NSISDIR}\Contrib\Language files\${LAUNCHERLANGUAGE}.nlf"
!include PortableApps.comLauncherLANG_${LAUNCHERLANGUAGE}.nsh

Var PROGRAMDIRECTORY
Var SETTINGSDIRECTORY
Var ADDITIONALPARAMETERS
Var EXECSTRING
Var PROGRAMEXECUTABLE
Var INIPATH
Var DISABLESPLASHSCREEN
Var SECONDARYLAUNCH
Var MISSINGFILEORPATH
Var LASTDRIVE
Var CURRENTDRIVE
Var APPLANGUAGE
Var FAILEDTORESTOREKEY

Section "Main"
	;=== Check if already running
	System::Call 'kernel32::CreateMutex(i 0, i 0, t "${NAME}") i .r1 ?e'
	Pop $0
	StrCmp $0 0 CheckINI
		StrCpy $SECONDARYLAUNCH "true"

	CheckINI:
		;=== Find the INI file, if there is one
		IfFileExists "$EXEDIR\${NAME}.ini" "" NoINI
			StrCpy $INIPATH "$EXEDIR"

		;=== Read the parameters from the INI file
		${ReadINIStrWithDefault} $0 "$INIPATH\${NAME}.ini" "${NAME}" "${APPNAME}Directory" "App\${DEFAULTAPPDIR}"
		StrCpy $PROGRAMDIRECTORY "$EXEDIR\$0"
		${ReadINIStrWithDefault} $0 "$INIPATH\${NAME}.ini" "${NAME}" "SettingsDirectory" "Data\${DEFAULTSETTINGSDIR}"
		StrCpy $SETTINGSDIRECTORY "$EXEDIR\$0"
		${ReadINIStrWithDefault} $ADDITIONALPARAMETERS "$INIPATH\${NAME}.ini" "${NAME}" "AdditionalParameters" ""
		${ReadINIStrWithDefault} $PROGRAMEXECUTABLE "$INIPATH\${NAME}.ini" "${NAME}" "${APPNAME}Executable" "${DEFAULTEXE}"
		${ReadINIStrWithDefault} $DISABLESPLASHSCREEN "$INIPATH\${NAME}.ini" "${NAME}" "DisableSplashScreen" "false"

		IfFileExists "$PROGRAMDIRECTORY\$PROGRAMEXECUTABLE" FoundProgramEXE NoProgramEXE

	NoINI:
		;=== No INI file, so we'll use the defaults
		StrCpy $ADDITIONALPARAMETERS ""
		StrCpy $PROGRAMEXECUTABLE "${DEFAULTEXE}"
		StrCpy $DISABLESPLASHSCREEN "false"

		IfFileExists "$EXEDIR\App\${DEFAULTAPPDIR}\${DEFAULTEXE}" "" NoProgramEXE
			StrCpy $PROGRAMDIRECTORY "$EXEDIR\App\${DEFAULTAPPDIR}"
			StrCpy $SETTINGSDIRECTORY "$EXEDIR\Data\${DEFAULTSETTINGSDIR}"
			GoTo FoundProgramEXE

	NoProgramEXE:
		;=== Program executable not where expected
		StrCpy $MISSINGFILEORPATH $PROGRAMEXECUTABLE
		MessageBox MB_OK|MB_ICONEXCLAMATION `$(LauncherFileNotFound)`
		Abort
		
	FoundProgramEXE:
		StrCmp $SECONDARYLAUNCH "true" GetPassedParameters
		${CheckForPlatformSplashDisable} $DISABLESPLASHSCREEN
		StrCmp $DISABLESPLASHSCREEN "true" SkipSplashScreen
			;=== Show the splash screen before processing the files
			InitPluginsDir
			File /oname=$PLUGINSDIR\splash.jpg "${NAME}.jpg"
			newadvsplash::show /NOUNLOAD 1200 0 0 -1 /L "$PLUGINSDIR\splash.jpg"

	SkipSplashScreen:
		;=== Check for data files
		IfFileExists "$SETTINGSDIRECTORY\*.*" CheckSettingsVersion
		
		;=== Create settings directory
		CreateDirectory $SETTINGSDIRECTORY

	CheckSettingsVersion:
		IfFileExists "$SETTINGSDIRECTORY\sitemanager.xml" AdjustPaths
		IfFileExists "$SETTINGSDIRECTORY\filters.xml" AdjustPaths
		IfFileExists "$SETTINGSDIRECTORY\layout.xml" AdjustPaths
		IfFileExists "$SETTINGSDIRECTORY\queue.xml" AdjustPaths
		IfFileExists "$SETTINGSDIRECTORY\FileZilla.xml" "" AdjustPaths
		
		;=== No FileZilla 3 files exist, FileZilla 2 upgrade
		CreateDirectory "$SETTINGSDIRECTORY\old"
		Rename "$SETTINGSDIRECTORY\FileZilla.xml" "$SETTINGSDIRECTORY\old\FileZilla2.xml"
		MessageBox MB_OK|MB_ICONINFORMATION `Your configuration file is for an older version of FileZilla and can not be used.  Your old settings have been saved to:$\n$\n$SETTINGSDIRECTORY\old\FileZilla2.xml$\n$\nTo import your old settings into this new version of FileZilla, select EDIT and then IMPORT from the main menu and open the old settings file.$\nOnce imported successfully, you can delete your old settings file and the 'old' directory.$\nDetails on importing your old configuration file are also available in FileZilla Portable's help file and on PortableApps.com.`	

	AdjustPaths:
		ReadINIStr $LASTDRIVE "$SETTINGSDIRECTORY\${NAME}Settings.ini" "${NAME}Settings" "LastDrive"
		${GetRoot} $EXEDIR $CURRENTDRIVE
		StrCmp $LASTDRIVE $CURRENTDRIVE GetAppLanguage
		IfFileExists "$SETTINGSDIRECTORY\filezilla.xml" "" AdjustPaths2
			${ReplaceInFile} `$SETTINGSDIRECTORY\filezilla.xml` `>$LASTDRIVE\` `>$CURRENTDRIVE\`

	AdjustPaths2:
		IfFileExists "$SETTINGSDIRECTORY\sitemanager.xml" "" GetAppLanguage
			${ReplaceInFile} `$SETTINGSDIRECTORY\sitemanager.xml` `<LocalDir>$LASTDRIVE\` `<LocalDir>$CURRENTDRIVE\`
			
	GetAppLanguage:
		ReadEnvStr $APPLANGUAGE "PortableApps.comLocaleglibc"
		StrCmp $APPLANGUAGE "" RememberPath ;if not set, move on
		StrCmp $APPLANGUAGE "en_US" "" GetCurrentLanguage
			StrCpy $APPLANGUAGE "en"
		
	GetCurrentLanguage:
		${ConfigRead} `$SETTINGSDIRECTORY\FileZilla.xml` `        <Setting name="Language Code" type="string">` $0
		StrCmp `$APPLANGUAGE</Setting>` $0 RememberPath ;if the same, move on
		StrCmp $APPLANGUAGE "en" SetAppLanguage ;english is built in, so skip locale file check
		IfFileExists "$PROGRAMDIRECTORY\locales\$APPLANGUAGE\*.*" SetAppLanguage RememberPath

	SetAppLanguage:
		${ConfigWrite} `$SETTINGSDIRECTORY\FileZilla.xml` `        <Setting name="Language Code" type="string">` `$APPLANGUAGE</Setting>` $R0
	
	RememberPath:
		WriteINIStr "$SETTINGSDIRECTORY\${NAME}Settings.ini" "${NAME}Settings" "LastDrive" "$CURRENTDRIVE"
		
	;RegistryBackup:
		;=== Backup the registry
		${registry::KeyExists} "HKEY_CURRENT_USER\Software\FileZillaPo-BackupByFileZillaPortable" $R0
		StrCmp $R0 "0" RestoreTheKey
		${registry::KeyExists} "HKEY_CURRENT_USER\Software\FileZillaPo" $R0
		StrCmp $R0 "-1" RestoreTheKey
		${registry::MoveKey} "HKEY_CURRENT_USER\Software\FileZillaPo" "HKEY_CURRENT_USER\Software\FileZillaPo-BackupByFileZillaPortable" $R0
		Sleep 100

	RestoreTheKey:
		IfFileExists "$SETTINGSDIRECTORY\filezilla-putty.reg" "" GetPassedParameters
		IfFileExists "$WINDIR\system32\reg.exe" "" RestoreTheKey9x
			ExecDos::exec `"$WINDIR\system32\reg.exe" import "$SETTINGSDIRECTORY\filezilla-putty.reg"`
			Pop $R0
			StrCmp $R0 '0' GetPassedParameters ;successfully restored key

	RestoreTheKey9x:
		${registry::RestoreKey} "$SETTINGSDIRECTORY\filezilla-putty.reg.reg" $R0
		Sleep 2000
		StrCmp $R0 '0' GetPassedParameters ;successfully restored key
		StrCpy $FAILEDTORESTOREKEY "true"
		MessageBox MB_OK|MB_ICONINFORMATION `${PORTABLEAPPNAME}'s settings could not be loaded into the registry.  The account you are logged in with most likely does not have the ability to alter the registry.  ${PORTABLEAPPNAME} should still run correctly, but the default settings will be used.`
	
	GetPassedParameters:
		;=== Get any passed parameters
		${GetParameters} $0
		StrCmp "'$0'" "''" "" LaunchProgramParameters

		;=== No parameters
		StrCpy $EXECSTRING `"$PROGRAMDIRECTORY\$PROGRAMEXECUTABLE"`
		Goto AdditionalParameters


	LaunchProgramParameters:
		StrCpy $EXECSTRING `"$PROGRAMDIRECTORY\$PROGRAMEXECUTABLE" $0`

	AdditionalParameters:
		StrCmp $ADDITIONALPARAMETERS "" LaunchNow

		;=== Additional Parameters
		StrCpy $EXECSTRING `$EXECSTRING $ADDITIONALPARAMETERS`

	LaunchNow:
		System::Call 'Kernel32::SetEnvironmentVariable(t, t) i("FILEZILLA_PORTABLE_SETTINGS", "$SETTINGSDIRECTORY").r0'
		StrCmp $SECONDARYLAUNCH "true" LaunchAndExit
		ExecWait $EXECSTRING

	CheckRunning:
		Sleep 1000
		FindProcDLL::FindProc "$PROGRAMEXECUTABLE"
		StrCmp $R0 "1" CheckRunning
		
		StrCmp $FAILEDTORESTOREKEY "true" SetOriginalKeyBack
		CreateDirectory $SETTINGSDIRECTORY
		${registry::SaveKey} "HKEY_CURRENT_USER\Software\FileZillaPo" "$SETTINGSDIRECTORY\filezilla-putty.reg" "" $0
		Sleep 100
	
	SetOriginalKeyBack:
		${registry::DeleteKey} "HKEY_CURRENT_USER\Software\FileZillaPo" $R0
		Sleep 100
		${registry::KeyExists} "HKEY_CURRENT_USER\Software\FileZillaPo-BackupByFileZillaPortable" $R0
		StrCmp $R0 "-1" TheEnd
		${registry::MoveKey} "HKEY_CURRENT_USER\Software\FileZillaPo-BackupByFileZillaPortable" "HKEY_CURRENT_USER\Software\FileZillaPo" $R0
		Sleep 100
		Goto TheEnd
	
	LaunchAndExit:
		Exec $EXECSTRING

	TheEnd:
		${registry::Unload}
		newadvsplash::stop /WAIT
SectionEnd