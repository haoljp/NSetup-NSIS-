﻿/*
    Compile the script to use the Unicode version of NSIS
    The producers：surou
*/
Var Dialog
Var MessageBoxHandle
Var isSilence
Var isAutoRun
Var varLocalVersion
Var oldInstallPath
Var FreeSpaceSize
Var installPath
Var varResourceDir
Var autoInstall
Var varAsynTimerId
!define MUI_ICON "..\Resource\Package\app.ico"
; 引入的头文件
!include "MUI.nsh"
!include "FileFunc.nsh"
!include "StdUtils.nsh"
!include "nsPublic.nsh"
!include "LogicLib.nsh"
!include "nsSkinEngine.nsh"
!include "nsUtils.nsh"
!include "nsProcess.nsh"
!include "InstallExt.nsh"
RequestExecutionLevel admin
;文件版本声明-开始
VIProductVersion ${FILE_VERSION}
VIAddVersionKey /LANG=2052 "ProductName" "${PRODUCT_NAME}"
VIAddVersionKey /LANG=2052 "Comments" "${PRODUCT_COMMENTS}"
VIAddVersionKey /LANG=2052 "CompanyName" "${PRODUCT_COMMENTS}"
VIAddVersionKey /LANG=2052 "LegalTrademarks" "${PRODUCT_NAME_EN}"
VIAddVersionKey /LANG=2052 "LegalCopyright" "${PRODUCT_LegalCopyright}"
VIAddVersionKey /LANG=2052 "FileDescription" "${PRODUCT_NAME}安装程序"
VIAddVersionKey /LANG=2052 "FileVersion" ${FILE_VERSION}
VIAddVersionKey /LANG=2052 "ProductVersion" ${PRODUCT_VERSION}
;文件版本声明-结束




OutFile "..\..\..\Temp\Output\${PRODUCT_NAME_EN}Step.${PRODUCT_VERSION}.exe"
; 安装和卸载页面
Page         custom     InstallProgress
Page         instfiles  "" InstallShow

Function "FindHDD"
;获取查找到的驱动器盘符($9)可用空间(/D=F)单位兆(/S=M)
${DriveSpace} $9 "/D=F /S=M" $R0
${If} $R0 > $R1
StrCpy $R1 $R0
StrCpy $R2 $9
${EndIf}
Push $0
FunctionEnd

Function getLocalVersion
   ClearErrors
   ReadRegStr $varLocalVersion HKCU "${PRODUCT_REG_KEY}" "UpdateVersion"
   IfErrors 0 +2
   ReadRegStr $varLocalVersion HKCU "${PRODUCT_REG_KEY}" "ProductVersion"
   
FunctionEnd

;刷新关联图标
Function RefreshShellIcons
  System::Call 'shell32.dll::SHChangeNotify(i, i, i, i) v \
  (${SHCNE_ASSOCCHANGED}, ${SHCNF_IDLIST}, 0, 0)'
FunctionEnd

Function .onInit
    InitPluginsDir
	${If} ${PRODUCT_FORWORD_EFFECT_TYPE} > 0
      SetOutPath $PLUGINSDIR
      SetOverwrite try
      File /r "${NSISDIR}\Plugins\Common\effect.dll"
    ${EndIf}
    ClearErrors
    ${GetParameters} $R0 # 获得命令行
    ${GetOptions} $R0 "/S" $R1 # 在命令行里查找是否存在/T选项
    IfErrors 0 +3
    StrCpy $isSilence "0"
    Goto +2
    StrCpy $isSilence "1"
    ClearErrors
    ${GetParameters} $R0 # 获得命令行
    ${GetOptions} $R0 "/AutoRun" $R1 # 在命令行里查找是否存在/T选项
    IfErrors 0 +3
    StrCpy $isAutoRun "0"
    Goto +2
    StrCpy $isAutoRun "1"
	ClearErrors
    ${GetParameters} $R0 # 获得命令行
    ${GetOptions} $R0 "/Install" $R1 # 在命令行里查找是否存在/T选项
    IfErrors 0 +3
    StrCpy $autoInstall "0"
    Goto +2
    StrCpy $autoInstall "1"
	
    ${If} ${PRODUCT_INSTALL_DIR} == 0
        StrCpy $oldInstallPath "${DEFAULT_DIR}"
    ${ElseIf} ${PRODUCT_INSTALL_DIR} == 1
        StrCpy $oldInstallPath "$PROGRAMFILES\${PRODUCT_NAME_EN}"
    ${EndIf}
    
  SetOutPath "${UNINSTALL_DIR}\Install"
  SetOverwrite try
  ${If} ${PRODUCT_RESOURCE_ENCRYPT_TYPE} == 0
	File /r /x *.db "..\Resource\Package\Install\*.*"
	File /r /x *.db "..\Resource\Package\Common\*.*"
	StrCpy $R0 "${UNINSTALL_DIR}\Install"
    StrCpy $varResourceDir "${UNINSTALL_DIR}\Install\"
  ${Else}
    File /nonfatal "..\..\..\Temp\Resource\Install${PRODUCT_VERSION}.dat"
	StrCpy $R0 "${UNINSTALL_DIR}\Install\Install${PRODUCT_VERSION}.dat"
    StrCpy $varResourceDir ""
  ${EndIf}
;初始化数据  安装目录
   nsSkinEngine::NSISInitSkinEngine /NOUNLOAD "$R0" "Install_$(LANG_MESSAGE).xml" "WizardTab" "false" "${PRODUCT_NAME_EN}" "${PRODUCT_KEY}" "app.ico" "false"
   Pop $Dialog
   ;初始化MessageBox窗口
   nsSkinEngine::NSISInitMessageBox "MessageBox_$(LANG_MESSAGE).xml" "TitleLabl" "TextLabl" "CloseBtn" "OkBtn" "YESBtn" "NOBtn" "AbortBtn" "RetryBtn" "IgnoreBtn" "cancelBtn"
   Pop $MessageBoxHandle
  ;创建互斥防止重复运行
  nsUtils::NSISCreateMutex "${PRODUCT_NAME_EN}Install"
  Pop $R0
  ${If} $R0 == ${HASRUN}
    nsSkinEngine::NSISMessageBox ${MB_OK} "" "$(MUTEX_MESSAGE)"
    Abort
  ${EndIf}
  
  ReadRegStr $installPath HKCU "${PRODUCT_REG_KEY}" "installDir"
  ${If} $installPath == ""
    ;初始化安装位置 $APPDATA
    StrCpy $installPath $oldInstallPath
  ${Else}
    StrCpy $oldInstallPath $installPath
    Call getLocalVersion
    nsUtils::CompareVersion "${PRODUCT_VERSION}" "$varLocalVersion" "0.0.0.0"
    Pop $0
    ${If} $0 < ${RANGE_EQUAL_LARGE}
    ${AndIf} $autoInstall == "0"
	${AndIf} $isSilence == "0"
        nsSkinEngine::NSISMessageBox ${MB_OKCANCEL} "" "$(VERSION_COMPARE_MESSAGE)"
        Pop $1
        ${If} $1 == ${ON_CANCEL}
            Abort
        ${EndIf}
    ${EndIf}
  ${EndIf}
  Call OnInitExt
  ${If} $isSilence == "1"
	 Call killProgress
     nsSkinEngine::NSISStartInstall "true"
  ${EndIf}
  ${If} ${PRODUCT_FORWORD_EFFECT_TYPE} > 0
    nsSkinEngine::InitEffect "bkAnimLayout" "$PLUGINSDIR\effect.dll"
  ${EndIf}
FunctionEnd

Function OnProgressChangeCallback
Pop $0
${If} $0 == 100
	GetFunctionAddress $varAsynTimerId OnCompleteDoFunc
	nsSkinEngine::NSISCreatTimer $varAsynTimerId 1
${EndIf}
nsSkinEngine::NSISSetControlData "InstallProgressBar"  "$0"  "ProgressInt"
nsSkinEngine::NSISSetControlData "progressText"  "$0%"  "text"
FunctionEnd

Function InstallProgress
   ;关闭按钮绑定函数
   nsSkinEngine::NSISFindControl "InstallTab_sysCloseBtn"
   Pop $0
   ${If} $0 == "${NOFIND}"
    MessageBox MB_OK "Do not have InstallTab_sysCloseBtn"
   ${Else}
    GetFunctionAddress $0 OnInstallCancelFunc
    nsSkinEngine::NSISOnControlBindNSISScript "InstallTab_sysCloseBtn" $0
   ${EndIf}

   ;------------------------安装界面 1-----------------------
   ;开始安装按钮绑定函数
   nsSkinEngine::NSISFindControl "fastInstallBtn"
   Pop $0
   ${If} $0 == "${NOFIND}"
    MessageBox MB_OK "Do not have fastInstallBtn button"
   ${Else}
    GetFunctionAddress $0 FastInstallPageFunc    
        nsSkinEngine::NSISOnControlBindNSISScript "fastInstallBtn"  $0
   ${EndIf}
   
   ;是否同意
   nsSkinEngine::NSISFindControl "acceptCheckBox"
   ${If} $0 == "${NOFIND}"
    MessageBox MB_OK "Do not have acceptCheckBox"
   ${Else}
        GetFunctionAddress $0 acceptCheckChangedFunc    
        nsSkinEngine::NSISOnControlBindNSISScript "acceptCheckBox"  $0
   ${EndIf}
   
   ;使用协议
   nsSkinEngine::NSISFindControl "acceptBtn"
   Pop $0
   ${If} $0 == "${NOFIND}"
    MessageBox MB_OK "Do not have acceptBtn button"
   ${Else}
    GetFunctionAddress $0 acceptPageFunc    
        nsSkinEngine::NSISOnControlBindNSISScript "acceptBtn"  $0
   ${EndIf}
   
   ;自定义安装
   nsSkinEngine::NSISFindControl "customInstallBtn"
   Pop $0
   ${If} $0 == "${NOFIND}"
    MessageBox MB_OK "Do not have customInstallBtn button"
   ${Else}
    GetFunctionAddress $0 CustomInstallFunc    
        nsSkinEngine::NSISOnControlBindNSISScript "customInstallBtn"  $0
   ${EndIf}
   ;------------------------安装界面 2-----------------------
    ;安装路径编辑框设定数据
   nsSkinEngine::NSISFindControl "InstallTab_InstallFilePath"
   Pop $0
   ${If} $0 == "${NOFIND}"
    MessageBox MB_OK "Do not have InstallTab_InstallFilePath"
   ${Else}
   
    GetFunctionAddress $0 OnTextChangeFunc
    nsSkinEngine::NSISOnControlBindNSISScript "InstallTab_InstallFilePath" $0
    nsSkinEngine::NSISSetControlData "InstallTab_InstallFilePath" $installPath "text"
    Call OnTextChangeFunc
   ${EndIf}

   ;安装路径浏览按钮绑定函数
   nsSkinEngine::NSISFindControl "InstallTab_SelectFilePathBtn"
   Pop $0
   ${If} $0 == "${NOFIND}"
    MessageBox MB_OK "Do not have InstallTab_SelectFilePathBtn button"
   ${Else}
    GetFunctionAddress $0 OnInstallPathBrownBtnFunc    
        nsSkinEngine::NSISOnControlBindNSISScript "InstallTab_SelectFilePathBtn"  $0
   ${EndIf}
   ;------------------------安装界面 3-----------------------
   ;立即安装
   nsSkinEngine::NSISFindControl "Select_Install_Btn"
   Pop $0
   ${If} $0 == "${NOFIND}"
    MessageBox MB_OK "Do not have Select_Install_Btn button"
   ${Else}
    GetFunctionAddress $0 InstallPageFunc    
        nsSkinEngine::NSISOnControlBindNSISScript "Select_Install_Btn"  $0
   ${EndIf}
   
   ;--------------------------------------完成页面----------------------------------
   nsSkinEngine::NSISFindControl "Install_run_Btn"
   Pop $0
   ${If} $0 == "${NOFIND}"
    MessageBox MB_OK "Do not have Install_run_Btn button"
   ${Else}
    GetFunctionAddress $0 OnCompleteBtnFunc    
        nsSkinEngine::NSISOnControlBindNSISScript "Install_run_Btn"  $0
   ${EndIf}
   Call InstallProgressExt
   ${If} $autoInstall == "1"
    nsProcess::KillProcessByPath "$oldInstallPath/uninst.exe"
	Call FastInstallPageFunc
	Call InstallPageFunc
   ${EndIf}
   nsSkinEngine::NSISRunSkinEngine "true"
FunctionEnd

Function OnInstallMinFunc
    nsSkinEngine::NSISMinSkinEngine
FunctionEnd

Function InstallBackTab
	${If} ${PRODUCT_FORWORD_EFFECT_TYPE} > 0
		GetFunctionAddress $0 InstallBackTabFunc
		nsSkinEngine::StartEffect "bkAnimLayout" "${PRODUCT_BACK_EFFECT_TYPE}" $0
	${Else}
		Call InstallBackTabFunc
	${EndIf}
FunctionEnd
   
Function InstallBackTabFunc
    nsSkinEngine::NSISBackTab "WizardTab"
FunctionEnd

Function InstallNextTab
    Call InstallNextTabExt
	${If} ${PRODUCT_FORWORD_EFFECT_TYPE} > 0
		GetFunctionAddress $0 InstallNextTabFunc
		nsSkinEngine::StartEffect "bkAnimLayout" "${PRODUCT_FORWORD_EFFECT_TYPE}" $0
	${Else}
		Call InstallNextTabFunc
	${EndIf}
FunctionEnd

Function InstallNextTabFunc
	nsSkinEngine::NSISNextTab "WizardTab"
FunctionEnd

Function CustomInstallFunc
    Call CustomInstallFuncExt
FunctionEnd

Function FastInstallPageFunc
    Call InstallNextTab	
    Call InstallPageFuncExt
FunctionEnd

Function OnInstallCancelFunc
   nsSkinEngine::NSISMessageBox ${MB_OKCANCEL} "" "$(APP_EXIT_MESSAGE)"
   Pop $0
    ${If} $0 == "1"
     nsSkinEngine::NSISExitSkinEngine "false"
   ${EndIf} 
FunctionEnd

Function UpdateFreeSpace
  Pop $R0
  ${GetRoot} $R0 $0
  StrCpy $1 "Bytes"

  System::Call kernel32::GetDiskFreeSpaceEx(tr0,*l,*l,*l.r0)
   ${If} $0 > 1024
   ${OrIf} $0 < 0
      System::Int64Op $0 / 1024
      Pop $0
      StrCpy $1 "KB"
      ${If} $0 > 1024
      ${OrIf} $0 < 0
     System::Int64Op $0 / 1024
     Pop $0
     StrCpy $1 "MB"
     ${If} $0 > 1024
     ${OrIf} $0 < 0
        System::Int64Op $0 / 1024
        Pop $0
        StrCpy $1 "GB"
     ${EndIf}
      ${EndIf}
   ${EndIf}

   Push "$0$1"
FunctionEnd

Function FreshInstallDataStatusFunc
   ;路径是否合法（合法则不为0Bytes）
   nsSkinEngine::NSISGetControlData InstallTab_InstallFilePath "text"
   Call UpdateFreeSpace
   Pop $R0
   
   ;更新磁盘空间文本显示
   nsSkinEngine::NSISFindControl "InstallTab_FreeSpace"
   Pop $0
   ${If} $0 == "-1"
    nsSkinEngine::NSISMessageBox "" "Do not have InstallTab_FreeSpace"
   ${Else}
    nsSkinEngine::NSISSetControlData "InstallTab_FreeSpace"  "剩余空间：$R0"  "text"
   ${EndIf}
   
   ${If} $R0 == "0Bytes"
    nsSkinEngine::NSISSetControlData "InstallTab_InstallBtn" "false" "enable"
   ${Else}
    nsSkinEngine::NSISSetControlData "InstallTab_InstallBtn" "true" "enable"
   ${EndIf}
FunctionEnd

Function OnTextChangeFunc
   ; 改变可用磁盘空间大小
   nsSkinEngine::NSISGetControlData InstallTab_InstallFilePath "text"
   Pop $0
   StrCpy $INSTDIR $0
   Call FreshInstallDataStatusFunc
FunctionEnd

Function OnInstallPathBrownBtnFunc
   nsSkinEngine::NSISGetControlData "InstallTab_InstallFilePath" "text" ;
   Pop $installPath
   nsSkinEngine::NSISSelectFolderDialog "$(SELECT_FOLD_MESSAGE)" $installPath
   Pop $0
   ${If} $0 != "${SELECT_CANCEL}"
      StrCpy $INSTDIR "$0\${PRODUCT_NAME_EN}"
      ;设置安装路径编辑框文本
      nsSkinEngine::NSISFindControl "InstallTab_InstallFilePath"
      Pop $0
      ${If} $0 == "${NOFIND}"
     MessageBox MB_OK "Do not have Wizard_InstallPathBtn4Page2 button"
      ${Else}
     nsSkinEngine::NSISSetControlData "InstallTab_InstallFilePath" $INSTDIR "text"
     Call OnTextChangeFunc
      ${EndIf}
   ${EndIf}
FunctionEnd

Function acceptCheckChangedFunc
	nsSkinEngine::NSISGetControlData "acceptCheckBox" "Checked"
    Pop $0
    ${If} $0 == "${CHECKED}"
		nsSkinEngine::NSISSetControlData "fastInstallBtn"  "true"  "enable"
	${Else}
		nsSkinEngine::NSISSetControlData "fastInstallBtn"  "false"  "enable"
    ${EndIf}
FunctionEnd

Function acceptPageFunc
	ExecShell "open" "${PRODUCT_LICENSE_WEB_SITE}"
FunctionEnd

Function InstallPageFunc
	Call killProgress
	nsProcess::KillProcessByName "AutoUpdate.exe"
    ;设置进度条
    nsSkinEngine::NSISFindControl "InstallProgressBar"
      Pop $0
      ${If} $0 == "${NOFIND}"
     MessageBox MB_OK "Do not have InstallProgressBar"
      ${Else}
     nsSkinEngine::NSISSetControlData "InstallProgressBar"  "0"  "ProgressInt"
     nsSkinEngine::NSISSetControlData "progressText"  "0%"  "text"
     Call InstallingExt
     nsSkinEngine::NSISStartInstall "true"
     ${EndIf} 
FunctionEnd

Function killProgress
	nsProcess::FindProcessByName "${MAIN_APP_NAME}"
	Pop $R0
	${If} $R0 == ${FINDPROCESS}
		${If} $isSilence == "0"
        ${AndIf} $autoInstall == "0"
			nsSkinEngine::NSISMessageBox ${MB_OKCANCEL} "" "$(APP_RUNNING_MESSAGE)"
			Pop $1
			${If} $1 == ${ON_OK}
				nsProcess::KillProcessByPath "$oldInstallPath"     ;强制结束进程
			${Else}
				nsSkinEngine::NSISExitSkinEngine "false"
			${EndIf}
		${Else}
			nsProcess::KillProcessByPath "$oldInstallPath"     ;强制结束进程
		${EndIf}
	${EndIf}
FunctionEnd

Function InstallShow
  GetFunctionAddress $0 OnProgressChangeCallback
  nsSkinEngine::SetProgressChangeCallback $0
FunctionEnd

Function OnCompleteDoFunc
    nsSkinEngine::NSISKillTimer $varAsynTimerId
    Call OnCompleteDo
    Call InstallNextTab
    Call InstallCompleteExt
FunctionEnd

Section "-LogSetOn"
  LogSet on
SectionEnd

Section InstallFiles
  ${If} ${PRODUCT_OVERLAY_INSTALL_TYPE} == 1
    CopyFiles /SILENT "$oldInstallPath/uninst.exe" "$TEMP\uninst.exe"
    ExecWait '"$TEMP\uninst.exe" /UnInstall $oldInstallPath /S'
  ${Else}
        IfFileExists "$INSTDIR\${PRODUCT_VERSION}\*" +7 0
        ${If} ${PRODUCT_SUPPORT_UPDATE} == 1
        ${AndIf} $varLocalVersion != ""
            IfFileExists "$oldInstallPath\$varLocalVersion\*" 0 +4
            CreateDirectory "$INSTDIR\${PRODUCT_VERSION}"
            CopyFiles /SILENT "$oldInstallPath\$varLocalVersion\*.*" "$INSTDIR\${PRODUCT_VERSION}"
            RMDir /r /REBOOTOK "$oldInstallPath\$varLocalVersion"
        ${EndIf}
  ${EndIf}
  SetOutPath "$INSTDIR"
  SetOverwrite ifnewer
  File /r "..\..\..\Temp\Temp\*.*"
SectionEnd

Section SectionExt
  Call SectionFuncExt
SectionEnd

Section RegistKeys
	DeleteRegValue HKCU "${PRODUCT_REG_KEY}" "UpdateOldVersion"
    WriteRegStr HKCU "${PRODUCT_REG_KEY}" "UpdateVersion" "${PRODUCT_VERSION}"
    WriteRegStr HKCU "${PRODUCT_REG_KEY}" "ProductVersion" "${PRODUCT_VERSION}"
    WriteRegStr HKCU "${PRODUCT_REG_KEY}" "installDir" "$INSTDIR"
    WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\${MAIN_LAUNCHAPP_NAME}"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninst.exe"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\${MAIN_LAUNCHAPP_NAME},0"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
    Call RegistKeysExt
SectionEnd

Section CreateShorts
    ;创建开始菜单快捷方式
    CreateDirectory "$SMPROGRAMS\${PRODUCT_NAME_EN}"
    CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME_EN}\${PRODUCT_NAME}.lnk" "$INSTDIR\${MAIN_LAUNCHAPP_NAME}"
    CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME_EN}\Uninstall.lnk" "$INSTDIR\uninst.exe"
SectionEnd

Function OnCompleteDo
    SetOverwrite ifnewer
	nsSkinEngine::NSISGetControlData "deskShortCheckBox" "Checked" ;
    Pop $0
    ${If} $0 == "${CHECKED}"
      ;创建桌面快捷方式
    CreateShortCut "$DESKTOP\${PRODUCT_NAME}.lnk" "$INSTDIR\${MAIN_LAUNCHAPP_NAME}"
        ;${StdUtils.InvokeShellVerb} $0 "$oldInstallPath" "${MAIN_LAUNCHAPP_NAME}" ${StdUtils.Const.ShellVerb.UnpinFromTaskbar}
    ;${StdUtils.InvokeShellVerb} $0 "$INSTDIR" "${MAIN_LAUNCHAPP_NAME}" ${StdUtils.Const.ShellVerb.PinToTaskbar}
    ${EndIf}
    Call RefreshShellIcons
    nsSkinEngine::NSISSetControlData "InstallTab_sysCloseBtn"  "true"  "enable"
    nsSkinEngine::NSISGetControlData "autoRunCheckBox" "Checked" ;
    Pop $0
    ${If} $0 == "${CHECKED}"
	${OrIf} $isAutoRun == "1"
      WriteRegStr HKCU "${PRODUCT_AUTORUN_KEY}" "${PRODUCT_NAME}" "$INSTDIR\${MAIN_LAUNCHAPP_NAME} -mini"
    ${EndIf}
    ${If} ${PRODUCT_SUPPORT_STATISTICS} == 1
        nsStatistics::InitCommonStatistics
        ${If} $autoInstall == "1"
        nsStatistics::AddOneAttribute "step" "4"
        ${Else}
        nsStatistics::AddOneAttribute "step" "0"
        ${EndIf}
        nsStatistics::AddOneAttribute "currentversion" "${PRODUCT_VERSION}"
        nsStatistics::AddOneAttribute "channelid" "$EXEFILE"
        nsStatistics::SendStatisticsInfo "${PRODUCT_STATISTICS_ADDRESS}" "65B70DE7540C42759156483165E35215" "${PRODUCT_UPDATE_ID}"
    ${EndIf}
FunctionEnd
	
Function OnCompleteBtnFunc
    nsSkinEngine::NSISHideSkinEngine
    Exec '"$INSTDIR\${MAIN_LAUNCHAPP_NAME}" /launch'
    ;nsShellExecAsUser::ShellExecAsUser "open" "$INSTDIR\${MAIN_LAUNCHAPP_NAME}" "/launch"
	${If} $autoInstall == "1"
		SelfDel::del /RMDIR
	${EndIf}
    nsSkinEngine::NSISExitSkinEngine "false"
FunctionEnd

Function .onInstSuccess
	${If} $isSilence == "1"
		Call OnCompleteDo
	${EndIf}
FunctionEnd