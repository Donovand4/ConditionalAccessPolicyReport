# ConditionalAccessPolicyReport
    PowerShell Script used to create a report for Entra ID Conditional Access Policies.

# Note
    The modules used in the script may still be in development and may change during the development cycle.

# TO DO:
    Open to suggestions.

# Updates:
	25 Apr 2023: 
                Added improved filtering to HTML report, updated module versions.
	21 Jun 2023: 
                Updated module version.
                Improved module imports to reduce run time. 
                Added All parameter for collecting policies. 
                Default to beta profile for collecting policies. 
	16 Nov 2023: 
                Updated module version.
                Added named locations report.
	12 March 2024: 
                Updated module version.
                Added directory roles.
                Aesolved some filtering issues for platforms.
	28 November 2024: 
                Added namded locations to the HTML form.
                Updated the HTML table format.
    11 February 2025:
                Added a LookupError filter for users and groups that are referenced but cannot be found in the tenant.
                Added functionality to the tables to freeze the column headers when scrolling down.
    28 February 2025:
                Added the missing User Risk Condition.
                Add the new Insider Risk Condition.
    11 April 2025:
                Added certificate authentication.

# Description
    The script will generate a report for all the Conditional Access Policies and Named Locations used in the Entra ID Tenant.
    The report will resolve all ID's used within the policies for users, groups, named locations and applications.
# Getting Started
    Below is a list of steps recommended to allow the report to authenticate and retrieve the information required.
    Steps:
    1.  Download and install the Microsoft Graph PowerShell module by launching a PowerShell Console as Administrator 
        and execute the below command:        
            Install-Module Microsoft.Graph -AllowClobber -Force
            
    2.  Launch a PowerShell Console
    3.  Run the below to authenticate to the Microsoft Graph PowerShell (Preview) Application that is added to Azure AD.
            Connect-MgGraph -Scopes 'Policy.Read.All', 'Directory.Read.All'
            
    4.  Complete the authentication by following the device login prompts.
    5.  Review and accept the required permissions.
    6.  The report can be executed as soon as the permissions are granted on the application.
    
    Optional: Certificate authentication requires that permissions 'Policy.Read.All', 'Directory.Read.All' are added to the application before authenticating. 
    
# Example
    Generates a report in the CSV and HTML format in the same location where the script is located.
    PS C:\> Generate-ConditionalAccessReport.ps1 -OutputFormat All -TenantID <TenantID>

    Generates a report in the CSV format in the same location where the script is located.
    PS C:\> Generate-ConditionalAccessReport.ps1 -OutputFormat CSV

    Generates a report in the HTML format in the same location where the script is located.
    PS C:\> Generate-ConditionalAccessReport.ps1 -OutputFormat HTML
    
    Generates a report in the All formats using AppID and CertificateThumbprint
    PS C:\> Generate-ConditionalAccessReport.ps1 -OutputFormat All -TenantID <TenantID> -AppID <AppID> -CertificateThumbprint <CertificateThumbprint>

# Outputs
    Exports .html and .csv files that contains the Conditional Access policies and Named Locations
# Notes
    The script will connect to the Microsoft Graph service and collect the required information.     
    If PowerShell logs an error message for MaximumFunctionCount or MaximumVariableCount. This can be increased using the below.    
    $MaximumFunctionCount = 8192 
    $MaximumVariableCount = 8192
    
# Link
    Github - https://github.com/microsoftgraph/msgraph-sdk-powershell
