# PsCommandDiscovery
Finding **PowerShell** commands for a given mission isn't always easy. There are thousands of commands. Especially for new users, finding a good command to start with often is a show stopper.

The built-in `Get-Command` is a good choice to find commands based on name, verb, noun, module, or parameter.

`Find-PowerShellCommand` goes a step beyond. It takes a simple keyword from you. Just make sure the keyword describes either the command you are looking for, *or* the information you want to get.

`Find-PowerShellCommand` searches for your keyword not just in the command name. It also looks at the kinds of data *returned* by the command, so if you're looking for commands that help you get *IPAddresses*, `Find-PowerShellCommand` would find commands with arbitrary names that return objects with at least one property containing your keyword, i.e. *IPAddress*.

That makes discovering commands so much easier, for the new user as well as for the experienced **PowerShell** SysAdmin who's looking for some piece of information.

I've started work on this while updating one of my books. In a perfect world, I'd love to get your feedback via [Discussions](https://github.com/TobiasPSP/PsCommandDiscovery/discussions) so we can refine `Find-PowerShellCommand` and add more strategies and tools to make the first step easier: finding the automation command that can make your day.

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
Command                       MatchType Member                                      Type                      
-------                       --------- ------                                      ----                      
Enable-PSRemoting             Parameter -SkipNetworkProfileCheck [switch]  (Switch) Microsoft.PowerShell.Core 
Enable-PSSessionConfiguration Parameter -SkipNetworkProfileCheck [switch]  (Switch) Microsoft.PowerShell.Core 
Enter-PSSession               Parameter -EnableNetworkAccess [switch]  (Switch)     Microsoft.PowerShell.Core 
Invoke-Command                Parameter -EnableNetworkAccess [switch]  (Switch)     Microsoft.PowerShell.Core 
New-PSSession                 Parameter -EnableNetworkAccess [switch]  (Switch)     Microsoft.PowerShell.Core 
Set-WSManQuickConfig          Parameter -SkipNetworkProfileCheck [switch]  (Switch) Microsoft.WSMan.Management
```

## Searching for Applications

Finds all executables and differentiates console commands from gui applications.

```powershell
Find-PowerShellCommand -Keyword power -CommandType Application
```

Sample result:

```
Command            MatchType Member                                          Type   
-------            --------- ------                                          ----   
powercfg.cpl       Command   .cpl: powercfg (x64) [Gui] 10.0.19041.800       Gui    
powercfg.exe       Command   .exe: powercfg (x64) [Console] 10.0.19041.800   Console
POWERPNT.EXE       Command   .exe: POWERPNT (x86) [Gui] 16.0.13530.20440     Gui    
powershell.exe     Command   .exe: powershell (x64) [Console] 10.0.19041.800 Console
powershell_ise.exe Command   .exe: powershell_ise (x64) [Gui] 10.0.19041.1   Gui   
```

## Finding Console Commands Only

Finds all console applications and lists version and source.

Again, all information returned is object-oriented so you can drill into the properties to retrieve what you need.

```powershell
Find-PowerShellCommand -Keyword power -CommandType Application | 
  Where-Object Type -eq Console | Select-Object -ExpandProperty Command
```

Sample result:

```
CommandType     Name                                               Version    Source                                                                            
-----------     ----                                               -------    ------                                                                            
Application     powercfg.exe                                       10.0.19... C:\WINDOWS\system32\powercfg.exe                                                  
Application     powershell.exe                                     10.0.19... C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe   
```

## Tapping Into Rich Objects

Lists all commands that produce objects with methods that carry a "Write" in the method name.
      
Note how you can use hashtables and calculated properties to combine information from different nest levels.

```powershell
Find-PowerShellCommand -Keyword Write -SearchType Method | 
   Select-Object -Property Command, 
                    @{N='MethodName';E={$_.Member}}, 
                    @{N='Module';E={$_.Command.ModuleName}}
```

Sample result:

```
Command               MethodName                          Module                         
-------               ----------                          ------                         
Get-IseSnippet        [IO.FileStream] OpenWrite()         ISE                            
New-TemporaryFile     [IO.FileStream] OpenWrite()         Microsoft.PowerShell.Utility   
ConvertTo-Xml         [void] WriteTo()                    Microsoft.PowerShell.Utility   
ConvertTo-Xml         [void] WriteContentTo()             Microsoft.PowerShell.Utility   
Export-PSSession      [IO.FileStream] OpenWrite()         Microsoft.PowerShell.Utility   
Get-ChildItem         [IO.FileStream] OpenWrite()         Microsoft.PowerShell.Management
Get-Clipboard         [IO.FileStream] OpenWrite()         Microsoft.PowerShell.Management
Get-Clipboard         [void] Write()                      Microsoft.PowerShell.Management
Get-Clipboard         [IAsyncResult] BeginWrite()         Microsoft.PowerShell.Management
Get-Clipboard         [void] EndWrite()                   Microsoft.PowerShell.Management
Get-Clipboard         [Threading.Tasks.Task] WriteAsync() Microsoft.PowerShell.Management
Get-Clipboard         [void] WriteByte()                  Microsoft.PowerShell.Management
Get-Clipboard         [Threading.Tasks.Task] WriteAsync() Microsoft.PowerShell.Management
Get-EventLog          [void] WriteEntry() (static)        Microsoft.PowerShell.Management
Get-EventLog          [void] WriteEntry() (static)        Microsoft.PowerShell.Management
Get-EventLog          [void] WriteEntry() (static)        Microsoft.PowerShell.Management
Get-EventLog          [void] WriteEntry() (static)        Microsoft.PowerShell.Management
Get-EventLog          [void] WriteEntry()                 Microsoft.PowerShell.Management
Get-EventLog          [void] WriteEntry()                 Microsoft.PowerShell.Management
Get-EventLog          [void] WriteEntry()                 Microsoft.PowerShell.Management
Get-EventLog          [void] WriteEntry()                 Microsoft.PowerShell.Management
Get-EventLog          [void] WriteEntry() (static)        Microsoft.PowerShell.Management
Get-EventLog          [void] WriteEntry()                 Microsoft.PowerShell.Management
Get-EventLog          [void] WriteEvent()                 Microsoft.PowerShell.Management
Get-EventLog          [void] WriteEvent()                 Microsoft.PowerShell.Management
Get-EventLog          [void] WriteEvent() (static)        Microsoft.PowerShell.Management
Get-EventLog          [void] WriteEvent() (static)        Microsoft.PowerShell.Management
Get-Item              [IO.FileStream] OpenWrite()         Microsoft.PowerShell.Management
Get-Item              [IO.FileStream] OpenWrite()         Microsoft.PowerShell.Management
Get-ItemProperty      [IO.FileStream] OpenWrite()         Microsoft.PowerShell.Management
New-FileCatalog       [IO.FileStream] OpenWrite()         Microsoft.PowerShell.Security  
New-Item              [IO.FileStream] OpenWrite()         Microsoft.PowerShell.Management
Test-DscConfiguration [void] WriteError()                 PSDesiredStateConfiguration    
Test-DscConfiguration [void] WriteObject()                PSDesiredStateConfiguration    
Test-DscConfiguration [void] WriteObject()                PSDesiredStateConfiguration    
Test-DscConfiguration [void] WriteVerbose()               PSDesiredStateConfiguration    
Test-DscConfiguration [void] WriteWarning()               PSDesiredStateConfiguration    
Test-DscConfiguration [void] WriteCommandDetail()         PSDesiredStateConfiguration    
Test-DscConfiguration [void] WriteProgress()              PSDesiredStateConfiguration    
Test-DscConfiguration [void] WriteDebug()                 PSDesiredStateConfiguration    
Test-DscConfiguration [void] WriteInformation()           PSDesiredStateConfiguration    
Test-DscConfiguration [void] WriteInformation()           PSDesiredStateConfiguration  
```

# Helper Functions

The module comes with a number of helper functions that may be valuable by their own.

## Identifying Console Applications

`Test-ApplicationType` takes a path to an executable and investigates its PE header to find out whether it is a console or a gui application, and what its architecture is.

Obviously this works only for applications that have a PE header, so most likely this function can be used on *Windows* operating systems only.

```powershell
Test-ApplicationType -Path c:\windows\explorer.exe
```

Sample result:

```
Name         : explorer
Extension    : .exe
Directory    : c:\windows
Type         : Gui
Architecture : x64
VersionInfo  : File:             C:\windows\explorer.exe
               InternalName:     explorer
               OriginalFilename: EXPLORER.EXE.MUI
               FileVersion:      10.0.19041.800 (WinBuild.160101.0800)
               FileDescription:  Windows-Explorer
               Product:          Betriebssystem Microsoft® Windows®
               ProductVersion:   10.0.19041.800
               Debug:            False
               Patched:          False
               PreRelease:       False
               PrivateBuild:     False
               SpecialBuild:     False
               Language:         Deutsch (Deutschland)
```

## Converting Cim DataTypes

WMI (*Windows Management Instrumentation*) and its Cim derivates use their own data types such as *SInt16* or *SInt8*. 

`Convert-CimTypeToNetType` takes the string name of a *CimType* datatype and returns the corresponding .NET datatype:

```powershell
Convert-CimTypeToNetType -CimType 'SInt16'
```

Returns:

```
IsPublic IsSerial Name  BaseType        
-------- -------- ----  --------        
True     True     Int16 System.ValueType
```


## Shortening Data Types

**PowerShell** uses *Type Accelerators* for the most common .NET types and supports additional ways to shorten .NET data type names.

`Convert-TypeToTypeAccelerator` takes a regular .NET type and returns the short **PowerShell** data type description (as string):

```powershell
Convert-TypeToTypeAccelerator -Type ([System.Xml.XmlDocument])
```

returns:

```
xml
```

```powershell
[System.Int32] | Convert-TypeToTypeAccelerator
```

returns:

```
int
```




