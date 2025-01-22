<#
.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
#############################################################################
#                                     			 		                    #
#   This Sample Code is provided for the purpose of illustration only       #
#   and is not intended to be used in a production environment.  THIS       #
#   SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT    #
#   WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT    #
#   LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS     #
#   FOR A PARTICULAR PURPOSE.  We grant You a nonexclusive, royalty-free    #
#   right to use and modify the Sample Code and to reproduce and distribute #
#   the object code form of the Sample Code, provided that You agree:       #
#   (i) to not use Our name, logo, or trademarks to market Your software    #
#   product in which the Sample Code is embedded; (ii) to include a valid   #
#   copyright notice on Your software product in which the Sample Code is   #
#   embedded; and (iii) to indemnify, hold harmless, and defend Us and      #
#   Our suppliers from and against any claims or lawsuits, including        #
#   attorneys' fees, that arise or result from the use or distribution      #
#   of the Sample Code.                                                     #
#                                     			 		                    #
#   Author: John Guy                                                        #
#   Version 1.0         Date Last modified:      22 January 2025            #
#                                     			 		                    #
#############################################################################
#>

# Function to delete tasks inside GUID-named folders under EnterpriseMgmt in Task Scheduler and remove corresponding registry keys
function Delete-TasksAndRegistryKeys {
    # Connect to the Task Scheduler
    $TaskService = New-Object -ComObject Schedule.Service
    $TaskService.Connect()

    # Navigate to the EnterpriseMgmt folder
    $RootFolderPath = "\Microsoft\Windows\EnterpriseMgmt"
    try {
        $RootFolder = $TaskService.GetFolder($RootFolderPath)
    } catch {
        Write-Host "The folder '$RootFolderPath' does not exist or cannot be accessed." -ForegroundColor Red
        return
    }

    # Retrieve all subfolders under EnterpriseMgmt
    $Subfolders = $RootFolder.GetFolders(0)

    foreach ($Folder in $Subfolders) {
        # Check if the folder name matches the GUID pattern
        if ($Folder.Name -match "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$") {
            Write-Host "Processing folder: $($Folder.Name)" -ForegroundColor White

            try {
                # Retrieve all tasks in the folder
                $Tasks = $Folder.GetTasks(0)

                foreach ($Task in $Tasks) {
                    Write-Host "Deleting task: $($Task.Name) in folder $($Folder.Name)" -ForegroundColor Yellow
                    $Folder.DeleteTask($Task.Name, 0)
                    Write-Host "Task '$($Task.Name)' deleted successfully." -ForegroundColor Green
                }

                # If no tasks were found
                if ($Tasks.Count -eq 0) {
                    Write-Host "No tasks found in folder: $($Folder.Name)" -ForegroundColor Cyan
                }

                # Delete corresponding registry key
                $RegistryPath = "HKLM:\SOFTWARE\Microsoft\Enrollments\$($Folder.Name)"
                if (Test-Path -Path $RegistryPath) {
                    Write-Host "Deleting registry key: $RegistryPath" -ForegroundColor Yellow
                    Remove-Item -Path $RegistryPath -Recurse -Force
                    Write-Host "Registry key '$RegistryPath' deleted successfully." -ForegroundColor Green
                } else {
                    Write-Host "Registry key '$RegistryPath' does not exist. Skipping..." -ForegroundColor Cyan
                }
            } catch {
                Write-Host "Failed to delete tasks or registry key for folder '$($Folder.Name)'. Error: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "Skipping non-GUID folder: $($Folder.Name)" -ForegroundColor Cyan
        }
    }

    # Run gpupdate /force to refresh group policy settings
    Write-Host "Running gpupdate /force to refresh group policy settings..." -ForegroundColor Yellow
    try {
        Start-Process -FilePath "gpupdate" -ArgumentList "/force" -Wait -NoNewWindow
        Write-Host "gpupdate /force completed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to run gpupdate /force. Error: $_" -ForegroundColor Red
    }
}

# Execute the function
Delete-TasksAndRegistryKeys
