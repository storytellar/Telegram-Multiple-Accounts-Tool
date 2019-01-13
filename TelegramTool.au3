#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <AutoItConstants.au3>
#include <File.au3>
#include <GuiListBox.au3>



Global $default_path , $Telegram_path , $Data_path , $RemovedData_path
_Default()


$Form1 = GUICreate("Telegram Tools", 256, 316,@DesktopWidth-260, @DeskTopHeight-410)
GUISetIcon(@SystemDir & "\Shell32.dll", 26)
$Tab1 = GUICtrlCreateTab(0, 0, 256, 316)
	$TabSheet1 = GUICtrlCreateTabItem("Telegram Controller")
		Global $t1List1 = GUICtrlCreateList("", 16, 40, 137, 266,BitOR($WS_BORDER, $WS_VSCROLL, $LBS_NOTIFY, $LBS_SORT))
		$t1Button1 = GUICtrlCreateButton("LOGIN", 160, 40, 75, 81)
		$t1Button2 = GUICtrlCreateButton("RESET", 160, 197, 75, 57)
		$t1Button3 = GUICtrlCreateButton("Delete", 160, 280, 75, 25)
		$t1Button4 = GUICtrlCreateButton("Load", 160, 255, 75, 25)
		$t1Button5 = GUICtrlCreateButton("Save", 160, 122, 75, 34)
		$t1Button6 = GUICtrlCreateButton("Rename", 160, 158, 75, 25)
	$TabSheet2 = GUICtrlCreateTabItem("Config")
		$t2TeleLocation = GUICtrlCreateInput($default_path, 8, 72, 233, 28)
		$t2Label1 = GUICtrlCreateLabel("Telegram  File Location", 8, 40, 168, 24)
		$t2Export = GUICtrlCreateButton("EXPORT ACCOUNT DATA", 8, 256, 243, 41)
		$t2Import = GUICtrlCreateButton("IMPORT ACCOUNT DATA", 8, 210, 243, 41)
		$t2Button1 = GUICtrlCreateButton("LOAD", 64, 128, 123, 65)
_LoadData()
GUISetState(@SW_SHOW)


While 1
	Switch GUIGetMsg()
		Case $GUI_EVENT_CLOSE
			Exit
		Case $t1Button1
			_Login()
		Case $t1Button2
			_ResetTelegram()
		Case $t1Button4
			_LoadData()
		Case $t1Button5
			_SaveAccount()
		Case $t1Button3
			_DeleteAccount()
		Case $t1Button6
			_RenameAccount()
		Case $t2Button1
			_LoadData()
		Case $t2Export
			_ExportAccountToZIP()
		Case $t2Import
			_ImportAccountFromZIP()
	EndSwitch
WEnd



Func _RenameAccount()
	$accName = GUICtrlRead($t1List1)
	If ($accName == "") Then
		Return
	EndIf

	$newName = _InputAccountName()
	If ($newName == -1) Then Return
	DirMove($Data_path & $accName , $Data_path & $newName , 1)
	_LoadData()
EndFunc

Func _ImportAccountFromZIP()
	Local $sFileOpenDialog = FileOpenDialog("", @DesktopDir & "\", "Backup file (*.zip)")
    If @error Then
        FileChangeDir(@ScriptDir)
		Return
    Else
        FileChangeDir(@ScriptDir)
		$sFileOpenDialog = StringReplace($sFileOpenDialog, "|", @CRLF)
    EndIf

	; Backup Data before overwrite
	DirCreate($Telegram_path & "temp")
	DirMove($Data_path,$Telegram_path & "temp\DataForTool" ,1)
	DirMove($Data_path,$Telegram_path & "temp\RemovedData",1)

	; Import data
	DirRemove($Data_path,1)
	DirRemove($RemovedData_path,1)
	_Zip_UnzipAll($sFileOpenDialog, $Telegram_path,1)

	_LoadData()
EndFunc

Func _ExportAccountToZIP()
	$zipName = InputBox("Ask","What is zip's name?","","",300,150,@DesktopWidth/2,@DesktopWidth/2)
	While(FileExists(@DesktopDir & $zipName))
		MsgBox("","","Error: Existed name !!!")
		$zipName = InputBox("Ask","What is zip's name?","","",300,150,@DesktopWidth/2,@DesktopWidth/2)
	WEnd
	$zip = _Zip_Create(@DesktopDir & "\" & $zipName & ".zip")
	_Zip_AddFolder($Zip,$Data_path,4)
	If(FileExists(@DesktopDir & "\" & $zipName & ".zip")) Then
		MsgBox("","","Exported to " & @DesktopDir & "\" & $zipName & ".zip")
	EndIf
EndFunc

Func _DeleteAccount()
	$accName = GUICtrlRead($t1List1)
	If ($accName == "") Then
		Return
	Else
		$ans = MsgBox(4,"Ask","Do you want to remove?")
		If ($ans == 6) Then
			DirMove($Data_path & $accName, $RemovedData_path & $accName,1)
			_LoadData()
		EndIf
	EndIf
EndFunc

Func _Login()
	; Check list empty
	If (Guictrlread($t1List1) == "") Then Return

	Local $acc_path = $Data_path & Guictrlread($t1List1)
	_KillTele()
	_Logout()
	DirCopy($acc_path,$Telegram_path & "tdata",1)
	_LaunchTele()
EndFunc

Func _LoadData()
	GUICtrlSetData($t1List1,"")
	Local $aFileList = _FileListToArray($Data_path, "*")
    If @error = 1 Then
		ConsoleWrite("Loi~: Path was invalid.")
		Return
    EndIf
    If @error = 4 Then
		ConsoleWrite("Loi~: No file(s) were found.")
		Return
    EndIf

	For $i=1 to $aFileList[0] step +1
		If (Number(_IntFromString($aFileList[$i])) <> 0) Then
			$aFileList[$i] = Number(_IntFromString($aFileList[$i]))
		EndIf
	Next
	_ArraySort($aFileList,0,1)
	For $i=1 to $aFileList[0] step +1
		If (Number(_IntFromString($aFileList[$i])) <> 0) Then
			$aFileList[$i] = "clone" & $aFileList[$i]
		EndIf
	Next

	_GUICtrlListBox_BeginUpdate($t1List1)
	For $i=1 to $aFileList[0] step +1
		_GUICtrlListBox_InsertString($t1List1,$aFileList[$i],-1)
	Next
	_GUICtrlListBox_EndUpdate($t1List1)
EndFunc
Func _IntFromString($s_str)
    ; strip non digit from string
    Return Int(StringRegExpReplace($s_str, "[^\d\.]", ""))
EndFunc
Func _SaveAccount()
	$accName = _InputAccountName()
	If ($accName == -1) Then Return
	_KillTele()
	DirCopy($Telegram_path & "tdata", $Data_path & $accName,1)
	_LoadData()
	_LaunchTele()
EndFunc

Func _InputAccountName()
	$accName = InputBox("Ask","What is account's name?","","",300,150,@DesktopWidth/2,@DesktopWidth/2)
	While(FileExists($Telegram_path & $accName))
		If ($accName == "") Then Return -1
		MsgBox("","","Error: Existed name !!!")
		$accName = InputBox("Ask","What is account's name?","","",300,150,@DesktopWidth/2,@DesktopWidth/2)
		If @Error = 1 Then Return -1
	WEnd
	Return $accName
EndFunc

Func _Default()
	Global $default_path = "C:\Users\" & @UserName & "\AppData\Roaming\Telegram Desktop\"
	Global $Telegram_path = $default_path
	Global $Data_path = $Telegram_path & "DataForTool\"
	Global $RemovedData_path = $Telegram_path & "RemovedData\"
	If(FileExists($Telegram_path & "DataForTool")) Then return
	DirCreate($Data_path)
	DirCreate($RemovedData_path)
EndFunc

Func _ResetTelegram()
	_KillTele()
	_Logout()
	_LaunchTele()
EndFunc

Func _LaunchTele()
	Run($Telegram_path & "Telegram.exe")
EndFunc

Func _Logout()
	DirRemove($Telegram_path & "tdata",1)
EndFunc

Func _KillTele()
	Local $PID = ProcessExists("Telegram.exe")
	_ProcessKill($PID)
EndFunc

Func _ProcessKill($iPID)
	Local $iTimeOut = 5, $iTimer
	$iTimeOut *= 1000
	$iTimer = TimerInit()
	While ProcessExists($iPID)
	If TimerDiff($iTimer) > $iTimeOut Then
	ExitLoop
	EndIf
	RunWait("TASKKILL /F /PID " & $iPID, @SystemDir & "\", @SW_HIDE)
	Sleep(20)
	WEnd
	Return Number(ProcessExists($iPID) > 0)
EndFunc


















;======================================================================================

;#AutoIt3Wrapper_au3check_parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6
#include <array.au3>
; ------------------------------------------------------------------------------
;
; AutoIt Version: 3.2
; Language:       English
; Description:    ZIP Functions.
; Author:		  torels_
;
; ------------------------------------------------------------------------------

If UBound($CMDLine) > 1 Then
	If $CMDLine[1] <> "" Then _Zip_VirtualZipOpen()
EndIf

;===============================================================================
;
; Function Name:    _Zip_Create()
; Description:      Create Empty ZIP file.
; Parameter(s):     $hFilename - Complete path to zip file that will be created
; Requirement(s):   none.
; Return Value(s):  Returns the Zip file path (to be used as a handle - even though it's not necessary)
; Author(s):        torels_
;
;===============================================================================
Func _Zip_Create($hFilename)
	$hFp = FileOpen($hFilename, 26)
	$sString = Chr(80) & Chr(75) & Chr(5) & Chr(6) & Chr(0) & Chr(0) & Chr(0) & Chr(0) & Chr(0) & Chr(0) & Chr(0) & Chr(0) & Chr(0) & Chr(0) & Chr(0) & Chr(0) & Chr(0) & Chr(0) & Chr(0) & Chr(0) & Chr(0) & Chr(0)
	FileWrite($hFp, $sString)
	If @error Then Return SetError(1,0,0)
	FileClose($hFp)

	While Not FileExists($hFilename)
		Sleep(10)
	Wend
	Return $hFilename
EndFunc   ;==>_Zip_Create

;===============================================================================
;
; Function Name:    _Zip_AddFile()
; Description:      Add a file to a ZIP Archieve.
; Parameter(s):     $hZipFile - Complete path to zip file that will be created (or handle if existant)
;					$hFile2Add - Complete path to the file that will be added
;					$flag = 1
;					- 0 ProgressBox
;					- 1 no progress box
; Requirement(s):   none.
; Return Value(s):  On Success - 0
;                   On Failure - sets @error 1~3
;					@error = 1 no Zip file
;					@error = 2 no dll
;					@error = 3 dll isn't registered
;                   On Failure - Returns False
; Author(s):        torels_
; Notes:			The return values will be given once the compressing process is ultimated... it takes some time with big files
;
;===============================================================================
Func _Zip_AddFile($hZipFile, $hFile2Add, $flag = 1)
	Local $DLLChk = _Zip_DllChk()
	Local $files = _Zip_Count($hZipFile)
	If $DLLChk <> 0 Then Return SetError($DLLChk, 0, 0);no dll
	If not _IsFullPath($hZipFile) then Return SetError(4,0) ;zip file isn't a full path
	If Not FileExists($hZipFile) Then Return SetError(1, 0, 0) ;no zip file
	$oApp = ObjCreate("Shell.Application")
	$copy = $oApp.NameSpace($hZipFile).CopyHere($hFile2Add)
	While 1
		If $flag = 1 then _Hide()
		If _Zip_Count($hZipFile) = ($files+1) Then ExitLoop
		Sleep(10)
	WEnd
	Return SetError(0,0,1)
EndFunc   ;==>_Zip_AddFile

;===============================================================================
;
; Function Name:    _Zip_AddFolder()
; Description:      Add a folder to a ZIP Archieve.
; Parameter(s):     $hZipFile - Complete path to zip file that will be created (or handle if existant)
;					$hFolder - Complete path to the folder that will be added (possibly including "\" at the end)
;					$flag = 1
;					- 1 no progress box
;					- 0 progress box
; Requirement(s):   none.
; Return Value(s):  On Success - 0
;                   On Failure - sets @error 1~3
;					@error = 1 no Zip file
;					@error = 2 no dll
;					@error = 3 dll isn't registered
; Author(s):        torels_
; Notes:			The return values will be given once the compressing process is ultimated... it takes some time with big files
;
;===============================================================================
Func _Zip_AddFolder($hZipFile, $hFolder, $flag = 1)
	Local $DLLChk = _Zip_DllChk()
	If $DLLChk <> 0 Then Return SetError($DLLChk, 0, 0);no dll
	If not _IsFullPath($hZipFile) then Return SetError(4,0) ;zip file isn't a full path
	If Not FileExists($hZipFile) Then Return SetError(1, 0, 0) ;no zip file
	If StringRight($hFolder, 1) <> "\" Then $hFolder &= "\"
	$files = _Zip_Count($hZipFile)
	$oApp = ObjCreate("Shell.Application")
	$oCopy = $oApp.NameSpace($hZipFile).CopyHere($oApp.Namespace($hFolder))
	While 1
		If $flag = 1 then _Hide()
		If _Zip_Count($hZipFile) = ($files+1) Then ExitLoop
		Sleep(10)
	WEnd
	Return SetError(0,0,1)
EndFunc   ;==>_Zip_AddFolder

;===============================================================================
;
; Function Name:    _Zip_AddFolderContents()
; Description:      Add a folder to a ZIP Archieve.
; Parameter(s):     $hZipFile - Complete path to zip file that will be created (or handle if existant)
;					$hFolder - Complete path to the folder that will be added (possibly including "\" at the end)
;					$flag = 1
;					- 1 no progress box
;					- 0 progress box
; Requirement(s):   none.
; Return Value(s):  On Success - 0
;                   On Failure - sets @error 1~3
;					@error = 1 no Zip file
;					@error = 2 no dll
;					@error = 3 dll isn't registered
; Author(s):        torels_
; Notes:			The return values will be given once the compressing process is ultimated... it takes some time with big files
;
;===============================================================================
Func _Zip_AddFolderContents($hZipFile, $hFolder, $flag = 1)
	Local $DLLChk = _Zip_DllChk()
	If $DLLChk <> 0 Then Return SetError($DLLChk, 0, 0);no dll
	If not _IsFullPath($hZipFile) then Return SetError(4,0) ;zip file isn't a full path
	If Not FileExists($hZipFile) Then Return SetError(1, 0, 0) ;no zip file
	If StringRight($hFolder, 1) <> "\" Then $hFolder &= "\"
	$files = _Zip_Count($hZipFile)
	$oApp = ObjCreate("Shell.Application")
	$oFolder = $oApp.NameSpace($hFolder)
	$oCopy = $oApp.NameSpace($hZipFile).CopyHere($oFolder.Items)
	$oFC = $oApp.NameSpace($hFolder).items.count
	While 1
		If $flag = 1 then _Hide()
		If _Zip_Count($hZipFile) = ($files+$oFC) Then ExitLoop
		Sleep(10)
	WEnd
	Return SetError(0,0,1)
EndFunc   ;==>_Zip_AddFolderContents

;===============================================================================
;
; Function Name:    _Zip_Delete()
; Description:      Delete a file from a ZIP Archive.
; Parameter(s):     $hZipFile - Complete path to zip file that will be created (or handle if existant)
;					$hFolder - Complete path to the folder that will be added (possibly including "\" at the end)
;					$flag = 1
;					- 1 no progress box
;					- 0 progress box
; Requirement(s):   none.
; Return Value(s):  On Success - 0
;                   On Failure - sets @error 1~3
;					@error = 1 no Zip file
;					@error = 2 no dll
;					@error = 3 dll isn't registered
; Author(s):        torels_
; Notes:			none
;
;===============================================================================
Func _Zip_Delete($hZipFile, $hFilename, $flag = 1)
	Local $DLLChk = _Zip_DllChk()
	If $DLLChk <> 0 Then Return SetError($DLLChk, 0, 0);no dll
	If not _IsFullPath($hZipFile) then Return SetError(4,0) ;zip file isn't a full path
	If Not FileExists($hZipFile) Then Return SetError(1, 0, 0) ;no zip file
	$list = _Zip_List($hZipFile)
	$dir = @TempDir & "\tmp" & Floor(Random(0,100))
	For $i = 1 to $list[0]
		If $list[$i] <> $hFilename Then _Zip_Unzip($hZipFile,$list[$i],$dir, $flag)
	Next
	FileDelete($hZipFile)
	_Zip_Create($hZipFile)
	_Zip_AddFolderContents($hZipFile, $dir, $flag)
	DirRemove($dir)
EndFunc

;===============================================================================
;
; Function Name:    _Zip_UnzipAll()
; Description:      Extract all files contained in a ZIP Archieve.
; Parameter(s):     $hZipFile - Complete path to zip file that will be created (or handle if existant)
;					$hDestPath - Complete path to where the files will be extracted
;					$flag = 1
;					- 1 no progress box
;					- 0 progress box
; Requirement(s):   none.
; Return Value(s):  On Success - 0
;                   On Failure - sets @error 1~3
;					@error = 1 no Zip file
;					@error = 2 no dll
;					@error = 3 dll isn't registered
; Author(s):        torels_
; Notes:			The return values will be given once the extracting process is ultimated... it takes some time with big files
;
;===============================================================================
Func _Zip_UnzipAll($hZipFile, $hDestPath, $flag = 1)
	Local $DLLChk = _Zip_DllChk()
	If $DLLChk <> 0 Then Return SetError($DLLChk, 0, 0);no dll
	If not _IsFullPath($hZipFile) then Return SetError(4,0) ;zip file isn't a full path
	If Not FileExists($hZipFile) Then Return SetError(2, 0, 0) ;no zip file
	If Not FileExists($hDestPath) Then DirCreate($hDestPath)
	Local $aArray[1]
	$oApp = ObjCreate("Shell.Application")
	$oApp.Namespace($hDestPath).CopyHere($oApp.Namespace($hZipFile).Items)
	For $item In $oApp.Namespace($hZipFile).Items
		_ArrayAdd($aArray, $item)
	Next
	While 1
		If $flag = 1 then _Hide()
		If FileExists($hDestPath & "\" & $aArray[UBound($aArray) - 1]) Then
			Return SetError(0, 0, 1)
			ExitLoop
		EndIf
		Sleep(500)
	WEnd
EndFunc   ;==>_Zip_UnzipAll

;===============================================================================
;
; Function Name:    _Zip_Unzip()
; Description:      Extract a single file contained in a ZIP Archieve.
; Parameter(s):     $hZipFile - Complete path to zip file that will be created (or handle if existant)
;					$hFilename - Name of the element in the zip archive ex. "hello_world.txt"
;					$hDestPath - Complete path to where the files will be extracted
;					$flag = 1
;					- 1 no progress box
;					- 0 progress box
; Requirement(s):   none.
; Return Value(s):  On Success - 0
;                   On Failure - sets @error 1~3
;					@error = 1 no Zip file
;					@error = 2 no dll
;					@error = 3 dll isn't registered
; Author(s):        torels_
; Notes:			The return values will be given once the extracting process is ultimated... it takes some time with big files
;
;===============================================================================
Func _Zip_Unzip($hZipFile, $hFilename, $hDestPath, $flag = 1)
	Local $DLLChk = _Zip_DllChk()
	If $DLLChk <> 0 Then Return SetError($DLLChk, 0, 0) ;no dll
	If not _IsFullPath($hZipFile) then Return SetError(4,0) ;zip file isn't a full path
	If Not FileExists($hZipFile) Then Return SetError(1, 0, 0) ;no zip file
	If Not FileExists($hDestPath) Then DirCreate($hDestPath)
	$oApp = ObjCreate("Shell.Application")
	$hFolderitem = $oApp.NameSpace($hZipFile).Parsename($hFilename)
	$oApp.NameSpace($hDestPath).Copyhere($hFolderitem)
	While 1
		If $flag = 1 then _Hide()
		If FileExists($hDestPath & "\" & $hFilename) Then
			return SetError(0, 0, 1)
			ExitLoop
		EndIf
		Sleep(500)
	WEnd
EndFunc   ;==>_Zip_Unzip

;===============================================================================
;
; Function Name:    _Zip_Count()
; Description:      Count files contained in a ZIP Archieve.
; Parameter(s):     $hZipFile - Complete path to zip file that will be created (or handle if existant)
; Requirement(s):   none.
; Return Value(s):  On Success - 0
;                   On Failure - sets @error 1~3
;					@error = 1 no Zip file
;					@error = 2 no dll
;					@error = 3 dll isn't registered
; Author(s):        torels_
;
;===============================================================================
Func _Zip_Count($hZipFile)
	Local $DLLChk = _Zip_DllChk()
	If $DLLChk <> 0 Then Return SetError($DLLChk, 0, 0) ;no dll
	If not _IsFullPath($hZipFile) then Return SetError(4,0) ;zip file isn't a full path
	If Not FileExists($hZipFile) Then Return SetError(1, 0, 0) ;no zip file
	$items = _Zip_List($hZipFile)
	Return UBound($items) - 1
EndFunc   ;==>_Zip_Count

;===============================================================================
;
; Function Name:    _Zip_CountAll()
; Description:      Count All files contained in a ZIP Archive (including Sub Directories)
; Parameter(s):     $hZipFile - Complete path to zip file that will be created (or handle if existant)
; Requirement(s):   none.
; Return Value(s):  On Success - 0
;                   On Failure - sets @error 1~3
;					@error = 1 no Zip file
;					@error = 2 no dll
;					@error = 3 dll isn't registered
; Author(s):        torels_, Smashly
;
;===============================================================================
Func _Zip_CountAll($hZipFile)
	Local $DLLChk = _Zip_DllChk()
	If $DLLChk <> 0 Then Return SetError($DLLChk, 0, 0) ;no dll
	If not _IsFullPath($hZipFile) then Return SetError(4,0) ;zip file isn't a full path
	If Not FileExists($hZipFile) Then Return SetError(1, 0, 0) ;no zip file
    $oApp = ObjCreate("Shell.Application")
    $oDir = $oApp.NameSpace(StringLeft($hZipFile, StringInStr($hZipFile, "\", 0, -1)))
    $sZipInf = $oDir.GetDetailsOf($oDir.ParseName(StringTrimLeft($hZipFile, StringInStr($hZipFile, "\", 0, -1))), -1)
    Return StringRight($sZipInf, StringLen($sZipInf) - StringInStr($sZipInf, ": ") - 1)
EndFunc

;===============================================================================
;
; Function Name:    _Zip_List()
; Description:      Returns an Array containing of all the files contained in a ZIP Archieve.
; Parameter(s):     $hZipFile - Complete path to zip file that will be created (or handle if existant)
; Requirement(s):   none.
; Return Value(s):  On Success - 0
;                   On Failure - sets @error 1~3
;					@error = 1 no Zip file
;					@error = 2 no dll
;					@error = 3 dll isn't registered
; Author(s):        torels_
;
;===============================================================================
Func _Zip_List($hZipFile)
	local $aArray[1]
	Local $DLLChk = _Zip_DllChk()
	If $DLLChk <> 0 Then Return SetError($DLLChk, 0, 0) ;no dll
	If not _IsFullPath($hZipFile) then Return SetError(4,0) ;zip file isn't a full path
	If Not FileExists($hZipFile) Then Return SetError(1, 0, 0) ;no zip file
	$oApp = ObjCreate("Shell.Application")
	$hList = $oApp.Namespace($hZipFile).Items
	For $item in $hList
		_ArrayAdd($aArray,$item.name)
	Next
	$aArray[0] = UBound($aArray) - 1
	Return $aArray
EndFunc   ;==>_Zip_List

;===============================================================================
;
; Function Name:    _Zip_Search()
; Description:      Search files in a ZIP Archive.
; Parameter(s):     $hZipFile - Complete path to zip file that will be created (or handle if existant)
;					$sSearchString - name of the file to be searched
; Requirement(s):   none.
; Return Value(s):  On Success - 0
;                   On Failure - sets @error 1 (no file found)
; Author(s):        torels_
; Notes:			none
;
;===============================================================================
Func _Zip_Search($hZipFile, $sSearchString)
	local $aArray
	Local $DLLChk = _Zip_DllChk()
	If $DLLChk <> 0 Then Return SetError($DLLChk, 0, 0) ;no dll
	If not _IsFullPath($hZipFile) then Return SetError(4,0) ;zip file isn't a full path
	If Not FileExists($hZipFile) Then Return SetError(1, 0, 0) ;no zip file
	$list = _Zip_List($hZipFile)
	for $i = 0 to UBound($list) - 1
		if StringInStr($list[$i],$sSearchstring) > 0 Then
			_ArrayAdd($aArray, $list[$i])
		EndIf
	Next
	if UBound($aArray) - 1 = 0 Then
		Return SetError(1,0,0)
	Else
		Return $aArray
	EndIf
EndFunc ;==> _Zip_Search

;===============================================================================
;
; Function Name:    _Zip_SearchInFile()
; Description:      Search files in a ZIP Archive's File.
; Parameter(s):     $hZipFile - Complete path to zip file that will be created (or handle if existant)
;					$sSearchString - name of the file to be searched
; Requirement(s):   none.
; Return Value(s):  On Success - 0
;                   On Failure - sets @error 1 (no file found)
; Author(s):        torels_
; Notes:			none
;
;===============================================================================
Func _Zip_SearchInFile($hZipFile, $sSearchString)
	local $aArray
	$list = _Zip_List($hZipFile)
	for $i = 1 to UBound($list) - 1
		_Zip_Unzip($hZipFile, $list[$i], @TempDir & "\tmp_zip.file")
		$read = FileRead(@TempDir & "\tmp_zip.file")
		if StringInStr($read,$sSearchstring) > 0 Then
			_ArrayAdd($aArray, $list[$i])
		EndIf
	Next
	if UBound($aArray) - 1 = 0 Then
		Return SetError(1,0,1)
	Else
		Return $aArray
	EndIf
EndFunc ;==> _Zip_Search

;===============================================================================
;
; Function Name:    _Zip_VirtualZipCreate()
; Description:      Create a Virtual Zip.
; Parameter(s):     $hZipFile - Complete path to zip file that will be created (or handle if existant)
;					$sPath - Path to where create the Virtual Zip
; Requirement(s):   none.
; Return Value(s):  On Success - List of Created Files
;                   On Failure - sets @error 1~3
;					@error = 1 no Zip file
;					@error = 2 no dll
;					@error = 3 dll isn't registered
; Author(s):        torels_
; Notes:			none
;
;===============================================================================
Func _Zip_VirtualZipCreate($hZipFile, $sPath)
	$List = _Zip_List($hZipFile)
	If @error Then Return SetError(@error,0,0)
	If Not FileExists($sPath) Then DirCreate($sPath)
	If StringRight($sPath, 1) = "\" Then $sPath = StringLeft($sPath, StringLen($sPath) -1)
	For $i = 1 to $List[0]
		If Not @Compiled Then
			$Cmd = @AutoItExe
			$params = '"' & @ScriptFullPath & '" ' & '"' & $hZipFile & "," & $List[$i] & '"'
		Else
			$Cmd = @ScriptFullPath
			$Params = '"' & $hZipFile & "," & $List[$i] & '"'
		EndIf
		FileCreateShortcut($Cmd, $sPath & "\" & $List[$i], -1,$Params, "Virtual Zipped File", _GetIcon($List[$i], 0), "", _GetIcon($List[$i], 1))
	Next
	$List = _ArrayInsert($List, 1, $sPath)
	Return $List
EndFunc

;===============================================================================
;
; Function Name:    _Zip_VirtualZipOpen()
; Description:      Open A File in a Virtual Zip, Internal Function.
; Parameter(s):     none.
; Requirement(s):   none.
; Return Value(s):  On Success - 0
;                   On Failure - sets @error 1~3
;					@error = 1 no Zip file
;					@error = 2 no dll
;					@error = 3 dll isn't registered
; Author(s):        torels_
; Notes:			none
;
;===============================================================================
Func _Zip_VirtualZipOpen()
	$ZipSplit = StringSplit($CMDLine[1], ",")
	$ZipName = $ZipSplit[1]
	$ZipFile = $ZipSplit[2]
	_Zip_Unzip($ZipName, $ZipFile, @TempDir & "\", 4+16) ;no progress + yes to all
	If @error Then Return SetError(@error,0,0)
	ShellExecute(@TempDir & "\" & $ZipFile)
EndFunc

;===============================================================================
;
; Function Name:    _Zip_VirtualZipOpen()
; Description:      Delete a Virtual Zip.
; Parameter(s):     none.
; Requirement(s):   none.
; Return Value(s):  On Success - 0
;                   On Failure - none.
; Author(s):        torels_
; Notes:			none
;
;===============================================================================
Func _Zip_VirtualZipDelete($aVirtualZipHandle)
	For $i = 2 to UBound($aVirtualZipHandle)-1
		If FileExists($aVirtualZipHandle[1] & "\" & $aVirtualZipHandle[$i]) Then FileDelete($aVirtualZipHandle[1] & "\" & $aVirtualZipHandle[$i])
	Next
	Return 0
EndFunc

;===============================================================================
;
; Function Name:    _Zip_DllChk()
; Description:      Internal error handler.
; Parameter(s):     none.
; Requirement(s):   none.
; Return Value(s):  Failure - @extended = 1
; Author(s):        smashley
;
;===============================================================================
Func _Zip_DllChk()
	If Not FileExists(@SystemDir & "\zipfldr.dll") Then Return 2
	If Not RegRead("HKEY_CLASSES_ROOT\CLSID\{E88DCCE0-B7B3-11d1-A9F0-00AA0060FA31}", "") Then Return 3
	Return 0
EndFunc   ;==>_Zip_DllChk

;===============================================================================
;
; Function Name:    _GetIcon()
; Description:      Internal Function.
; Parameter(s):     $file - File form which to retrieve the icon
;					$ReturnType - IconFile or IconID
; Requirement(s):   none.
; Return Value(s):  Icon Path/ID
; Author(s):        torels_
;
;===============================================================================
Func _GetIcon($file, $ReturnType = 0)
	$FileType = StringSplit($file, ".")
	$FileType = $FileType[UBound($FileType)-1]
	$FileParam = RegRead("HKEY_CLASSES_ROOT\." & $FileType, "")
	$DefaultIcon = RegRead("HKEY_CLASSES_ROOT\" & $FileParam & "\DefaultIcon", "")

	If Not @error Then
		$IconSplit = StringSplit($DefaultIcon, ",")
		ReDim $IconSplit[3]
		$Iconfile = $IconSplit[1]
		$IconID = $IconSplit[2]
	Else
		$Iconfile = @SystemDir & "\shell32.dll"
		$IconID = -219
	EndIf

	If $ReturnType = 0 Then
		Return $Iconfile
	Else
		Return $IconID
	EndIf
EndFunc

;===============================================================================
;
; Function Name:    _IsFullPath()
; Description:      Internal Function.
; Parameter(s):     $path - a zip path
; Requirement(s):   none.
; Return Value(s):  success - True.
;					failure - False.
; Author(s):        torels_
;
;===============================================================================
Func _IsFullPath($path)
    if StringInStr($path,":\") then
        Return True
    Else
        Return False
    EndIf
Endfunc

;===============================================================================
;
; Function Name:    _Hide()
; Description:      Internal Function.
; Parameter(s):     none
; Requirement(s):   none.
; Return Value(s):  none.
; Author(s):        torels_
;
;===============================================================================
Func _Hide()
	If ControlGetHandle("[CLASS:#32770]", "", "[CLASS:SysAnimate32; INSTANCE:1]") <> "" And WinGetState("[CLASS:#32770]") <> @SW_HIDE	Then ;The Window Exists
		$hWnd = WinGetHandle("[CLASS:#32770]")
		WinSetState($hWnd, "", @SW_HIDE)
	EndIf
EndFunc