<#
    .Name
    Get-NVAPI

    .Version 
    0.1

    .SYNOPSIS
    Example/test script for using the .NET NvAPIWrapper for managing NVidia GPUs

    .DESCRIPTION

    .Requirements
    - Powershell v3.0 or higher

    .EXAMPLE
    \Get-NVAPI.ps1

    .OUTPUTS
    System.Management.Automation.PSObject

    .Credits
    https://github.com/falahati/NvAPIWrapper

    .NOTES
    Author: EZTechhelp
    Site  : https://www.eztechhelp.com
#> 

#############################################################################
#region Configurable Script Parameters
#############################################################################

#---------------------------------------------- 
#region Global Variables
#----------------------------------------------
$Preferred_GPU_Value = 'id,2.0:220610DE,00000100,GF - (368,2,161,10240) @ (0)'
#---------------------------------------------- 
#endregion Global Variables
#----------------------------------------------

#############################################################################
#endregion Configurable Script Parameters
#############################################################################

#############################################################################
#region Execution and Output 
#############################################################################

try
{
  
  #Load the NVAPIWrapper.DLL
  $null = [System.Reflection.Assembly]::LoadFrom("$PSScriptRoot\Assembly\NvAPIWrapper.dll")

  #Get Primary Display Device
  $PrimaryDisplayDevice = [NvAPIWrapper.Display.DisplayDevice]::GetGDIPrimaryDisplayDevice()
  write-host "#### Primary Display Device ####" -ForegroundColor yellow
  write-host "$($PrimaryDisplayDevice | out-string)" -ForegroundColor Cyan
  
}
catch
{
  write-output "[ERROR] An exception occurred loading assemblies $_" 

}

#---------------------------------------------- 
#region Retrieving Current Settings for Global Profile
#----------------------------------------------
try
{
  #Load a new Driver Settings Session
  $DriverSettingsSession = [NvAPIWrapper.DRS.DriverSettingsSession]::CreateAndLoad()
  write-host "#### Driver Settings Session ####" -ForegroundColor yellow
  write-host "$($DriverSettingsSession | out-string)" -ForegroundColor Cyan
  
  #Display Current Global Profile and Settings
  write-host "#### Current Global Profile and Settings ####" -ForegroundColor yellow
  write-host "$($DriverSettingsSession.CurrentGlobalProfile | out-string)" -ForegroundColor Cyan  
  write-host "$($DriverSettingsSession.CurrentGlobalProfile.Settings | out-string)" -ForegroundColor Cyan 
}
catch
{
  write-output "[ERROR] An exception occurred getting Global Profile settings $_" 

}  
#---------------------------------------------- 
#endregion Retrieving Current Settings for Global Profile
#----------------------------------------------

#---------------------------------------------- 
#region Example for changing Preferred OpenGL GPU from Autoselect to specific GPU
#----------------------------------------------
function Set-PreferredGPU{
  <#
      .Example
      Set-PreferredGPU -Preferred_GPU $Preferred_GPU_Value
  #>
  param (
    [string]$Preferred_GPU
  )
  try
  {

    #Lets find what its currently set to 
    $DriverSettingsSession = [NvAPIWrapper.DRS.DriverSettingsSession]::CreateAndLoad()
    $Preferred_OpenGL_GPU = $DriverSettingsSession.CurrentGlobalProfile.Settings | where {$_.SettingInfo.Name -eq 'Preferred OpenGL GPU'}
    write-host "#### Current Preferred OpenGL GPU Value ####" -ForegroundColor Yellow
    write-host "$($Preferred_OpenGL_GPU.CurrentValue | out-string)"
  
    #Lets find what available setting values are
    write-host "#### Available setting values for Preferred OpenGL GPU ####" -ForegroundColor Yellow 
    write-host "$($Preferred_OpenGL_GPU.SettingInfo.AvailableValues | out-string)"
  
    #Lets get the value of the GPU we want (currently dont know how to know which setting is which GPU so using a reference machine with same hardware can help find value you want)
    $New_Preferred_OpenGL_GPU_Value = $Preferred_OpenGL_GPU.SettingInfo.AvailableValues | where {$_ -eq 'id,2.0:220610DE,00000100,GF - (368,2,161,10240) @ (0)'}
  
    #Now we can set the new value for Preferred OpenGL GPU. We will need the Setting ID, Setting type and new value
    write-host ">>>> Setting new value to $New_Preferred_OpenGL_GPU_Value" -ForegroundColor Cyan 
    $DriverSettingsSession.CurrentGlobalProfile.SetSetting($Preferred_OpenGL_GPU.SettingId,$Preferred_OpenGL_GPU.SettingType,$New_Preferred_OpenGL_GPU_Value)
  
    #Now lets save the profile
    write-host ">>>> Saving Profile" -ForegroundColor Cyan 
    $DriverSettingsSession.Save()
  
    #Now lets check the new value was set
    $DriverSettingsSession = [NvAPIWrapper.DRS.DriverSettingsSession]::CreateAndLoad()
    $New_Preferred_OpenGL_GPU = $DriverSettingsSession.CurrentGlobalProfile.Settings | where {$_.SettingInfo.Name -eq 'Preferred OpenGL GPU'}
    
    write-host "#### New Preferred OpenGL GPU Value ####" -ForegroundColor Yellow
    write-host "New Preferred OpenGL GPU: $($New_Preferred_OpenGL_GPU.CurrentValue | out-string)"
  
  }
  catch
  {
    write-output "[ERROR] An exception ocurred setting Preferrred OpenGL Value $_" 

  }
}
#---------------------------------------------- 
#endregion Example for changing Preferred OpenGL GPU from Autoselect to specific GPU
#----------------------------------------------  

#---------------------------------------------- 
#region See what apps are using gpu
#----------------------------------------------
$GPUhandle = new-object NvAPIWrapper.Native.GPU.Structures.PhysicalGPUHandle
$GPU_apps = [NvAPIWrapper.Native.GPUApi]::QueryActiveApps($GPUhandle)

write-host "#### Apps Currently Using the GPU ####" -ForegroundColor Yellow
write-host "$($GPU_apps | out-string)"
#---------------------------------------------- 
#endregion See what apps are using gpu
#----------------------------------------------


#---------------------------------------------- 
#region Get GPU Clock Speeds and Current Usage
#----------------------------------------------

$physicalGPU = [NvAPIWrapper.GPU.PhysicalGPU]::GetPhysicalGPUs()
$physicalGPU_handle = $physicalGPU.handle
$GPU_clocks = [NvAPIWrapper.Native.GPUApi]::GetAllClockFrequencies($physicalGPU_handle)
$usages = [NvAPIWrapper.Native.GPUApi]::GetUsages($physicalGPU_handle)

write-host "#### GPU Clock Speeds ####" -ForegroundColor Yellow
write-host "$($GPU_clocks | out-string)"

write-host "#### GPU Current Usage ####" -ForegroundColor Yellow
write-host "$($usages | out-string)"
#---------------------------------------------- 
#region  Get GPU Clock Speeds and Current Usage
#----------------------------------------------


#---------------------------------------------- 
#region Get Current Driver
#----------------------------------------------
$driver_branch_version = [NvAPIWrapper.NVIDIA]::DriverBranchVersion
$driver_Version = [NvAPIWrapper.NVIDIA]::DriverVersion

write-host "#### GPU Current Driver ####" -ForegroundColor Yellow
write-host "Driver Branch Version: $($driver_branch_version | out-string)"
write-host "Driver Version: $($driver_Version | out-string)"
#---------------------------------------------- 
#region Get Current Driver
#----------------------------------------------

#---------------------------------------------- 
#region Get Display HDR Data
#----------------------------------------------
$primary_display_device = [NvAPIWrapper.Display.DisplayDevice]::GetGDIPrimaryDisplayDevice()
#Get current hdr status/mode
$HDR_Current_Mode = new-object NvAPIWrapper.Native.Display.ColorDataHDRMode

write-host "#### GPU HDR Data ####" -ForegroundColor Yellow
write-host "HDR Driver Capabilities: $($primary_display_device.DriverHDRCapabilities.DisplayData | out-string)"
write-host "Current HDR Mode: $($HDR_Current_Mode)"

#---------------------------------------------- 
#region Get Display Capabilities and HDR Modes
#----------------------------------------------
#############################################################################
#endregion Execution and Output Functions
#############################################################################