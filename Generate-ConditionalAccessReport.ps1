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
#   Version 1.6         Date Last Modified: 25 June 2025                #  
#                                                                           #  
#############################################################################  
.SYNOPSIS
    PowerShell Script used to generate Conditional Access Policies report with named locations.
    Created by: Donovan du Val
    Creation Date: 13 May 2020
    Date Last Modified: 25 June 2025
.DESCRIPTION
    The script will generate a report for all the Conditional Access Policies and Named Locations used in the Entra ID Tenant.
.EXAMPLE
    Generates reports in the CSV and HTML format
    PS C:\> Generate-ConditionalAccessReport.ps1 -OutputFormat All -TenantID <TenantID>
.EXAMPLE
    Generates reports in the CSV format
    PS C:\> Generate-ConditionalAccessReport.ps1 -OutputFormat CSV
.EXAMPLE
    Generates a report in the HTML format
    PS C:\> Generate-ConditionalAccessReport.ps1 -OutputFormat HTML
.EXAMPLE
    Generates a report in the All formats using AppID and CertificateThumbprint
    PS C:\> Generate-ConditionalAccessReport.ps1 -OutputFormat All -TenantID <TenantID> -AppID <AppID> -CertificateThumbprint <CertificateThumbprint>
.INPUTS
   No inputs
.OUTPUTS
    Exports .html and .csv files that contains the Conditional Access policies and Named Locations
.NOTES
    The script will connect to the Microsoft Graph service and collect the required information. 
    To install the latest modules:
    Install-Module Microsoft.Graph -AllowClobber -Force

    If PowerShell logs an error message for MaximumFunctionCount or MaximumVariableCount. This can be increased using the below.
    
    $MaximumFunctionCount = 8192 
    $MaximumVariableCount = 8192

    Updates:
    	25 Apr 2023: Added improved filtering to HTML report, updated module versions.
    	21 Jun 2023: Updated module version, 
                  improved module imports to reduce run time, 
                  added All parameter for collecting policies,
                  default to beta profile for collecting policies. 
    	16 Nov 2023: Updated module version, 
                  added named locations report
    	12 March 2024: Updated module version,
                    Added directory roles,
                    resolved some filtering issues for platforms.
    	28 November 2024: Added namded locations to the HTML form,
    			Updated the HTML table format.
	11 February 2025: Added a LookupError filter for users and groups that are referenced but cannot be found in the tenant.
 			Added functionality to the tables to freeze the column headers when scrolling down.
      28 February 2025: Added a user and insider risk conditions.
      11 April 2025: Added certificate authentication support for the script.
      2 May 2025: Split out the CSS and HTML body into separate files to reduce the length of the script. 
      Both the Htmlbody are required for the HTML report to work. These files must be in the same directory as the script.
	  25 June 2025: Updated the script to test for the HTML report requirements before generating the report for HTML reports.
 		

.LINK
    Github 
    https://github.com/microsoftgraph/msgraph-sdk-powershell 
    Microsoft Graph PowerShell Module
    https://www.powershellgallery.com/packages/Microsoft.Graph
#>
[CmdletBinding()]
param (
[Parameter(Mandatory = $true, Position = 0)] [ValidateSet('All', 'CSV', 'HTML')] $OutputFormat,
    [Parameter(Mandatory = $False, Position = 1)] [String] $TenantID,
    [Parameter(Mandatory = $False, Position = 2)] [string] $AppID,
    [Parameter(Mandatory = $False, Position = 3)] [string] $CertificateThumbprint
)
#Requires -Version 5.1
#Requires -Modules @{ ModuleName = "Microsoft.Graph.Authentication"; ModuleVersion = "2.25.0" }
#Requires -Modules @{ ModuleName = "Microsoft.Graph.Identity.SignIns"; ModuleVersion = "2.25.0" }
#Requires -Modules @{ ModuleName = "Microsoft.Graph.Applications"; ModuleVersion = "2.25.0" }
#Requires -Modules @{ ModuleName = "Microsoft.Graph.Users"; ModuleVersion = "2.25.0" }
#Requires -Modules @{ ModuleName = "Microsoft.Graph.Groups"; ModuleVersion = "2.25.0" }
#Requires -Modules @{ ModuleName = "Microsoft.Graph.Identity.DirectoryManagement"; ModuleVersion = "2.25.0" }
Begin {
    Clear-Host
    Write-Host 'Importing the modules...'

    Write-Host 'Logging into Microsoft Graph' -ForegroundColor Green

    # Validate parameter dependencies
    $usingCertAuth = $AppID -or $CertificateThumbprint

    if ($usingCertAuth) {
        if (-not ($AppID -and $CertificateThumbprint -and $TenantID)) {
            Write-Host 'When using AppID and CertificateThumbprint, you must also provide TenantID. All three parameters are required together. Exiting.......' -ForegroundColor Red
            Start-Sleep -Seconds 2
            Exit
        }
    }

    if ($TenantID.Length -eq 0) {
	try {
		Write-Host "Trying to connect without tenant ID"
		Connect-MgGraph -Scopes 'Policy.Read.All', 'Directory.Read.All' -NoWelcome
	}
	catch {
		Write-Host 'Login Failed. Exiting.......' -ForegroundColor Red
		Start-Sleep -Seconds 2
		Exit
	}
	} elseif ($TenantID -and !$usingCertAuth) {
		try {
			Write-Host "Trying to connect to tenant: $TenantID"
			Connect-MgGraph -Scopes 'Policy.Read.All', 'Directory.Read.All' -TenantId $TenantID -NoWelcome
		}
		catch {
			Write-Host 'Login Failed. Exiting.......' -ForegroundColor Red
			Start-Sleep -Seconds 2
			Exit
		}
	} elseif ($TenantID -and $usingCertAuth) {
		try {
			Write-Host "Connecting to Microsoft Graph using App Registration..." -ForegroundColor Green
		
			# Normalize thumbprint (remove spaces, make uppercase for comparison)
			$CertificateThumbprint = $CertificateThumbprint -replace '\s', '' | ForEach-Object { $_.ToUpper() }

			# Try to find the cert in CurrentUser store
			$cert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Thumbprint -eq $CertificateThumbprint }

			if(!$cert){ 
				$cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $CertificateThumbprint } 
			}

			if (-not $cert) {
				Write-Host "Certificate with the given thumbprint not found in Current User or Local machine store" -ForegroundColor Red
				Start-Sleep -Seconds 2
				Exit
			} else {
				Write-Host "Certificate found. Continuing...`n" -ForegroundColor Green
				Connect-MgGraph -ClientId $AppID -CertificateThumbprint $CertificateThumbprint -TenantId $TenantID -NoWelcome
			}
		}
		catch {
			Write-Host 'Login Failed. Exiting.......' -ForegroundColor Red
			Start-Sleep -Seconds 2
			Exit
		}
	}
    
    Write-Host 'Successfully Logged into Microsoft Graph' -ForegroundColor Green
    $Date = Get-Date -Format dd-MMMM-yyyy
    $Filename = "ConditionalAccessReport - $($Date)"
    $NamedLocationsFileName = "NamedLocations - $($Date)"
    
    function Report-DirectoryApps {
        param (
            [Parameter(Mandatory = $true)]
            [String[]]
            $AppID
        )
        switch ($AppID) 
        {
            'All' { 'All' }
            'Office365' {'Office365'}
            Default { 
              $appName = ($servicePrincipals | Where-Object { $_.AppID -eq $AppID }).DisplayName 
              if ($appName) 
              {
                $appName
              } 
              else 
              {
                "LookUpError-$($AppID)"
              }
            }
        }
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
	          'AllTrusted' {'AllTrusted'}
            Default {
            ($namedLocations | Where-Object { $_.ID -eq $ID }).displayName
            }
        }
    }

    function Get-TypeOfNamedLocations {
        param (
            [Parameter(Mandatory = $true)]
            [String[]]
            $TypeString
        )
        switch ($TypeString) {
            '#microsoft.graph.ipNamedLocation' { 'ipNamedLocation' }
            '#microsoft.graph.countryNamedLocation' { 'countryNamedLocation' }
            Default {
            "UnknownType"
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
                    "LookUpError-$($ID)"
                }
            }
        }
    }

    function Report-DirectoryRole {
      param (
              [Parameter(Mandatory = $true)]
              [String[]]
              $ID
          )
          $RoleTemplate = ($DirectoryRoleTemplates | Where-Object { $_.Id -eq "$($ID)" }).DisplayName
          if ($RoleTemplate) 
          {
            $RoleTemplate
          } 
          else 
          {
            "LookUpError-$($ID)"
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
                    "LookUpError-$($ID)"
                }
            }
        }
    }

	function Test-HTMLRequirements{
		Write-host "Testing for HTML required files..." -ForegroundColor Green

		$ExternalStyle = get-content -path ".\Style.css" -Raw -ErrorAction SilentlyContinue ## Load the CSS file for formatting the HTML report
		$StyleSheet = ("<style>`n") + $ExternalStyle + ("`n</style>")
		$PageHeader = "<h1><center>Conditional Access Policies Report - $($date)</center></h1>"
		$htmlBodyfile = get-content -Path ".\Htmlbody.txt" -Raw -ErrorAction SilentlyContinue ##Body format with filter scripts

		if (-not $htmlBodyfile) {
			Write-Host 'HTML body file not found. Exiting.......' -ForegroundColor Red
			Start-Sleep -Seconds 2
			Exit
		}

		if (-not $ExternalStyle) {
			Write-Host 'CSS file not found. Exiting.......' -ForegroundColor Red
			Start-Sleep -Seconds 2
			Exit
		}
	}
}

process {
    Write-Host ''
    Write-Host 'Collecting Named Locations...' -ForegroundColor Green
    $namedLocations = Get-MgIdentityConditionalAccessNamedLocation | select-object displayname,id,`
    @{ name ="Type"; expression ={($_.AdditionalProperties.'@odata.type' | ForEach-Object {Get-TypeOfNamedLocations -TypeString $_ })}},`
    @{ name ="isTrusted"; expression ={$_.additionalproperties.isTrusted}},`
    @{ name ="ipRanges"; expression ={$_.additionalproperties.ipRanges.cidrAddress -join ","}},`
    @{ name ="Country";express={$_.additionalproperties.countriesAndRegions -join ","}},`
    @{ name ="includeUnknownCountriesAndRegions"; expression ={$_.additionalproperties.includeUnknownCountriesAndRegions}},`
    @{ name ="countryLookupMethod"; expression ={$_.additionalproperties.countryLookupMethod}}
    
    Write-Host 'Collecting Service Principals...' -ForegroundColor Green
    $servicePrincipals = Get-MgServicePrincipal -All | Select-Object DisplayName, AppId
    Write-Host ''
    Write-Host "Collecting Directory Role Templates..." -ForegroundColor Green
    $DirectoryRoleTemplates = Get-MgDirectoryRoleTemplate | select-object DisplayName,Id
    write-host ""
    $Report = @()
    #Collects the conditional access policies using the mgconditionalaccesspolicy command.
    foreach ($pol in (Get-MgIdentityConditionalAccessPolicy -All)) {
        $Report += New-Object PSobject -Property @{
            'Displayname'                             = $pol.displayName
            'Description'                             = $pol.Description
            'State'                                   = $pol.state
            'ID'                                      = $pol.id
            'createdDateTime'                         = if ($pol.createdDateTime) { $pol.createdDateTime } else { 'Null' }
            'ModifiedDateTime'                        = if ($pol.ModifiedDateTime) { $pol.ModifiedDateTime } else { 'Null' }
            'UserIncludeUsers'                        = if ($pol.Conditions.Users.IncludeUsers) { ($pol.Conditions.Users.IncludeUsers | ForEach-Object { (Report-Users -ID $_ ) }) -join ',' } else { 'Not Configured' }
            'DirectoryRolesInclude'                   = if ($pol.Conditions.Users.IncludeRoles) { ($pol.Conditions.Users.IncludeRoles | ForEach-Object { (Report-DirectoryRole -ID $_ ) }) -join ',' } else { 'Not Configured' }
            'UserExcludeUsers'                        = if ($pol.Conditions.Users.ExcludeUsers) { ($pol.Conditions.Users.ExcludeUsers | ForEach-Object { (Report-Users -ID $_ ) }) -join ',' } else { 'Not Configured' } 
            'DirectoryRolesExclude'                   = if ($pol.Conditions.Users.ExcludeRoles) { ($pol.Conditions.Users.ExcludeRoles | ForEach-Object { (Report-DirectoryRole -ID $_ ) }) -join ',' } else { 'Not Configured' }
            'UserIncludeGroups'                       = if ($pol.Conditions.Users.IncludeGroups) { ($pol.Conditions.Users.IncludeGroups | ForEach-Object { (Report-Groups -ID $_ ) }) -join ',' } else { 'Not Configured' }
            'UserExcludeGroups'                       = if ($pol.Conditions.Users.ExcludeGroups) { ($pol.Conditions.Users.ExcludeGroups | ForEach-Object { (Report-Groups -ID $_ ) }) -join ',' } else { 'Not Configured' }
            'ConditionUserRiskLevels'                 = if ($pol.Conditions.UserRiskLevels) { $pol.Conditions.UserRiskLevels -join ',' } else { 'Not Configured' }
            'ConditionSignInRiskLevels'               = if ($pol.Conditions.SignInRiskLevels) { $pol.Conditions.SignInRiskLevels -join ',' } else { 'Not Configured' }
            'ConditionInsiderRiskLevels'              = if ($pol.Conditions.InsiderRiskLevels) { $pol.Conditions.InsiderRiskLevels -join ',' } else { 'Not Configured' }
            'ConditionClientAppTypes'                 = if ($pol.Conditions.ClientAppTypes) { $pol.Conditions.ClientAppTypes -join ',' } else { 'Not Configured' }
            'PlatformIncludePlatforms'                = if ($pol.conditions.platforms.IncludePlatforms) { $pol.conditions.platforms.IncludePlatforms -join ',' } else { 'Not Configured' }
            'PlatformExcludePlatforms'                = if ($pol.conditions.platforms.ExcludePlatforms) { $pol.conditions.platforms.ExcludePlatforms -join ',' } else { 'Not Configured' }
            'DevicesFilterStatesMode'                 = if ($pol.Conditions.Devices.DeviceFilter.Mode) {$pol.Conditions.Devices.DeviceFilter.Mode } else { 'Not Configured' } 
            'DevicesFilterStatesRule'                 = if ($pol.Conditions.Devices.DeviceFilter.Rule) {$pol.Conditions.Devices.DeviceFilter.Rule } else { 'Not Configured' }
            'ApplicationIncludeApplications'          = if ($pol.Conditions.Applications.IncludeApplications) { ($pol.Conditions.Applications.IncludeApplications | ForEach-Object { Report-DirectoryApps -AppID $_ }) -join ',' } else { 'Not Configured' }
            'ApplicationExcludeApplications'          = if ($pol.Conditions.Applications.ExcludeApplications) { ($pol.Conditions.Applications.ExcludeApplications | ForEach-Object { Report-DirectoryApps -AppID $_ }) -join ',' } else { 'Not Configured' }
            'ApplicationIncludeUserActions'           = if ($pol.Conditions.Applications.IncludeUserActions) { $pol.Conditions.Applications.IncludeUserActions -join ',' } else { 'Not Configured' }
            'LocationIncludeLocations'                = if ($pol.Conditions.Locations.IncludeLocations) { ($pol.Conditions.Locations.IncludeLocations | ForEach-Object { Report-NamedLocations -ID $_ }) -join ',' } else { 'Not Configured' }
            'LocationExcludeLocations'                = if ($pol.Conditions.Locations.ExcludeLocations) { ($pol.Conditions.Locations.ExcludeLocations | ForEach-Object { Report-NamedLocations -ID $_ }) -join ',' } else { 'Not Configured' }
            'GrantControlBuiltInControls'             = if ($pol.GrantControls.BuiltInControls) { $pol.GrantControls.BuiltInControls -join ',' } else { 'Not Configured' }
            'GrantControlTermsOfUse'                  = if ($pol.GrantControls.TermsOfUse) { $pol.GrantControls.TermsOfUse -join ',' } else { 'Not Configured' }
            'GrantControlOperator'                    = if ($pol.GrantControls.Operator) { $pol.GrantControls.Operator } else { 'Not Configured' }
            'GrantControlCustomAuthFactors'           = if ($pol.GrantControls.CustomAuthenticationFactors) { $pol.GrantControls.CustomAuthenticationFactors -join ',' } else { 'Not Configured' }
            'CloudAppSecurityType'                    = if ($pol.SessionControls.CloudAppSecurity.CloudAppSecurityType) { $pol.SessionControls.CloudAppSecurity.CloudAppSecurityType } else { 'Not Configured' }
            'AppEnforcedRestrictions'                 = if ($pol.SessionControls.ApplicationEnforcedRestrictions.IsEnabled) { $pol.SessionControls.ApplicationEnforcedRestrictions.IsEnabled } else { 'Not Configured' }
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
    $ReportData = $Report | Select-Object -Property Displayname,Description,State,ID,createdDateTime,ModifiedDateTime,`
    UserIncludeUsers,UserExcludeUsers,DirectoryRolesInclude,DirectoryRolesExclude,UserIncludeGroups,UserExcludeGroups,`
    ConditionUserRiskLevels,ConditionSignInRiskLevels,ConditionInsiderRiskLevels,ConditionClientAppTypes, PlatformIncludePlatforms, PlatformExcludePlatforms, DevicesFilterStatesMode,`
    DevicesFilterStatesRule,ApplicationIncludeApplications,ApplicationExcludeApplications,ApplicationIncludeUserActions,`
    LocationIncludeLocations,LocationExcludeLocations,GrantControlBuiltInControls,GrantControlTermsOfUse,GrantControlOperator,`
    GrantControlCustomAuthFactors,AppEnforcedRestrictions,CloudAppSecurityType,`
    CloudAppSecurityIsEnabled,PersistentBrowserIsEnabled,PersistentBrowserMode,SignInFrequencyIsEnabled,`
    SignInFrequencyType,SignInFrequencyValue | Sort-Object -Property Displayname

    Write-Host '' 
    switch ($OutputFormat) {
        'All' {
			Test-HTMLRequirements

            Write-Host "Generating the HTML Report. $($Filename.html)" -ForegroundColor Green
            $CAreportDataHTML = $ReportData | ConvertTo-Html -As Table -PreContent "<h1>Conditional Access Policies</h1>" -PostContent "<br>"
            $CAreportDataHTML = ($CAreportDataHTML.Replace("<table>", "<table id=`"myCATable`">"))
            $CAreportDataHTML = ($CAreportDataHTML.Replace("<title>HTML TABLE</title>", ""))
            $NamedLocationsReportDataHTML = $namedLocations | ConvertTo-Html -As Table -PreContent "<h1>Named Locations</h1>" -PostContent "<br>"
            $NamedLocationsReportDataHTML = ($NamedLocationsReportDataHTML.Replace("<table>", "<table id=`"myNLTable`">"))
            $NamedLocationsReportDataHTML = ($NamedLocationsReportDataHTML.Replace("<td>", "<td class=`"table-CellNL`">"))
            $NamedLocationsReportDataHTML = ($NamedLocationsReportDataHTML.Replace("<title>HTML TABLE</title>", ""))
            $report = ConvertTo-Html -Head $StyleSheet -Title "Conditional Access Policies Report" -Body "$PageHeader $htmlBodyfile $CAreportDataHTML $NamedLocationsReportDataHTML" -PostContent "<p>Creation Date: $($Date)</p>"
            $report | Out-File "$Filename.html"
            
            Write-Host "Generating the CSV Reports. $($Filename.csv)" -ForegroundColor Green
            $ReportData | Export-Csv "$Filename.csv" -NoTypeInformation -Delimiter ";"
            $namedLocations | Export-Csv "$NamedLocationsFileName.csv" -NoTypeInformation -Delimiter ";"
        }
        'CSV' {
            Write-Host "Generating the CSV Reports. $($Filename.csv)" -ForegroundColor Green
            $ReportData | Export-Csv "$Filename.csv" -NoTypeInformation -Delimiter ";"
        }
        'HTML' {
			Test-HTMLRequirements

            Write-Host "Generating the HTML Report. $($Filename.html)" -ForegroundColor Green
            $CAreportDataHTML = $ReportData | ConvertTo-Html -As Table -PreContent "<h1>Conditional Access Policies</h1>" -PostContent "<br>"
            $CAreportDataHTML = ($CAreportDataHTML.Replace("<table>", "<table id=`"myCATable`">"))
            $CAreportDataHTML = ($CAreportDataHTML.Replace("<title>HTML TABLE</title>", ""))
            $NamedLocationsReportDataHTML = $namedLocations | ConvertTo-Html -As Table -PreContent "<h1>Named Locations</h1>" -PostContent "<br>"
            $NamedLocationsReportDataHTML = ($NamedLocationsReportDataHTML.Replace("<table>", "<table id=`"myNLTable`">"))
            $NamedLocationsReportDataHTML = ($NamedLocationsReportDataHTML.Replace("<td>", "<td class=`"table-CellNL`">"))
            $NamedLocationsReportDataHTML = ($NamedLocationsReportDataHTML.Replace("<title>HTML TABLE</title>", ""))
            $report = ConvertTo-Html -Head $StyleSheet -Title "Conditional Access Policies Report" -Body "$PageHeader $htmlBodyfile $CAreportDataHTML $NamedLocationsReportDataHTML" -PostContent "<p>Creation Date: $($Date)</p>"
            $report | Out-File "$Filename.html"
        }
    }
    Write-Host ''
    Write-Host 'Disconnecting from Microsoft Graph' -ForegroundColor Green

    Disconnect-MgGraph
}