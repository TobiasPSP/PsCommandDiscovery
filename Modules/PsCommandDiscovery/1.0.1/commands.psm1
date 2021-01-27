# Enum defined as c# to make sure it gets exported by the module:
Add-Type -TypeDefinition @"
   [System.Flags]
   public enum PsoSearchType
   {
      CommandName = 1,
      Parameter = 2,
      Property = 4,
      Method = 8
   }
"@


function Test-ApplicationType
{
  <#
      .SYNOPSIS
      Returns the type of an application (architecture, console/gui)

      .DESCRIPTION
      Can be used to identify console-based commands and distinguish them from gui tools
      Analyzes the PE header so this cmdlet is probably specific for the Windows platform
      and won't work on other OS

      .PARAMETER Path
      Path to executable.

      .EXAMPLE
      Test-ApplicationType -Path c:\windows\explorer.exe
      returns the details about the specified executable

      .LINK
      https://github.com/TobiasPSP/PsCommandDiscovery
  #>


  param
  (
    [Parameter(Mandatory)]
    [string]
    $Path
  )
  
  $bytes = [Byte[]]::new(4096)
  $infos = [Ordered]@{}
  $infos['Name'] = [System.Io.Path]::GetFileNameWithoutExtension($Path)
  $infos['Extension'] = [System.IO.Path]::GetExtension($Path)
  $infos['Directory'] = Split-Path -Path $Path
  $infos['Type'] = 'Unknown'
  $infos['Architecture'] = 'Unknown'
  $infos['VersionInfo'] = (Get-Item -Path $Path).VersionInfo
  try
  {
    $stream = [System.IO.FileStream]::new($path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
    if (($stream.Read($bytes, 0, 4096) -and $bytes[0] -eq 0x4d -and $bytes[1] -eq 0x5a) -eq $true) 
    {
      $offset = [system.bitconverter]::touint32($bytes, 60)
      $architecture  = [system.bitconverter]::touint16($bytes, $offset + 4)
      $appType    = [system.bitconverter]::touint16($bytes, $offset + 92)
      $infos['Architecture'] = switch ($architecture) {
        0x014c  { 'x86' }
        0x8664  { 'x64' }
      }
      $infos['Type'] = switch ($appType) {
        2  { 'Gui' }
        3  { 'Console' }
      }
    }
  }
  catch 
  {

  }
  finally
  {
    $stream.close()
  }

  return [pscustomobject]$infos | Add-Member -MemberType ScriptMethod -Name ToString -Value { 
    '{1}: {0} ({2}) [{3}] {4}' -f $this.Name, $this.Extension.ToLower(), $this.Architecture, $this.Type, $this.VersionInfo.ProductVersion
  } -Force -PassThru
}

function Convert-CimTypeToNetType
{
  <#
      .SYNOPSIS
      Converts string CimType to the corresponding .NET type

      .PARAMETER CimType
      Name of the CimType to convert

      .PARAMETER ReturnUnknownTypeAsAstring
      When there is no corresponding .NET type, return the CimType

      .EXAMPLE
      Convert-CimTypeToNetType -CimType 'SInt16'
      returns the .NET type representing signed 16bit integers.

      .LINK
      https://github.com/TobiasPSP/PsCommandDiscovery
  #>


  param
  (
    [String]
    [Parameter(Mandatory,ValueFromPipeline)]
    $CimType,
    
    [switch]
    $ReturnUnknownTypeAsAstring
  )
  
  begin
  {
    $lookup = @{
      UInt8 = [Byte]
      UInt16 = [UInt16]
      UInt32 = [UInt32]
      UInt64 = [UInt64]
      SInt8 = [SByte]
      SInt16 = [Int16]
      SInt32 = [int]
      SInt64 = [Int64]
      Real32 = [Single]
      Real64 = [Double]
      Boolean = [bool]
      DateTime = [DateTime]
      Char16 = [Char]
      String = [string]
    }
  }
  
  process
  {
    $result = $lookup[$CimType]
    if ($ReturnUnknownTypeAsAstring -and ($result -eq $null))
    {
      return $CimType
    }
    return $result
  }
}

function Convert-TypeToTypeAccelerator
{
  <#
      .SYNOPSIS
      Accepts any .NET type and returns the PowerShell string representation

      .DESCRIPTION
      Shortens .NET full type names with the short forms used by PowerShell:
      - returns the available PowerShell type accelerator
      - If no type accelerator is available, strips the "System." namespace from the type.

      .PARAMETER Type
      Type to convert

      .EXAMPLE
      Convert-TypeToTypeAccelerator -Type ([System.Xml.XmlDocument])
      returns the short PowerShell type accelerator "Xml"

      .EXAMPLE
      [System.Int32] | Convert-TypeToTypeAccelerator
      returns the short PowerShell type accelerator "int"

      .EXAMPLE
      Convert-TypeToTypeAccelerator -Type ([System.Int16])
      since there is no PowerShell type accelerator for this type, strips the default namespace
      and returns "Int16"

      .LINK
      https://github.com/TobiasPSP/PsCommandDiscovery
  #>


  param
  (
    [Type]
    [Parameter(Mandatory,ValueFromPipeline)]
    $Type
  )

  begin
  {
    if ($script:lookup -eq $null)
    {
      $typeaccelerators = [PSObject].Assembly.GetType('System.Management.Automation.TypeAccelerators')::Get
      $typeaccelerators.Keys | ForEach-Object { $lookup = @{} } { 
        $key = $typeaccelerators[$_]
        if ($lookup.ContainsKey($key))
        {
          if ($lookup[$key].Length -gt $_.length)
          {
            $lookup[$key] = $_
          }
        }
        else
        {
          $lookup[$key] = $_
        } 
      }
    }
  }
  
  process
  {
    $typeName = $lookup[$Type]
    if ([string]::IsNullOrEmpty($typename)) 
    {
      $typename = $_.FullName -replace '^System\.'
    }
    return $typeName
  }

}
function Find-PowerShellCommand
{
  <#
      .SYNOPSIS
      Helps discover PowerShell commands by looking for keywords in name and returned properties

      .DESCRIPTION
      Get-Command lets you find commands only based on command attributes such as name, module, or parameters.
      Often, a user searches for a command that will actually provide a given piece of information.
      Find-Command takes a keyword and looks at the actual results of a command.
      It then lists all commands that matches the keyword in
      - the command name
      - any property name
      - any property of any of the returned object types
      - any method of any of the returned object types
      
      .PARAMETER Keyword
      A string keyword describing what you are looking for, i.e. "user"

      .PARAMETER CommandType
      The type of command you are looking for, i.e. 'Cmdlet', 'Function', 'Alias', or 'Application'. 
      You can specify multiple values as a comma-separated list

      .PARAMETER SearchType
      The scope of search that should be performed. Supported values are 'CommandName', 'Parameter', 'Property' and 'Method'

      .PARAMETER ShowProgress
      When specified, a progress bar is shown. This slows the command down considerably but may be helpful when queries take a long time.

      .EXAMPLE
      Find-PowerShellCommand -Keyword user
      Lists all cmdlets and functions that use the term "user" anywhere in its name, parameter, returned property or returned method.

      .EXAMPLE
      Find-PowerShellCommand -Keyword user -SearchType Property -ShowProgress
      Lists all commands that return objects that expose a property with "user" in its name, and shows a progress bar while searching.

      .EXAMPLE
      Find-PowerShellCommand -Keyword network -SearchType Parameter
      Finds all cmdlets and functions with a parameter that contains "network"

      .EXAMPLE
      Find-PowerShellCommand -Keyword power -CommandType Application
      Finds all executables and differentiates console commands from gui applications

      .EXAMPLE
      Find-PowerShellCommand -Keyword power -CommandType Application | Where-Object Type -eq Console | Select-Object -ExpandProperty Command
      Finds all console applications and lists version and source
      Again, all information returned is object-oriented so you can drill into the properties to retrieve what you need.

      .EXAMPLE
      Find-PowerShellCommand -Keyword Write -SearchType Method | Select-Object -Property Command, @{N='MethodName';E={$_.Member}}, @{N='Module';E={$_.Command.ModuleName}}
      Lists all commands that produce objects with methods that carry a "Write" in the method name.
      Note how you can use hashtables and calculated properties to combine information from different nest levels.
      
      .LINK
      https://github.com/TobiasPSP/PsCommandDiscovery
  #>


  param
  (
    [Parameter(Mandatory)]
    [string]
    $Keyword,
    
    [System.Management.Automation.CommandTypes[]] 
    $CommandType = 'Function,Cmdlet',
    
    [PsoSearchType]
    $SearchType = 'CommandName,Property',
    
    [switch]
    $ShowProgress
  
  )

  # get list of PowerShell type accelerators:
  $typeaccelerators = [PSObject].Assembly.GetType('System.Management.Automation.TypeAccelerators')::Get
  $typeaccelerators.Keys | ForEach-Object { $lookup = @{} } { $lookup[$typeaccelerators[$_]] = $_ }
 
  # whitelist of extensions considered an executable application
  $application = '.exe','.msc','.com','.bat','.vbs','.cpl'

  # get requested commands...
  if ($ShowProgress) { Write-Progress -Activity "Finding Commands for keyword '$keyword'" -Status 'Acquiring available commands' }
  $commands = Get-Command -CommandType $CommandType
  
  $commandCount = $commands.Count
  $currentCount = 0
  # select commands based on submitted keyword
  $commands | Foreach-Object {
    $command = $_
    $currentCount++
    
    if ($ShowProgress) 
    { 
      $percent = $currentCount * 100 / $commandCount
      Write-Progress "Finding Commands for keyword '$keyword'" -Status $command.Name -PercentComplete $percent
    }
      
    # check applications first if included in search:
    if ($Command.CommandType -eq 'Application')
    {
      # ignore extensions that cannot be directly called
      
      if ($_.Extension -in $application)
      {
        if ($_.Name -like "*$Keyword*")
        {
          $appInfo = Test-ApplicationType -Path $command.Path
          # command name matches keyword
          return  [PSCustomObject]@{
            Command = $command
            MatchType = 'Command'
            Member = $appInfo
            Type = $appInfo.Type
          }
        }
      }
    }
    else
    {
      # check whether any returned property matches the keyword:
      if ($Command.OutputType -and ($SearchType -band [PsoSearchType]::Property) -eq 'Property')
      {
        $command.OutputType | ForEach-Object {
          $outputType = $_
          # if the result is a .NET type...
          if ($outputType.Type -ne $null)
          {
            # examine all property names
            $outputType.Type.GetProperties() | ForEach-Object {
              if ($_.Name -like "*$keyword*")
              {
                # property name matches keyword
                $readonly = !$_.CanWrite
                           
                $propertyInfo = [PSCustomObject]@{
                  MemberName = $_.Name
                  Writeable = !$readonly
                  Type = $_.PropertyType
                  TypeName = $_.PropertyType | Convert-TypeToTypeAccelerator
                  PropertyInfo = $_
                } | Add-Member -MemberType ScriptMethod -Name ToString -Value { 
                  $note = if ($this.Writeable) { 'read/write' } else { 'readonly' }
                  '[{0}] {1} ({2})' -f $this.typename, $this.MemberName, $note 
                } -Force -PassThru


                [PSCustomObject]@{
                  Command = $command
                  MatchType = 'Property'
                  Member = $propertyInfo
                  Type = $outputType | Add-Member -MemberType ScriptMethod -Name ToString -Value { '[{0}]' -f $this.Type.FullName } -Force -PassThru
                }
              }
            }
          }
          # if type is $null then this is a WMI instance
          else
          {
            $wminame = $_.Name.Split('#')
            if ($wminame.Count -eq 2)
            {
              $namespace = Split-Path -Path $wminame[1]
              $classname = Split-Path -Path $wminame[1] -Leaf
              Get-CimClass -ClassName $classname -Namespace $namespace -ErrorAction Ignore |
              ForEach-Object {
                $wmiclass = $_
                $wmiclass.CimClassProperties| ForEach-Object {
                  if ($_.Name -like "*$keyword*")
                  {
                    $readonly = ($_.Flags -band 'ReadOnly') -eq 'ReadOnly'
                    $writeable = $_.Qualifiers.Where{$_.Name -eq 'write'}.Count -eq 1
                    $type = $_.CimType | Convert-CimTypeToNetType
                    $typename = if ($type -eq $null) { $_.CimType } else { $type | Convert-TypeToTypeAccelerator  }
                    $propertyInfo = [PSCustomObject]@{
                      MemberName = $_.Name
                      Writeable = !$readonly -or $writeable
                      Type = $type
                      TypeName = $typename 
                      PropertyInfo = $_
                    } | Add-Member -MemberType ScriptMethod -Name ToString -Value { 
                      $note = if ($this.Writeable) { 'read/write' } else { 'readonly' }
                      '[{0}] {1} ({2})' -f $this.TypeName, $this.MemberName, $note 
                    } -Force -PassThru
                  
                    # property name matches keyword
                    [PSCustomObject]@{
                      Command = $command
                      MatchType = 'WMIProperty'
                      Member = $propertyInfo
                      Type = $wmiclass
                    }
                  }
                }
              }
            }
          }
        }
      }
    
    
      # check whether any method in the returned object matches the keyword:
      if ($Command.OutputType -and ($SearchType -band [PsoSearchType]::Method) -eq 'Method')
      {
        $command.OutputType | ForEach-Object {
          $outputType = $_
          # if the result is a .NET type...
          if ($outputType.Type -ne $null)
          {
            # examine all property names
            $outputType.Type.GetMethods() | ForEach-Object {
              # does the method name match the keyword and is not a property getter/setter:
              if (($_.Name -like "*$keyword*") -and ($_.Name -notmatch '^(get_|set_)'))
              {
                $methodInfo = [PSCustomObject]@{
                  MemberName = $_.Name
                  Static = $_.IsStatic
                  Type = $_.ReturnType
                  TypeName = $_.ReturnType | Convert-TypeToTypeAccelerator
                  MethodInfo = $_
                } | Add-Member -MemberType ScriptMethod -Name ToString -Value { '[{0}] {1}(){2}' -f $this.TypeName, $this.MemberName, $(if($this.Static) { ' (static)' }) } -Force -PassThru


                [PSCustomObject]@{
                  Command = $command
                  MatchType = 'Method'
                  Member = $methodInfo
                  Type = $outputType | Add-Member -MemberType ScriptMethod -Name ToString -Value { '[{0}]' -f $this.Type.FullName } -Force -PassThru
                }
              }
            }
          }
          # if type is $null then this is a WMI instance
          else
          {
            $wminame = $_.Name.Split('#')
            if ($wminame.Count -eq 2)
            {
              $namespace = Split-Path -Path $wminame[1]
              $classname = Split-Path -Path $wminame[1] -Leaf
              Get-CimClass -ClassName $classname -Namespace $namespace -ErrorAction Ignore |
              ForEach-Object {
                $wmiclass = $_
                $wmiclass.CimClassMethods| ForEach-Object {
                  if ($_.Name -like "*$keyword*")
                  {
                    $isStatic = $_.Qualifiers.Where{$_.Name -eq 'static'}.Count -eq 1
                    $type = $_.ReturnType | Convert-CimTypeToNetType
                    $typename = if ($type -eq $null) { $_.ReturnType } else { $type | Convert-TypeToTypeAccelerator  }
                    $methodInfo = [PSCustomObject]@{
                      MemberName = $_.Name
                      Static = $isStatic
                      Type = $type
                      TypeName = $typename 
                      MethodInfo = $_
                    } | Add-Member -MemberType ScriptMethod -Name ToString -Value { 
                      '[{0}] {1} ({2})' -f $this.TypeName, $this.MemberName, $(if($this.Static) { ' (static)' }) 
                    } -Force -PassThru
                  
                    # method name matches keyword
                    [PSCustomObject]@{
                      Command = $command
                      MatchType = 'WMIMethod'
                      Member = $methodInfo
                      Type = $wmiclass
                    }
                  }
                }
              }
            }
          }
        }
      }
        
      # does command name match?
      if ($command.Name -like "*$Keyword*" -and (($SearchType -band [PsoSearchType]::CommandName) -eq 'CommandName'))
      {
        # command name matches keyword
        [PSCustomObject]@{
          Command = $command
          MatchType = 'CommandName'
          Member = $null
          Type = $null
        }
      }
    
      # does parameter name match?
      if (($SearchType -band [PsoSearchType]::Parameter) -eq 'Parameter')
      {
        if ($null -ne $command.Parameters -and (@($command.Parameters).Count -gt 0))
        {
          $command.Parameters.Keys | ForEach-Object {
            try
            {
              $parameter = $command.Parameters[$_]
            }
            catch
            {
              Wait-Debugger
            }
            if ($_ -like "*$keyword*")
            {
              $parameterInfo = [PSCustomObject]@{
                MemberName = $_
                Switch = $parameter.SwitchParameter
                Type = $parameter.ParameterType
                TypeName = $parameter.ParameterType | Convert-TypeToTypeAccelerator
                ParameterInfo = $parameter
              } | Add-Member -MemberType ScriptMethod -Name ToString -Value { '-{1} [{0}] {2}' -f $this.TypeName, $this.MemberName, $(if($this.Switch) { ' (Switch)' }) } -Force -PassThru
          
          
              # command name matches keyword
              [PSCustomObject]@{
                Command = $command
                MatchType = 'Parameter'
                Member = $parameterInfo
                Type = $command.ModuleName
              }
            }
          }
        }
      }
    }
  }
}