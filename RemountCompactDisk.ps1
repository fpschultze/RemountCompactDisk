#requires -RunAsAdministrator

<#
.SYNOPSIS
   Re-mounts compact disk drive.

.DESCRIPTION
   Script to iterate through all compact disk drives in order to change their drive letter assigments.
   By default the script begins with Z: as first new drive letter and works backwards among the set of
   available drive letters.

.EXAMPLE
  .\RemountCompactDisk.ps1

  Use the default (Z:) as starting drive letter.

.EXAMPLE
  .\RemountCompactDisk.ps1 -NewDriveLetter 'Y:'

  Use Y: as starting drive letter.

.NOTES
  The script requires elevated permissions.
  The script leverages mountvol.exe
#>
[CmdletBinding(SupportsShouldProcess=$true)]
Param
(
  # The new compact disk drive letter
  [Parameter()]
  [string]
  $NewDriveLetter = 'Z:'
)


#region Variables

Set-Variable -Name DriveType_CompactDisk -Value 5 -Option ReadOnly -WhatIf:$false

#endregion


#region Wrapper functions for mountvol.exe

function Get-VolumeMountPoint ($DriveLetter)
{
  $output = (mountvol.exe $DriveLetter /L).Trim()
  if ($LASTEXITCODE -ne 0)
  {
    throw ('{0}: {1}' -f $MyInvocation.InvocationName, $output)
  }
  $output
}

function Dismount-Volume ($DriveLetter)
{
  $output = mountvol.exe $DriveLetter /D
  if ($LASTEXITCODE -ne 0)
  {
    throw ('{0}: {1}' -f $MyInvocation.InvocationName, $output)
  }
  $true
}

function Mount-Volume ($DriveLetter, $MountPoint)
{
  $output = mountvol.exe $DriveLetter $MountPoint
  if ($LASTEXITCODE -ne 0)
  {
    throw ('{0}: {1}' -f $MyInvocation.InvocationName, $output)
  }
  $true
}

#endregion


#region Main

try
{
  $DriveLettersInUse = Get-CimInstance -ClassName Win32_LogicalDisk

  $LastDriveLetterInUse = $DriveLettersInUse | Select-Object -ExpandProperty DeviceID | Sort-Object -Descending | Select-Object -First 1

  $DriveLettersInUse | Where-Object {$_.DriveType -eq $DriveType_CompactDisk} | Sort-Object -Property DeviceID -Descending |
    ForEach-Object {

      $CurrentDriveLetter = $_.DeviceID

      if ($CurrentDriveLetter, $LastDriveLetterInUse -notcontains $NewDriveLetter)
      {
        if ($PSCmdlet.ShouldProcess($CurrentDriveLetter, "Re-mount using $NewDriveLetter"))
        {
          $MountPoint = Get-VolumeMountPoint -DriveLetter $CurrentDriveLetter

          if (Dismount-Volume -DriveLetter $CurrentDriveLetter)
          {
            if (Mount-Volume -DriveLetter $NewDriveLetter -MountPoint $MountPoint)
            {
              'Successfully re-mounted {0} to {1}' -f $CurrentDriveLetter, $NewDriveLetter | Write-Verbose
            }
          }
        }

        $NewDriveLetter = '{0}:' -f [char]([byte][char]$NewDriveLetter.Substring(0,1) - 1)
      }
      else
      {
        'Nothing to do (current compact disk drive letter: {0}, last drive letter in use: {1})' -f $CurrentDriveLetter, $LastDriveLetterInUse | Write-Warning
      }
    }
}
catch
{
  $_.Exception.Message | Write-Error
}

#endregion
