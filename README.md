# ConditionalAccessPolicyReport
    PowerShell Script used to create a report for Azure AD Conditional Access Policies.

# Note
    Be aware that the modules used in the script are making use of APIs that are in preview status and are subject to change, and may break existing scenarios without notice. Don't take a production dependency on APIs in the beta endpoint.

# TO DO:
    The script is being reviewed and may be rewritten to make use of the Graph API's directly.

# Description
    The script will generate a report for all the Conditional Access Policies used in the Azure AD Tenant. 
    The report will resolve all ID's used within the policies for users, groups, named locations and applications.
# Getting Started
    Below is a list of steps recommended to allow the report to authenticate and retrieve the information required.
    Steps:
    1.  Download and install the Microsoft Graph PowerShell module by launching a PowerShell Console as Administrator 
        and execute the below command:        
            Install-Module Microsoft.Graph -AllowClobber -Force
            Install-Module -Name Microsoft.Graph.Identity.RoleManagement
            
    2.  Launch a PowerShell Console
    3.  Run the below to authenticate to the Microsoft Graph PowerShell (Preview) Application that is added to Azure AD.
            Connect-Graph -Scopes "Policy.Read.All","Directory.Read.All"
            
    4.  Complete the authentication by following the device login prompts.
    5.  Review and accept the required permissions.
    6.  The report can be executed as soon as the permissions are granted on the application.
    
# Example
    Generates a report in the CSV and HTML format
    PS C:\> Generate-ConditionalAccessReport.ps1 -export All

    Generates a report in the CSV format
    PS C:\> Generate-ConditionalAccessReport.ps1 -export CSV

    Generates a report in the HTML format
    PS C:\> Generate-ConditionalAccessReport.ps1 -export HTML
# Outputs
    Exports .html and .csv files that contains the Conditional Access policies.
# Notes
    The script will connect to the Microsoft Graph service and collect the required information. 
# Link
    Github - https://github.com/microsoftgraph/msgraph-sdk-powershell
