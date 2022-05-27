# Summary
A script to add AD users to AD groups, based on given memberships.  

See also: https://github.com/engrit-illinois/Remove-AdGroupMemberships  

# Behavior
- Accepts a CSV file with one row for each user-in-group membership which should be added. See documentation of `-InputCsv` parameter.
- Validates that all given AD objects exist and that given memberships do not already exist.
- Performs the membership additionals.
- Outputs results to the screen, and optionally to a PowerShell object, and/or a new CSV.

# Requirements
- Requires RSAT to be installed.
- Must be run as a user account with write access to the relevant AD groups.

# Usage
1. Download `Add-AdGroupMemberships.psm1` to `$HOME\Documents\WindowsPowerShell\Modules\Add-AdGroupMemberships\Ad-AdGroupMemberships.psm1`.
    - The above path is for PowerShell v5.1. For later versions, replace `WindowsPowerShell` with `PowerShell`.
2. Run it using the examples and documentation provided below, including the `-TestRun` switch.
3. Review the output to confirm that the changes match your expectations.
4. Run it again without the `-TestRun` switch.

# Examples

### Common usage
```powershell
Add-AdGroupMemberships -TestRun -InputCsv "c:\input.csv" -OutputCsv "c:\output.csv"
```

### Also capture the output in a variable for inspection
```powershell
$result = Add-AdGroupMemberships -TestRun -InputCsv "c:\input.csv" -OutputCsv "c:\output.csv" -PassThru
```

# Parameters

### -TestRun
Optional switch.  
If specified, the script will skip the step where it actually modifies AD groups. Everything else (i.e. the data gathering, munging, logging, and output) will happen as normal.  

### -InputCsv \<string\>
Required string.  
The full path to a properly-formatted CSV file.  
Formatting requirements:  
  - Columns named `User` and `Group` are required (by default). Input column names can be customized using the `-InputUserColumn` and `-InputGroupColumn` parameters.
  - Each row represents a single membership of a user in a group.
  - Cells should just contain the regular name of the user or group.
  - Additional columns may be present and will be ignored.
  - Columns may be in any order.

`example-input.csv` shows an example of the minimum requirements.  

### -InputUserColumn \<string\>
Optional string.  
The name of the column in the input CSV which contains the user names of the memberships.  
The same name will be used as the associated column in the output CSV, if `-OutputCsv` is specified.  
Default is `User`.  

### -InputGroupColumn \<string\>
Optional string.  
The name of the column in the input CSV which contains the group names of the memberships.  
The same name will be used as the associated column in the output CSV, if `-OutputCsv` is specified.  
Default is `Group`.  

### -OutputCsv \<string\>
Optional string.  
The full path of a file to export results to, in CSV format.  
If omitted, no output CSV will be generated.  

# Notes
- Developed and tested on PowerShell v7.2. Should work on PowerShell v5.1.
- By mseng3. See my other projects here: https://github.com/mmseng/code-compendium.
