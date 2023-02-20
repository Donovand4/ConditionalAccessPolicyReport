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
#   Version 1.1         Date Last Modified: 20 February 2023                #  
#                                                                           #  
#############################################################################  
.SYNOPSIS
    PowerShell Script used to generate Conditional Access Policies.
    Created by: Donovan du Val
    Creation Date: 13 May 2020
    Last Updated: 20 Feb 2023 - Added filtering to HTML report.
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
.EXAMPLE
    Generates a report in the CSV format using the Graph Beta profile
    PS C:\> Generate-ConditionalAccessReport.ps1 -export CSV -BetaProfile $true
.INPUTS
   No inputs
.OUTPUTS
    Exports .html and .csv files that contains the Conditional Access policies.
.NOTES
    The script will connect to the Microsoft Graph service and collect the required information. 
    To install the latest modules:
    Install-Module Microsoft.Graph -AllowClobber -Force

    If there are any missing policies, then rerun the script using the Beta profile parameter and compare the output.

    If PowerShell logs an error message for MaximumFunctionCount or MaximumVariableCount. This can be increased using the below.
    
    $MaximumFunctionCount = 8192 
    $MaximumVariableCount = 8192

.LINK
    Github 
    https://github.com/microsoftgraph/msgraph-sdk-powershell 
    Microsoft Graph PowerShell Module
    https://www.powershellgallery.com/packages/Microsoft.Graph
#>
[CmdletBinding()]
param (
[Parameter(Mandatory = $true, Position = 0)] [ValidateSet('All', 'CSV', 'HTML')] $OutputFormat,
    [Parameter(Mandatory = $False)] [String] $TenantID,
    [Parameter(Mandatory = $False)] [String] [ValidateSet($true)] $BetaProfile
)
#Requires -Version 5.1
#Requires -Modules @{ ModuleName="Microsoft.Graph"; ModuleVersion="1.16.0" }
Begin {
    Clear-Host
    Write-Host 'Importing the modules...'
    Import-Module Microsoft.Graph.Authentication, Microsoft.Graph.Identity.SignIns, Microsoft.Graph.Applications, Microsoft.Graph.Users, Microsoft.Graph.Groups

    Write-Host 'Logging into Microsoft Graph' -ForegroundColor Green
    if ($TenantID.Length -eq 0) {
        try {
            Write-Host "Trying to connect without tenant ID"
            Connect-MgGraph -Scopes 'Policy.Read.All', 'Directory.Read.All'
        }
        catch {
            Write-Host 'Login Failed. Exiting.......' -ForegroundColor Red
            Start-Sleep -Seconds 2
            Exit
        }
    } else {
        try {
            Write-Host "Trying to connect to tenant: $TenantID"
            Connect-MgGraph -Scopes 'Policy.Read.All', 'Directory.Read.All' -TenantId $TenantID
        }
        catch {
            Write-Host 'Login Failed. Exiting.......' -ForegroundColor Red
            Start-Sleep -Seconds 2
            Exit
        }
    }

    if ($BetaProfile -eq $true)
    {
        Write-Host 'Selecting the Beta profile' -ForegroundColor Green

        Select-MgProfile -Name Beta
    }
    
    Write-Host 'Successfully Logged into Microsoft Graph' -ForegroundColor Green
    $Date = Get-Date -Format dd-MMMM-yyyy
    $Filename = "ConditionalAccessReport - $($Date)"

    function Report-DirectoryApps {
        param (
            [Parameter(Mandatory = $true)]
            [String[]]
            $AppID
        )
        ($servicePrincipals | Where-Object { $_.AppID -eq $AppID }).DisplayName
    }
    
    function Report-NamedLocations {
        param (
            [Parameter(Mandatory = $true)]
            [String[]]
            $ID
        )
        switch ($ID) {
            '00000000-0000-0000-0000-000000000000' { 'Unknown Site' }
            'All' { 'All' }
            Default {
            ($namedLocations | Where-Object { $_.ID -eq $ID }).displayName
            }
        }
    }
    
    function Report-Users {
        param (
            [Parameter(Mandatory = $true)]
            [String[]]
            $ID
        )
        switch ($ID) {
            'GuestsOrExternalUsers' { 'GuestsOrExternalUsers' }
            'All' { 'All' }
            Default {
                $user = (Get-MgUser -UserId "$($ID)" -ErrorAction SilentlyContinue).userprincipalname
                if ($user) {
                    $user
                } 
                else {
                    "LookingUpError-$($ID)"
                }
            }
        }
    }
    
    function Report-Groups {
        param (
            [Parameter(Mandatory = $true)]
            [String[]]
            $ID
        )
        switch ($ID) {
            'GuestsOrExternalUsers' { 'GuestsOrExternalUsers' }
            'All' { 'All' }
            Default {
                $group = (Get-MgGroup -GroupId "$($ID)" -ErrorAction silentlycontinue).displayname
                if ($group) {
                    $group
                }
                else {
                    "LookingUpError-$($ID)"
                }
            }
        }
    }   
    $Head = @'
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
    #myDisplayNameFilterID {
    width: 75%;
    font-size: 18px;
    padding: 10px 20px 10px 20px;
    border: 1.5px solid #ddd; 
    margin-bottom: 15px;
</style>
'@

##Body format with filter scripts
$HTMLBody = @"
<font color="Black"><h1><center>Conditional Access Policies Report - $($date)</center></h1></font>
<font color="Black"><h2>Quick Filter:</h2></font>
<div id="myCAQuickFilterContainer">
  <button class="btn active" onclick="myStateFilter('all')"> Clear filters</button>
  <button class="btn" onclick="myStateFilter('Enabled')"> Enabled</button>
  <button class="btn" onclick="myStateFilter('Disabled')"> Disabled</button>
</div>
<font color="Black"><h2>Display Name Filter:</h2></font>
<input type="text" id="myDisplayNameFilterID" onkeyup="myDisplayNameFilter()" placeholder="Search for Display Names..">
<br>
<script>
  function myStateFilter(a)
  {
    // Declare variables
    var input, filter, table, tr, td, i, txtValue;
    filter = a.toUpperCase();
    table = document.getElementById("myCATable");
    tr = table.getElementsByTagName("tr");
    if (a == "all")
    {
        for (i = 0; i < tr.length; i++)
      {
        td = tr[i].getElementsByTagName("td")[2];
        if (td)
        {
          tr[i].style.display = "";
        }
      }
    }
    else{
      // Loop through all table rows, and hide those who don't match the search query
      for (i = 0; i < tr.length; i++)
      {
        td = tr[i].getElementsByTagName("td")[2];
        if (td)
        {
          txtValue = td.textContent || td.innerText;
          if (txtValue.toUpperCase().indexOf(filter) > -1)
          {
            tr[i].style.display = "";
          } else
          {
            tr[i].style.display = "none";
          }
        }
      }
    }
  }

function myDisplayNameFilter()
{
  // Declare variables
  var input, filter, table, tr, td, i, txtValue;
  input = document.getElementById("myDisplayNameFilterID");
  filter = input.value.toUpperCase();
  table = document.getElementById("myCATable");
  tr = table.getElementsByTagName("tr");
  // Loop through all table rows, and hide those who don't match the search query
  for (i = 0; i < tr.length; i++)
  {
    td = tr[i].getElementsByTagName("td")[0];
    if (td)
    {
      txtValue = td.textContent || td.innerText;
      if (txtValue.toUpperCase().indexOf(filter) > -1)
      {
        tr[i].style.display = "";
      } else
      {
        tr[i].style.display = "none";
      }
    }
  }
}
</script>

"@
}

process {
    Write-Host ''
    Write-Host 'Collecting Named Locations...' -ForegroundColor Green
    $namedLocations = Get-MgIdentityConditionalAccessNamedLocation | Select-Object displayname, id

    Write-Host 'Collecting Service Principals...' -ForegroundColor Green
    $servicePrincipals = Get-MgServicePrincipal -All | Select-Object DisplayName, AppId
    Write-Host ''
    $Report = @()
    #Collects the conditional access policies using the mgconditionalaccesspolicy command.
    foreach ($pol in (Get-MgIdentityConditionalAccessPolicy)) {
        $Report += New-Object PSobject -Property @{
            'Displayname'                             = $pol.displayName
            'Description'                             = $pol.Description
            'State'                                   = $pol.state
            'ID'                                      = $pol.id
            'createdDateTime'                         = if ($pol.createdDateTime) { $pol.createdDateTime } else { 'Null' }          
            'ModifiedDateTime'                        = if ($pol.ModifiedDateTime) { $pol.ModifiedDateTime } else { 'Null' }
            'UserIncludeUsers'                        = if ($pol.Conditions.Users.IncludeUsers) { ($pol.Conditions.Users.IncludeUsers | ForEach-Object { (Report-Users -ID $_ ) }) -join ',' } else { 'Not Configured' } 
            'UserExcludeUsers'                        = if ($pol.Conditions.Users.ExcludeUsers) { ($pol.Conditions.Users.ExcludeUsers | ForEach-Object { (Report-Users -ID $_ ) }) -join ',' } else { 'Not Configured' } 
            'UserIncludeGroups'                       = if ($pol.Conditions.Users.IncludeGroups) { ($pol.Conditions.Users.IncludeGroups | ForEach-Object { (Report-Groups -ID $_ ) }) -join ',' } else { 'Not Configured' }
            'UserExcludeGroups'                       = if ($pol.Conditions.Users.ExcludeGroups) { ($pol.Conditions.Users.ExcludeGroups | ForEach-Object { (Report-Groups -ID $_ ) }) -join ',' } else { 'Not Configured' }
            'ConditionSignInRiskLevels'               = if ($pol.Conditions.SignInRiskLevels) { $pol.Conditions.SignInRiskLevels -join ',' } else { 'Not Configured' }
            'ConditionClientAppTypes'                 = if ($pol.Conditions.ClientAppTypes) { $pol.Conditions.ClientAppTypes -join ',' } else { 'Not Configured' }
            'PlatformIncludePlatforms'                = if ($pol.Conditions.Platforms.IncludePlatforms) { $pol.Conditions.Platforms.IncludePlatforms -join ',' } else { 'Not Configured' }
            'PlatformExcludePlatforms'                = if ($pol.Conditions.Platforms.ExcludePlatforms) { $pol.Conditions.Platforms.ExcludePlatforms -join ',' } else { 'Not Configured' }
            'DevicesFilterStatesMode'                 = if ($pol.Conditions.Devices.DeviceFilter.Mode) {$pol.Conditions.Devices.DeviceFilter.Mode -join ","} else {"Failed to Report"} 
            'DevicesFilterStatesRule'                 = if ($pol.Conditions.Devices.DeviceFilter.Rule) {$pol.Conditions.Devices.DeviceFilter.Rule -join ","} else {"Failed to Report"}                       
            'ApplicationIncludeApplications'          = if ($pol.Conditions.Applications.IncludeApplications) { ($pol.Conditions.Applications.IncludeApplications | ForEach-Object { Report-DirectoryApps -AppID $_ }) -join ',' } else { 'Not Configured' }
            'ApplicationExcludeApplications'          = if ($pol.Conditions.Applications.ExcludeApplications) { ($pol.Conditions.Applications.ExcludeApplications | ForEach-Object { Report-DirectoryApps -AppID $_ }) -join ',' } else { 'Not Configured' }
            'ApplicationIncludeUserActions'           = if ($pol.Conditions.Applications.IncludeUserActions) { $pol.Conditions.Applications.IncludeUserActions -join ',' } else { 'Not Configured' }
            'LocationIncludeLocations'                = if ($pol.Conditions.Locations.IncludeLocations) { ($pol.Conditions.Locations.IncludeLocations | ForEach-Object { Report-NamedLocations -ID $_ }) -join ',' } else { 'Not Configured' }
            'LocationExcludeLocations'                = if ($pol.Conditions.Locations.ExcludeLocations) { ($pol.Conditions.Locations.ExcludeLocations | ForEach-Object { Report-NamedLocations -ID $_ }) -join ',' } else { 'Not Configured' }
            'GrantControlBuiltInControls'             = if ($pol.GrantControls.BuiltInControls) { $pol.GrantControls.BuiltInControls -join ',' } else { 'Not Configured' }
            'GrantControlTermsOfUse'                  = if ($pol.GrantControls.TermsOfUse) { $pol.GrantControls.TermsOfUse -join ',' } else { 'Not Configured' }
            'GrantControlOperator'                    = if ($pol.GrantControls.Operator) { $pol.GrantControls.Operator } else { 'Not Configured' }
            'GrantControlCustomAuthenticationFactors' = if ($pol.GrantControls.CustomAuthenticationFactors) { $pol.GrantControls.CustomAuthenticationFactors -join ',' } else { 'Not Configured' }
            'CloudAppSecurityCloudAppSecurityType'    = if ($pol.SessionControls.CloudAppSecurity.CloudAppSecurityType) { $pol.SessionControls.CloudAppSecurity.CloudAppSecurityType } else { 'Not Configured' }
            'ApplicationEnforcedRestrictions'         = if ($pol.SessionControls.ApplicationEnforcedRestrictions.IsEnabled) { $pol.SessionControls.ApplicationEnforcedRestrictions.IsEnabled } else { 'Not Configured' }
            'CloudAppSecurityIsEnabled'               = if ($pol.SessionControls.CloudAppSecurity.IsEnabled) { $pol.SessionControls.CloudAppSecurity.IsEnabled } else { 'Not Configured' }
            'PersistentBrowserIsEnabled'              = if ($pol.SessionControls.PersistentBrowser.IsEnabled) { $pol.SessionControls.PersistentBrowser.IsEnabled } else { 'Not Configured' }
            'PersistentBrowserMode'                   = if ($pol.SessionControls.PersistentBrowser.Mode) { $pol.SessionControls.PersistentBrowser.Mode } else { 'Not Configured' }
            'SignInFrequencyIsEnabled'                = if ($pol.SessionControls.SignInFrequency.IsEnabled) { $pol.SessionControls.SignInFrequency.IsEnabled } else { 'Not Configured' }
            'SignInFrequencyType'                     = if ($pol.SessionControls.SignInFrequency.Type) { $pol.SessionControls.SignInFrequency.Type } else { 'Not Configured' }
            'SignInFrequencyValue'                    = if ($pol.SessionControls.SignInFrequency.Value) { $pol.SessionControls.SignInFrequency.Value } else { 'Not Configured' }
        }
    }
}
  
end {

    Write-Host 'Generating the Reports.' -ForegroundColor Green
    $ReportData = $Report | Select-Object -Property Displayname,Description,State,ID,createdDateTime,ModifiedDateTime,UserIncludeUsers,UserExcludeUsers,UserIncludeGroups,UserExcludeGroups,ConditionSignInRiskLevels,ConditionClientAppTypes,PlatformIncludePlatforms,PlatformExcludePlatforms,DevicesFilterStatesMode,DevicesFilterStatesRule,ApplicationIncludeApplications,ApplicationExcludeApplications,ApplicationIncludeUserActions,LocationIncludeLocations,LocationExcludeLocations,GrantControlBuiltInControls,GrantControlTermsOfUse,GrantControlOperator,GrantControlCustomAuthenticationFactors,ApplicationEnforcedRestrictions,CloudAppSecurityCloudAppSecurityType,CloudAppSecurityIsEnabled,PersistentBrowserIsEnabled,PersistentBrowserMode,SignInFrequencyIsEnabled,SignInFrequencyType,SignInFrequencyValue | Sort-Object -Property Displayname    
    Write-Host '' 
    switch ($OutputFormat) {
        'All' { 
            Write-Host "Generating the HTML Report. $($Filename.html)" -ForegroundColor Green
            $HTMLTableData = $ReportData | ConvertTo-Html -Head $Head -Body $HTMLBody -PostContent "<p>Creation Date: $($Date)</p>"            
            ($HTMLTableData.Replace("<table>", "<table id=`"myCATable`">")) | Out-File "$Filename.html"
            
            Write-Host "Generating the CSV Report. $($Filename.csv)" -ForegroundColor Green
            $ReportData | Export-Csv "$Filename.csv" -NoTypeInformation 
        }
        'CSV' {
            Write-Host "Generating the CSV Report. $($Filename.csv)" -ForegroundColor Green
            $ReportData | Export-Csv "$Filename.csv" -NoTypeInformation
        }
        'HTML' {
            Write-Host "Generating the HTML Report. $($Filename.html)" -ForegroundColor Green
            $HTMLTableData = $ReportData | ConvertTo-Html -Head $Head -Body $HTMLBody -PostContent "<p>Creation Date: $($Date)</p>"            
            ($HTMLTableData.Replace("<table>", "<table id=`"myCATable`">")) | Out-File "$Filename.html"
        }
    }
    Write-Host ''
    Write-Host 'Disconnecting from Microsoft Graph' -ForegroundColor Green

    Disconnect-MgGraph
}
