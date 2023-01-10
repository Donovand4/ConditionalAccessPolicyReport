# ConditionalAccessPolicyReport
    PowerShell Script used to create a report for Azure AD Conditional Access Policies.

# Note
    The modules used in the script may still be in development and may change during the development cycle.

# TO DO:
    Review improvements for report format and possibly doc export.

# Description
    The script will generate a report for all the Conditional Access Policies used in the Azure AD Tenant. 
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
    
# Example
    Generates a report in the CSV and HTML format in the same location where the script is located.
    PS C:\> Generate-ConditionalAccessReport.ps1 -export All

    Generates a report in the CSV format in the same location where the script is located.
    PS C:\> Generate-ConditionalAccessReport.ps1 -export CSV

    Generates a report in the HTML format in the same location where the script is located.
    PS C:\> Generate-ConditionalAccessReport.ps1 -export HTML
# Outputs
    Exports .html and .csv files that contains the Conditional Access policies.
# Notes
    The script will connect to the Microsoft Graph service and collect the required information. 
    If there are any missing policies, then rerun the script using the Beta profile parameter and compare the output.
    
    If PowerShell logs an error message for MaximumFunctionCount or MaximumVariableCount. This can be increased using the below.    
    $MaximumFunctionCount = 8192 
    $MaximumVariableCount = 8192
    
# Link
    Github - https://github.com/microsoftgraph/msgraph-sdk-powershell
