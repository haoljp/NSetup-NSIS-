;自定义宏
!define FILE_VERSION "1.3.1.2"
;初始化界面扩展操作
Function InstallProgressExt
   ;最小化按钮绑定函数
   nsSkinEngine::NSISFindControl "minbtn"
   Pop $0
   ${If} $0 == "-1"
    MessageBox MB_OK "Do not have minbtn"
   ${Else}
    GetFunctionAddress $0 OnInstallMinFunc
    nsSkinEngine::NSISOnControlBindNSISScript "minbtn" $0
   ${EndIf}
   
   nsSkinEngine::NSISFindControl "CancelDownloadBtn"
   Pop $0
   ${If} $0 == "-1"
    MessageBox MB_OK "Do not have CancelDownloadBtn"
   ${Else}
    GetFunctionAddress $0 OnInstallCancelFunc
    nsSkinEngine::NSISOnControlBindNSISScript "CancelDownloadBtn" $0
   ${EndIf}
FunctionEnd
;需要更新阶段扩展处理
Function NeedUpdateStepExt
    nsSkinEngine::NSISSetControlData "WizardTab"  "$varResourceDirBG_use.png"  "bkimage"
FunctionEnd
;升级无效或者不需要更新阶段扩展处理
Function NoNeedUpdateStepExt
	nsSkinEngine::NSISSetControlData "WizardTab"  "$varResourceDirBG_Latest_version.png"  "bkimage"
FunctionEnd
;网络错误阶段扩展处理
Function NetErrorStepExt
	nsSkinEngine::NSISSetControlData "WizardTab"  "$varResourceDirBG_error_network.png"  "bkimage"
FunctionEnd
;升级成功阶段扩展处理
Function UpdateSuccessStepExt
	nsSkinEngine::NSISSetControlData "WizardTab"  "$varResourceDirBG_upgrade_completed.png"  "bkimage"
FunctionEnd
;升级错误阶段扩展处理
Function UpdateErrorStepExt
	nsSkinEngine::NSISSetControlData "WizardTab"  "$varResourceDirBG_error_upgrade.png"  "bkimage"
FunctionEnd
;下载文件阶段扩展处理
Function DownloadUpdateStepExt
	nsSkinEngine::NSISSetControlData "WizardTab"  "$varResourceDirBG_updating.png"  "bkimage"
FunctionEnd
;替换文件阶段扩展处理
Function ReplaceFilesStepExt
	nsSkinEngine::NSISSetControlData "WizardTab"  "$varResourceDirBG_replace_data.png"  "bkimage"
FunctionEnd