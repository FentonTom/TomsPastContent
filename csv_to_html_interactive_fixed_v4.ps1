<#
.SYNOPSIS
    Converts a CSV of Tom Fenton's past articles into an interactive HTML page.

.DESCRIPTION
    - Reads CSV (default: SV_Data_V1.csv)
    - Sorts by Article Date (descending)
    - Sticky header in scrollable container
    - Clickable article URLs
    - Light/Dark toggle button
#>

param (
    [string]$InputCSV = "SV_Data_V1.csv",
    [string]$OutputHTML = "TJF_Art.html"
)

# --- Step 1: Import CSV ---
if (-Not (Test-Path $InputCSV)) {
    Write-Host "❌ Input CSV not found: $InputCSV"
    exit
}
$csvData = Import-Csv -Path $InputCSV
if (-not $csvData) {
    Write-Host "❌ No data found in CSV file."
    exit
}

# --- Step 2: Sort by Article Date ---
if ($csvData[0].PSObject.Properties.Name -contains "Article Date") {
    $csvData = $csvData | Sort-Object { [datetime]($_.'Article Date') } -Descending
}

# --- Step 3: HTML header with toggle button ---
$htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Tom Fenton’s Past Articles</title>
<style>
    :root {
        --bg-color: #121212;
        --text-color: #e0e0e0;
        --header-bg: #1e1e1e;
        --header-text: #ffffff;
        --row-even-bg: #1b1b1b;
        --link-color: #82aaff;
        --table-shadow: 0 2px 5px rgba(255,255,255,0.1);
    }
    body {
        font-family: Arial, sans-serif;
        background-color: var(--bg-color);
        color: var(--text-color);
        margin: 40px;
        transition: background-color 0.3s, color 0.3s;
    }
    h1 { text-align: center; color: var(--header-text); }
    #toggleButton {
        display: block;
        margin: 10px auto 20px auto;
        padding: 10px 20px;
        font-size: 16px;
        cursor: pointer;
    }
    .table-container {
        max-height: 70vh;
        overflow-y: auto;
        border: 1px solid #ddd;
        border-radius: 6px;
        box-shadow: var(--table-shadow);
    }
    table {
        border-collapse: collapse;
        width: 100%;
        table-layout: auto;
    }
    th, td {
        border: 1px solid #ddd;
        padding: 8px;
        text-align: left;
        max-width: 500px;
        word-wrap: break-word;
    }
    th {
        background-color: var(--header-bg);
        color: var(--header-text);
        position: sticky;
        top: 0;
        z-index: 2;
        cursor: pointer;
    }
    tr:nth-child(even) { background-color: var(--row-even-bg); }
    a { color: var(--link-color); text-decoration: none; }
    a:hover { text-decoration: underline; }
</style>
<script>
    function toggleMode() {
        const root = document.documentElement;
        const bg = getComputedStyle(root).getPropertyValue('--bg-color').trim();
        if (bg === '#121212') {
            root.style.setProperty('--bg-color','#f8f9fa');
            root.style.setProperty('--text-color','#333333');
            root.style.setProperty('--header-bg','#007bff');
            root.style.setProperty('--header-text','#ffffff');
            root.style.setProperty('--row-even-bg','#f2f2f2');
            root.style.setProperty('--link-color','#007bff');
            root.style.setProperty('--table-shadow','0 2px 5px rgba(0,0,0,0.1)');
        } else {
            root.style.setProperty('--bg-color','#121212');
            root.style.setProperty('--text-color','#e0e0e0');
            root.style.setProperty('--header-bg','#1e1e1e');
            root.style.setProperty('--header-text','#ffffff');
            root.style.setProperty('--row-even-bg','#1b1b1b');
            root.style.setProperty('--link-color','#82aaff');
            root.style.setProperty('--table-shadow','0 2px 5px rgba(255,255,255,0.1)');
        }
    }

    // Sorting including date handling
    document.addEventListener('DOMContentLoaded', function() {
        const getCellValue = (tr, idx) => tr.children[idx].innerText || tr.children[idx].textContent;
        const comparer = (idx, asc) => (a, b) => {
            const colName = a.parentNode.parentNode.querySelectorAll('th')[idx].innerText;
            let v1 = getCellValue(asc ? a : b, idx);
            let v2 = getCellValue(asc ? b : a, idx);
            if (colName === 'Article Date') { return new Date(v1) - new Date(v2); }
            else if (!isNaN(v1) && !isNaN(v2)) { return v1 - v2; }
            else { return v1.toString().localeCompare(v2); }
        };
        document.querySelectorAll('th').forEach(th => th.addEventListener('click', (() => {
            const table = th.closest('table');
            Array.from(table.querySelectorAll('tr:nth-child(n+2)'))
                .sort(comparer(Array.from(th.parentNode.children).indexOf(th), this.asc = !this.asc))
                .forEach(tr => table.appendChild(tr));
        })));
    });
</script>
</head>
<body>
<h1>Tom Fenton’s Past Articles</h1>
<button id="toggleButton" onclick="toggleMode()">Toggle Light/Dark Mode</button>
<div class="table-container">
<table>
"@

# --- Table headers ---
$columns = $csvData[0].PSObject.Properties.Name | Where-Object { $_ -ne "Article Website" }
# No Website column
$htmlHeader += "<tr>" + (($columns | ForEach-Object { "<th>$_</th>" }) -join "") + "</tr>`n"

# --- Table rows ---
$htmlRows = ""
foreach ($row in $csvData) {
    $htmlRows += "<tr>"
    foreach ($col in $columns) {
        $value = $row.$col
        if ($value -match '^https?:\/\/') { $value = "<a href='$value' target='_blank'>$value</a>" }
        $htmlRows += "<td>$value</td>"
    }
    $htmlRows += "</tr>`n"
}

# --- Close HTML ---
$htmlFooter = @"
</table>
</div>
</body>
</html>
"@

# --- Write HTML ---
$htmlContent = $htmlHeader + $htmlRows + $htmlFooter
Set-Content -Path $OutputHTML -Value $htmlContent -Encoding UTF8

Write-Host "✅ HTML file created: $OutputHTML with sticky header, sortable Article Date, and light/dark toggle (Website column removed)"

