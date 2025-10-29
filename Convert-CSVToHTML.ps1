<#
.SYNOPSIS
    Converts a CSV file into an HTML table and saves it as a web page.
    Any column that contains URLs is automatically converted into clickable links.

.DESCRIPTION
    This script reads the contents of a CSV file, converts them into an HTML table, 
    and then saves the output as an HTML web page. 
    It detects URLs (strings starting with "http" or "https") and converts them into clickable <a> links.

.PARAMETER InputCSV
    The full path to the CSV file that will be converted.

.PARAMETER OutputHTML
    The full path where the HTML file will be saved.

.EXAMPLE
    .\Convert-CSVToHTML.ps1 -InputCSV "C:\data\sites.csv" -OutputHTML "C:\data\sites.html"

.NOTES
    Author: Tom Fenton
    Created: October 2025
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$InputCSV,

    [Parameter(Mandatory = $true)]
    [string]$OutputHTML
)

# --- Step 1: Import the CSV file into a PowerShell object
$csvData = Import-Csv -Path $InputCSV

# --- Step 2: Begin building the HTML structure
$htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>CSV to HTML Table</title>
<style>
    body { font-family: Arial, sans-serif; background-color: #f8f9fa; margin: 40px; }
    table { border-collapse: collapse; width: 100%; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #007bff; color: white; }
    tr:nth-child(even) { background-color: #f2f2f2; }
    a { color: #007bff; text-decoration: none; }
    a:hover { text-decoration: underline; }
</style>
</head>
<body>
<h2>CSV Data Table</h2>
<table>
"@

# --- Step 3: Create the table header from the first row
$columns = $csvData[0].PSObject.Properties.Name
$htmlHeader += "<tr>" + ($columns | ForEach-Object { "<th>$_</th>" }) -join "" + "</tr>"

# --- Step 4: Add table rows
$htmlRows = ""
foreach ($row in $csvData) {
    $htmlRows += "<tr>"
    foreach ($col in $columns) {
        $value = $row.$col
        # If the value looks like a URL, make it clickable
        if ($value -match '^https?:\/\/') {
            $value = "<a href='$value' target='_blank'>$value</a>"
        }
        $htmlRows += "<td>$value</td>"
    }
    $htmlRows += "</tr>`n"
}

# --- Step 5: Combine and close HTML
$htmlFooter = @"
</table>
</body>
</html>
"@

# --- Step 6: Write to output HTML file
$htmlContent = $htmlHeader + $htmlRows + $htmlFooter
Set-Content -Path $OutputHTML -Value $htmlContent -Encoding UTF8

Write-Host "✅ Conversion complete! HTML file saved to: $OutputHTML"
