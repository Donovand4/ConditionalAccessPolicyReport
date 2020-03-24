# ConditionalAccessPolicyReport
PowerShell Script used to create a report for Azure AD Conditional Access Policies.

# DESCRIPTION
    The script will generate a report for all the Conditional Access Policies used in the Azure AD Tenant. 
    The report will resolve all ID's used within the policies for users, groups, named locations and applications.
# EXAMPLE
    Generates a report in the CSV and HTML format
    PS C:\> Generate-ConditionalAccessReport.ps1 -export All

    Generates a report in the CSV format
    PS C:\> Generate-ConditionalAccessReport.ps1 -export CSV

    Generates a report in the HTML format
    PS C:\> Generate-ConditionalAccessReport.ps1 -export HTML
# OUTPUTS
    Exports .html and .csv files that contains the Conditional Access policies.
# NOTES
    The script will connect to the Microsoft Graph service and collect the required information. 
# LINK
    Github - https://github.com/microsoftgraph/msgraph-sdk-powershell
