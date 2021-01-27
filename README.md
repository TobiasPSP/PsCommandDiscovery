# PsCommandDiscovery
Most **PowerShell** users know the situation when you know what kind of information you need, but you do not know which command might help you.

The module **PsCommandDiscovery** aims to help users find commands. While the built-in `Get-Command` focuses on command name, parameters and origin, the new function `Find-PowerShellCommand` extends the search scope and finds commands based on their output as well. 

## Installation

Install from *PowerShell Gallery*:

```powershell
Install-Module -Name PsCommandDiscovery -Scope CurrentUser -Verbose
```

## Finding Commands by Keyword

Lists all cmdlets and functions that use the term "user" anywhere in its name, parameter, returned property or returned method.

```powershell
Find-PowerShellCommand -Keyword user
```

Sample result:

```
Command                                   MatchType   Member                                                                                                    
-------                                   ---------   ------                                                                                                    
Add-WinADUserGroups                       CommandName                                                                                                           
Convert-SidToUser                         CommandName                                                                                                           
Convert-SIDToUser                         CommandName                                                                                                           
(...)                                                                                                     
Get-Credential                            Property    [string] UserName (readonly)                                                                              
Get-Culture                               Property    [bool] UseUserOverride (readonly)                                                                         
Get-EventLog                              Property    [string] UserName (readonly)                                                                              
Get-LocalUser                             CommandName                                                                                                           
Get-PnPAADUser                            CommandName                                                                                                           
Get-PnPTeamsUser                          CommandName                                                                                                           
Get-PnPUser                               CommandName                                                                                                           
Get-PnPUserOneDriveQuota                  CommandName                                                                                                           
Get-PnPUserProfileProperty                CommandName                                                                                                           
Get-Process                               Property    [timespan] UserProcessorTime (readonly)                                                                   
Get-SPOCrossGeoMovedUsers                 CommandName                                                                                                           
Get-SPOCrossGeoUsers                      CommandName                                                                                                           
Get-SPOExternalUser                       CommandName                                                                                                           
Get-SPOSiteUserInvitations                CommandName                                                                                                           
Get-SPOUser                               CommandName                                                                                                           
Get-SPOUserAndContentMoveState            CommandName                                                                                                           
Get-SPOUserOneDriveLocation               CommandName                                                                                                           
Get-UICulture                             Property    [bool] UseUserOverride (readonly)                                                                         
Get-WinUserLanguageList                   CommandName                                                                                                           
Get-WUServiceManager                      CommandName                                                                                                           
(...)                                                                                                        
Start-Process                             Property    [timespan] UserProcessorTime (readonly)                                                                   
Start-SPOUserAndContentMove               CommandName                                                                                                           
Stop-Process                              Property    [timespan] UserProcessorTime (readonly)                                                                   
Stop-SPOUserAndContentMove                CommandName                                                                                                           
Update-AzADUser                           CommandName                                                                                                           
Update-UserType                           CommandName                                                                                                           
```

## Showing Progressbar and Limiting Search Scope

Lists all commands that return objects that expose a property with "user" in its name, and shows a progress bar while searching.

Using a progress bar can slow down the overall time the command requires.

```powershell
Find-PowerShellCommand -Keyword user -SearchType Property -ShowProgress
```

Sample result:

```
Command               MatchType Member                                                                                                                          
-------               --------- ------                                                                                                                          
Get-Credential        Property  [string] UserName (readonly)                                                                                                    
Get-Culture           Property  [bool] UseUserOverride (readonly)                                                                                               
Get-EventLog          Property  [string] UserName (readonly)                                                                                                    
Get-Process           Property  [timespan] UserProcessorTime (readonly)                                                                                         
Get-UICulture         Property  [bool] UseUserOverride (readonly)                                                                                               
New-PSTransportOption Property  [Nullable`1[[System.Int32, mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089]]] MaxSessionsPerUser ...
New-PSTransportOption Property  [Nullable`1[[System.Int32, mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089]]] MaxConcurrentUsers ...
Start-Process         Property  [timespan] UserProcessorTime (readonly)                                                                                         
Stop-Process          Property  [timespan] UserProcessorTime (readonly)                                                                                                           
```

## Searching in Parameters

Finds all cmdlets and functions with a parameter that contains "network"

```powershell
Find-PowerShellCommand -Keyword network -SearchType Parameter
```

Sample result:

```

```



