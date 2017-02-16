# RemountCompactDisk
PowerShell script to re-mount compact disk drive letters.

Script to iterate through all compact disk drives in order to change their drive letter assigments.

By default the script begins with Z: as first new drive letter and works backwards among the set of available drive letters.

The script requires elevated permissions.

The script leverages mountvol.exe
