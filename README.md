# Reset_Intune
This PowerShell script assists with "resetting" Intune enrollment of a device with the Intune Sync Error 0x80190190 or Windows devices with expired certificates.

Run the script as Administrator.

The script will delete the Scheduled Tasks under _Microsoft - Windows - EnterpriseMgmt_.
Then the script will delete the correlated Registry key for the same GUID found above in _HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Enrollments_
