/*
    Compile the script to use the Unicode version of NSIS
    The producers：surou
*/
!define FILE_VERSION "4.0.2.0"
; 引入的头文件
!include "MUI.nsh"
!include "FileFunc.nsh"
!include "StdUtils.nsh"
!include "nsPublic.nsh"

Var varLocalVersion
Var varOldLocalVersion
;Request application privileges for Windows Vista
RequestExecutionLevel admin
;文件版本声明-开始
VIProductVersion ${FILE_VERSION}
VIAddVersionKey /LANG=2052 "ProductName" "${PRODUCT_NAME}"
VIAddVersionKey /LANG=2052 "Comments" "${PRODUCT_COMMENTS}"
VIAddVersionKey /LANG=2052 "CompanyName" "${PRODUCT_COMMENTS}"
VIAddVersionKey /LANG=2052 "LegalTrademarks" "${PRODUCT_NAME_EN}"
VIAddVersionKey /LANG=2052 "LegalCopyright" "${PRODUCT_LegalCopyright}"
VIAddVersionKey /LANG=2052 "FileDescription" "${PRODUCT_NAME}引导程序"
VIAddVersionKey /LANG=2052 "FileVersion" ${FILE_VERSION}
VIAddVersionKey /LANG=2052 "ProductVersion" ${PRODUCT_VERSION}
!define MUI_ICON "..\Resource\Package\appm.ico"

;Languages 
!insertmacro MUI_LANGUAGE "SimpChinese"
RequestExecutionLevel user
SilentInstall silent
OutFile "..\..\..\Temp\Temp\Launch.exe"

Function getLocalVersion
   ClearErrors
   ReadRegStr $varLocalVersion HKCU "${PRODUCT_REG_KEY}" "UpdateVersion"
   IfErrors 0 +2
   ReadRegStr $varLocalVersion HKCU "${PRODUCT_REG_KEY}" "ProductVersion"
   ;
FunctionEnd

Section InstallAppDataFiles
	ClearErrors
	ReadRegStr $R0 HKCU "${PRODUCT_REG_KEY}" "UpdateOldVersion"
	IfErrors 0 +2
	Goto +8
	${If} $R0 != ""
    IfFileExists "$EXEDIR\update\*" 0 +2
    RMDir /r /REBOOTOK "$EXEDIR\update"
	IfFileExists "$EXEDIR\$R0\*" 0 +4
    nsProcess::KillProcessByPath "$EXEDIR\$R0"
	RMDir /r /REBOOTOK "$EXEDIR\$R0"
	${EndIf}
	IfFileExists "$EXEDIR\$R0\*" 0 +2
	Goto +2
	DeleteRegValue HKCU "${PRODUCT_REG_KEY}" "UpdateOldVersion"
	;
  ClearErrors
  ${GetParameters} $R0 # 获得命令行
  ${GetOptions} $R0 "/File" $R1 # 在命令行里查找是否存在/T选项
  Call getLocalVersion
  Exec '"$EXEDIR\$varLocalVersion\${MAIN_APP_NAME}" $R1'
  Exec '"$EXEDIR\AutoUpdate.exe" /Auto'
  IfFileExists $EXEDIR\AutoUpdateSelf.exe 0 +2
  Delete $EXEDIR\AutoUpdateSelf.exe
  ;
SectionEnd
