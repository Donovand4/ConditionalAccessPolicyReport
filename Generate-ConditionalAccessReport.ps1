<#
#############################################################################  
#                                                                           #  
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
#                                                                           # 
#   This posting is provided "AS IS" with no warranties, and confers        # 
#   no rights. Use of included script samples are subject to the terms      # 
#   specified at http://www.microsoft.com/info/cpyright.htm.                # 
#                                                                           #  
#   Author: Donovan du Val                                                  #  
#   Version 1.0         Date Last Modified: 20 March 2020                   #  
#                                                                           #  
#############################################################################  
.SYNOPSIS
    PowerShell Script used to generate Conditional Access Policies.
    Created by: Donovan du Val
    Date: 13 May 2020
.DESCRIPTION
    The script will generate a report for all the Conditional Access Policies used in the Azure AD Tenant.
.EXAMPLE
    Generates a report in the CSV and HTML format
    PS C:\> Generate-ConditionalAccessReport.ps1 -export All
.EXAMPLE
    Generates a report in the CSV format
    PS C:\> Generate-ConditionalAccessReport.ps1 -export CSV
.EXAMPLE
    Generates a report in the HTML format
    PS C:\> Generate-ConditionalAccessReport.ps1 -export HTML
.INPUTS
   No inputs
.OUTPUTS
    Exports .html and .csv files that contains the Conditional Access policies.
.NOTES
    The script will connect to the Microsoft Graph service and collect the required information. 
.LINK
    Github 
    https://github.com/microsoftgraph/msgraph-sdk-powershell 
    Microsoft Graph PowerShell Module
    https://www.powershellgallery.com/packages/Microsoft.Graph
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("All", "CSV", "HTML")]
    $Export
  )
#Requires -Version 5.1
#Requires -Modules Microsoft.Graph.Identity.ConditionalAccess,Microsoft.Graph.Identity.ServicePrincipal,Microsoft.Graph.Users.User,Microsoft.Graph.Groups.Group,Microsoft.Graph.Identity.RoleManagement
Begin {    
    Clear-Host
    write-host "Importing the modules..."
    Import-Module Microsoft.Graph.Identity.ConditionalAccess,Microsoft.Graph.Identity.ServicePrincipal,Microsoft.Graph.Users.User,Microsoft.Graph.Groups.Group,Microsoft.Graph.Identity.RoleManagement

    write-host "Logging into Microsoft Graph" -ForegroundColor Green

    if ((Connect-Graph -Scopes "Policy.Read.All","Directory.Read.All") -eq $null) 
    {
        write-host "Login Failed. Exiting......." -ForegroundColor Red
        sleep -Seconds 2
        Exit
    } 
    else 
    {
        write-host "Successfully Logged into Microsoft Graph" -ForegroundColor Green
    }

    $Date = Get-Date -format dd-MMMM-yyyy
    $Filename = "ConditionalAccessReport - $($Date)"

    function Report-DirectoryApps {
        param (
            [Parameter(Mandatory=$true)]
            [String[]]
            $AppID
        )
        ($servicePrincipals | where-object {$_.AppID -eq $AppID}).AppDisplayName
    }
    
    function Report-NamedLocations {
      param (
          [Parameter(Mandatory=$true)]
          [String[]]
          $ID
      )
      switch ($ID) {
          "00000000-0000-0000-0000-000000000000" { "Unknown Site" }
          "All" {"All"}
          Default {
            ($namedLocations | where-object {$_.ID -eq $ID}).displayName}
      }
    }
    
    function Report-Users {
      param (
          [Parameter(Mandatory=$true)]
          [String[]]
          $ID
      )
      switch ($ID) {
          "GuestsOrExternalUsers" { "GuestsOrExternalUsers" }
          "All" {"All"}
          Default {
              $user = (Get-MgUser -UserId "$($ID)" -erroraction SilentlyContinue).userprincipalname
              if ($user)
              {
                  $user
              } 
              else{
                  "LookingUpError-$($ID)"
              }
          }
      }
    }
    
    function Report-Groups {
      param (
          [Parameter(Mandatory=$true)]
          [String[]]
          $ID
      )
      switch ($ID) {
          "GuestsOrExternalUsers" { "GuestsOrExternalUsers" }
          "All" {"All"}
          Default {
              $group = (Get-MgGroup -GroupId "$($ID)" -erroraction silentlycontinue).displayname
             if ($group)
             {
                  $group
              }
              else{
                  "LookingUpError-$($ID)"
              }
          }
      }
    }
    

  $Head = @"  
<style>
header {
    text-align: center;
  }
  body {
    font-family: "Arial";
    font-size: 10pt;
    color: #4C607B;
    }
  table, th, td {
  	width: 450px;
    border-collapse: collapse;
    border: solid;
    border: 1.5px solid black;
    padding: 3px;
	}
  th {
    font-size: 1.2em;
    text-align: center;
    background-color: #003366;
    color: #ffffff;
    }
  td {
    color: #000000;    
    }
    tr:nth-child(even) {background-color: #d6d6d6;}
</style>  
"@


}

process {
    Write-Host ""
    Write-host "Collecting Named Locations..." -ForegroundColor Green
    $namedLocations = Get-MgConditionalAccessNamedLocation | Select-Object displayname,id

    Write-Host "Collecting Service Principals..." -ForegroundColor Green
    $servicePrincipals = Get-MgServicePrincipal -Top 999 | Select-Object AppDisplayName,AppId
    Write-Host ""
    $Report = @()
#Collects the conditional access policies using the mgconditionalaccesspolicy command.
    foreach ($pol in (Get-MgConditionalAccessPolicy)) {
        $Report += New-Object PSobject -Property @{
        "Displayname"  = $pol.displayName
        "Description"  = $pol.Description
        "State" = $pol.state
        "ID"  = $pol.id
        "createdDateTime" = if ($pol.createdDateTime){$pol.createdDateTime} else {"Null"}          
        "ModifiedDateTime"  = if ($pol.ModifiedDateTime){$pol.ModifiedDateTime} else {"Null"}
        "UserIncludeUsers"  = if ($pol.Conditions.UserIncludeUsers) {($pol.Conditions.UserIncludeUsers | ForEach-Object{(Report-Users -ID $_ )}) -join ","} else {"Not Configured"} 
        "UserExcludeUsers"  = if ($pol.Conditions.UserExcludeUsers) {($pol.Conditions.UserExcludeUsers | ForEach-Object{(Report-Users -ID $_ )}) -join ","} else {"Not Configured"} 
        "UserIncludeGroups" = if ($pol.Conditions.UserIncludeGroups) {($pol.Conditions.UserIncludeGroups | ForEach-Object{(Report-Groups -ID $_ )}) -join ","} else {"Not Configured"}
        "UserExcludeGroups" = if ($pol.Conditions.UserExcludeGroups) {($pol.Conditions.UserExcludeGroups | ForEach-Object{(Report-Groups -ID $_ )}) -join ","} else {"Not Configured"}
        "UserIncludeRoles"  = if ($pol.Conditions.UserIncludeRoles) {($pol.Conditions.UserIncludeRoles | ForEach-Object{(Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $_).displayName}) -join "," } else {"Not Configured"}
        "UserExcludeRoles" = if ($pol.Conditions.UserExcludeRoles) {($pol.Conditions.UserExcludeRoles | ForEach-Object{(Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $_).displayName}) -join "," } else {"Not Configured"}
        "ConditionSignInRiskLevels" = if ($pol.Conditions.SignInRiskLevels) {$pol.Conditions.SignInRiskLevels -join ","} else {"Not Configured"}
        "ConditionClientAppTypes" = if ($pol.Conditions.ClientAppTypes) {$pol.Conditions.ClientAppTypes -join ","} else {"Not Configured"}
        "PlatformIncludePlatforms"  = if ($pol.Conditions.PlatformIncludePlatforms) {$pol.Conditions.PlatformIncludePlatforms -join ","} else {"Not Configured"}
        "PlatformExcludePlatforms"  = if ($pol.Conditions.PlatformExcludePlatforms) {$pol.Conditions.PlatformExcludePlatforms -join ","} else {"Not Configured"}
        "DeviceStateIncludeStates"  = if ($pol.Conditions.DeviceStateIncludeStates) {$pol.Conditions.DeviceStateIncludeStates -join ","} else {"Not Configured"}
        "DeviceStateExcludeStates"  = if ($pol.Conditions.DeviceStateExcludeStates) {$pol.Conditions.DeviceStateExcludeStates -join ","} else {"Not Configured"}
        "ApplicationIncludeApplications" = if ($pol.Conditions.ApplicationIncludeApplications) {($pol.Conditions.ApplicationIncludeApplications | ForEach-Object {Report-DirectoryApps -AppID $_}) -join ","} else {"Not Configured"}
        "ApplicationExcludeApplications" = if ($pol.Conditions.ApplicationExcludeApplications) {($pol.Conditions.ApplicationExcludeApplications | ForEach-Object {Report-DirectoryApps -AppID $_}) -join ","} else {"Not Configured"}
        "ApplicationIncludeUserActions" = if ($pol.Conditions.ApplicationIncludeUserActions) {$pol.Conditions.ApplicationIncludeUserActions -join ","} else {"Not Configured"}
        "LocationIncludeLocations"  = if ($pol.Conditions.LocationIncludeLocations) {($pol.Conditions.LocationIncludeLocations | ForEach-Object {Report-NamedLocations -ID $_}) -join ","} else {"Not Configured"}
        "LocationExcludeLocations"  = if ($pol.Conditions.LocationExcludeLocations) {($pol.Conditions.LocationExcludeLocations | ForEach-Object {Report-NamedLocations -ID $_}) -join ","} else {"Not Configured"}
        "GrantControlBuiltInControls" = if ($pol.GrantControlBuiltInControls) {$pol.GrantControlBuiltInControls -join ","} else {"Not Configured"}
        "GrantControlTermsOfUse"  = if ($pol.GrantControlTermsOfUse) {$pol.GrantControlTermsOfUse -join "," } else {"Not Configured"}
        "GrantControlOperator"  = if ($pol.GrantControlOperator) {$pol.GrantControlOperator} else {"Not Configured"}
        "GrantControlCustomAuthenticationFactors" = if ($pol.GrantControlCustomAuthenticationFactors) {$pol.GrantControlCustomAuthenticationFactors -join "," } else {"Not Configured"}
        "CloudAppSecurityCloudAppSecurityType" = if ($pol.CloudAppSecurityCloudAppSecurityType) {$pol.CloudAppSecurityCloudAppSecurityType} else {"Not Configured"}
        "CloudAppSecurityIsEnabled" = if ($pol.CloudAppSecurityIsEnabled) {$pol.CloudAppSecurityIsEnabled} else {"Not Configured"}
        "PersistentBrowserIsEnabled"  = if ($pol.PersistentBrowserIsEnabled) {$pol.PersistentBrowserIsEnabled} else {"Not Configured"}
        "PersistentBrowserMode" = if ($pol.PersistentBrowserMode) {$pol.PersistentBrowserMode} else {"Not Configured"}
        "SignInFrequencyIsEnabled"  = if ($pol.SignInFrequencyIsEnabled) {$pol.SignInFrequencyIsEnabled} else {"Not Configured"}
        "SignInFrequencyType" = if ($pol.SignInFrequencyType) {$pol.SignInFrequencyType} else {"Not Configured"}
        "SignInFrequencyValue"  = if ($pol.SignInFrequencyValue) {$pol.SignInFrequencyValue} else {"Not Configured"}
        }
    }
}
  
end {

    Write-host "Creating the Reports." -ForegroundColor Green
    $ReportData = $Report | Select-Object -Property Displayname,Description,State,ID,createdDateTime,ModifiedDateTime,UserIncludeUsers,UserExcludeUsers,UserIncludeGroups,UserExcludeGroups,UserIncludeRoles,UserExcludeRoles,ConditionSignInRiskLevels,ConditionClientAppTypes,PlatformIncludePlatforms,PlatformExcludePlatforms,DeviceStateIncludeStates,DeviceStateExcludeStates,ApplicationIncludeApplications,ApplicationExcludeApplications,ApplicationIncludeUserActions,LocationIncludeLocations,LocationExcludeLocations,GrantControlBuiltInControls,GrantControlTermsOfUse,GrantControlOperator,GrantControlCustomAuthenticationFactors,CloudAppSecurityCloudAppSecurityType,CloudAppSecurityIsEnabled,PersistentBrowserIsEnabled,PersistentBrowserMode,SignInFrequencyIsEnabled,SignInFrequencyType,SignInFrequencyValue | Sort-Object -Property Displayname
    Write-Host "" 
    switch ($Export) {
        "All" { 
            Write-host "Generating the HTML Report." -ForegroundColor Green
            $ReportData | ConvertTo-HTML -head $Head -Body "<font color=`"Black`"><h1><center>Conditional Access Policies Report - $Date</center></h1></font>" | Out-File "$Filename.html"
            
            Write-host "Generating the CSV Report." -ForegroundColor Green
            $ReportData | Export-Csv "$Filename.csv" -NoTypeInformation 
        }
        "CSV" {
            Write-host "Generating the CSV Report." -ForegroundColor Green
            $ReportData | Export-Csv "$Filename.csv" -NoTypeInformation
        }
        "HTML" {
            Write-host "Generating the HTML Report." -ForegroundColor Green
            $ReportData | ConvertTo-HTML -head $Head -Body "<font color=`"Black`"><h1><center>Conditional Access Policies Report - $Date</center></h1></font>" | Out-File "$Filename.html"
        }
    }
    Write-Host ""
    write-host "Disconnecting from Microsoft Graph" -ForegroundColor Green

    Disconnect-Graph
}
