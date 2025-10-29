param (
    [Parameter(Mandatory = $true)]
    [string]$InputCSV,

    [Parameter(Mandatory = $true)]
    [string]$OutputHTML
)

# --- Step 1: Import and sort CSV by Article Date ---
$csvData = Import-Csv -Path $InputCSV
if (-not $csvData) {
    Write-Host "❌ No data found in CSV file."
    exit
}

if ($csvData[0].PSObject.Properties.Name -contains "Article Date") {
    $csvData = $csvData | Sort-Object { [datetime]($_.'Article Date') } -Descending
} else {
    Write-Host "⚠️  'Article Date' column not found — output will not be sorted."
}

# --- Step 2: Add derived "Article Website" column ---
foreach ($row in $csvData) {
    $url = $row.URL
    if ($url -match '^https?:\/\/([^\/]+)') {
        $domain = $matches[1]
        $row | Add-Member -NotePropertyName "Article Website" -NotePropertyValue $domain
    } else {
        $row | Add-Member -NotePropertyName "Article Website" -NotePropertyValue ""
    }
}

# --- Step 3: Build HTML with escaped curly braces ---
$htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Tom Fenton’s Past Articles</title>
<style>
    body {{ font-family: Arial, sans-serif; background-color: #f8f9fa; margin: 40px; }}
    h1 {{ color: #333333; text-align: center; }}
    input[type=""text""] {{ display: block; margin: 0 auto 20px auto; padding: 10px; width: 50%; font-size: 16px; border: 1px solid #ccc; border-radius: 5px; box-shadow: inset 0 1px 3px rgba(0,0,0,0.1); }}
    table {{ border-collapse: collapse; width: 100%; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }}
    th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
    th {{ background-color: #007bff; color: white; cursor: pointer; user-select: none; }}
    tr:nth-child(even) {{ background-color: #f2f2f2; }}
    a {{ color: #007bff; text-decoration: none; }}
    a:hover {{ text-decoration: underline; }}
    mark {{ background-color: yellow; font-weight: bold; }}
    .no-results {{ text-align: center; font-style: italic; color: #777; }}
</style>
<script>
function sortTable(n) {{ /* JS code for sorting */ }}
function searchTable() {{ /* JS code for search and highlighting */ }}
</script>
</head>
<body>
<h1>Tom Fenton’s Past Articles</h1>
<input type=""text"" id=""searchInput"" onkeyup=""searchTable()"" placeholder=""🔍 Search articles by title, date, or website..."">
<table id="articleTable">
"@

# --- Step 4: Headers ---
$columns = $csvData[0].PSObject.Properties.Name
$htmlHeader += "<tr>" + (
    for ($i = 0; $i -lt $columns.Count; $i++) {
        "<th onclick='sortTable($i)'>$($columns[$i])</th>"
    }
) -join "" + "</tr>"

# --- Step 5: Data rows ---
$htmlRows = ""
foreach ($row in $csvData) {
    $htmlRows += "<tr>"
    foreach ($col in $columns) {
        $value = $row.$col
        if ($value -match '^https?:\/\/') {
            $value = "<a href='$value' target='_blank'>$value</a>"
        }
        $htmlRows += "<td>$value</td>"
    }
    $htmlRows += "</tr>`n"
}

# --- Step 6: No results row ---
$htmlFooter = @"
<tr id=""noResults"" class=""no-results"" style=""display:none;"">
    <td colspan=""$($columns.Count)"">No matching articles found.</td>
</tr>
</table>
</body>
</html>
"@

# --- Step 7: Write HTML ---
$htmlContent = $htmlHeader + $htmlRows + $htmlFooter
Set-Content -Path $OutputHTML -Value $htmlContent -Encoding UTF8

Write-Host "✅ HTML created successfully!"
