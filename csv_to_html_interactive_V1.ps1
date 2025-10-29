<#
.SYNOPSIS
    Converts a CSV file of Tom Fenton's past articles into an interactive, searchable, sortable HTML page with text highlighting.

.DESCRIPTION
    Reads a CSV file of articles, sorts by "Article Date" (newest first),
    adds "Article Website" (domain from URL), and generates an HTML page that supports:
      - Clickable sorting by any column
      - Search filtering across all fields
      - Highlighted search matches
      - Clickable URLs

.PARAMETER InputCSV
    Path to the CSV file containing article data.

.PARAMETER OutputHTML
    Path where the HTML file will be saved.

.EXAMPLE
    .\Convert-CSVToHTML.ps1 -InputCSV "C:\data\articles.csv" -OutputHTML "C:\data\TomFentonArticles.html"

.NOTES
    Author: Tom Fenton
    Updated: October 2025
#>

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

# --- Step 2: Add derived "Article Website" column (extract domain) ---
foreach ($row in $csvData) {
    $url = $row.URL
    if ($url -match '^https?:\/\/([^\/]+)') {
        $domain = $matches[1]
        $row | Add-Member -NotePropertyName "Article Website" -NotePropertyValue $domain
    } else {
        $row | Add-Member -NotePropertyName "Article Website" -NotePropertyValue ""
    }
}

# --- Step 3: Build HTML structure with styles and scripts ---
$htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Tom Fenton’s Past Articles</title>
<style>
    body { font-family: Arial, sans-serif; background-color: #f8f9fa; margin: 40px; }
    h1 { color: #333333; text-align: center; }
    input[type="text"] {
        display: block;
        margin: 0 auto 20px auto;
        padding: 10px;
        width: 50%;
        font-size: 16px;
        border: 1px solid #ccc;
        border-radius: 5px;
        box-shadow: inset 0 1px 3px rgba(0,0,0,0.1);
    }
    table { border-collapse: collapse; width: 100%; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #007bff; color: white; cursor: pointer; user-select: none; }
    tr:nth-child(even) { background-color: #f2f2f2; }
    a { color: #007bff; text-decoration: none; }
    a:hover { text-decoration: underline; }
    mark { background-color: yellow; font-weight: bold; }
    .no-results { text-align: center; font-style: italic; color: #777; }
</style>
<script>
    // --- Sorting ---
    function sortTable(n) {
        const table = document.getElementById("articleTable");
        let switching = true, dir = "asc", switchcount = 0;
        while (switching) {
            switching = false;
            const rows = table.rows;
            for (let i = 1; i < rows.length - 1; i++) {
                let shouldSwitch = false;
                const x = rows[i].getElementsByTagName("TD")[n];
                const y = rows[i + 1].getElementsByTagName("TD")[n];
                let xVal = x.textContent || x.innerText;
                let yVal = y.textContent || y.innerText;

                const xDate = Date.parse(xVal);
                const yDate = Date.parse(yVal);
                if (!isNaN(xDate) && !isNaN(yDate)) { xVal = xDate; yVal = yDate; }
                else if (!isNaN(parseFloat(xVal)) && !isNaN(parseFloat(yVal))) {
                    xVal = parseFloat(xVal); yVal = parseFloat(yVal);
                }

                if (dir === "asc" && xVal > yVal) shouldSwitch = true;
                if (dir === "desc" && xVal < yVal) shouldSwitch = true;

                if (shouldSwitch) {
                    rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
                    switching = true;
                    switchcount++;
                    break;
                }
            }
            if (!switching && switchcount === 0) {
                dir = dir === "asc" ? "desc" : "asc";
                switching = true;
            }
        }
    }

    // --- Search and highlight ---
    function searchTable() {
        const input = document.getElementById("searchInput");
        const filter = input.value.toLowerCase();
        const table = document.getElementById("articleTable");
        const rows = table.getElementsByTagName("tr");
        let visibleCount = 0;

        for (let i = 1; i < rows.length; i++) {
            const tds = rows[i].getElementsByTagName("td");
            let match = false;
            for (let j = 0; j < tds.length; j++) {
                const text = tds[j].textContent || tds[j].innerText;
                if (filter && text.toLowerCase().includes(filter)) {
                    match = true;
                    const regex = new RegExp("(" + filter + ")", "gi");
                    tds[j].innerHTML = text.replace(regex, "<mark>$1</mark>");
                } else {
                    tds[j].innerHTML = text; // remove previous highlights
                }
            }
            rows[i].style.display = match || filter === "" ? "" : "none";
            if (rows[i].style.display !== "none") visibleCount++;
        }

        document.getElementById("noResults").style.display = visibleCount ? "none" : "table-row";
    }
</script>
</head>
<body>
<h1>Tom Fenton’s Past Articles</h1>
<input type="text" id="searchInput" onkeyup="searchTable()" placeholder="🔍 Search articles by title, date, or website...">
<table id="articleTable">
"@

# --- Step 4: Create sortable headers ---
$columns = $csvData[0].PSObject.Properties.Name
$htmlHeader += "<tr>" + (
    for ($i = 0; $i -lt $columns.Count; $i++) {
        "<th onclick='sortTable($i)'>$($columns[$i])</th>"
    }
) -join "" + "</tr>"

# --- Step 5: Add data rows ---
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

# --- Step 6: Add no-results message ---
$htmlFooter = @"
<tr id="noResults" class="no-results" style="display:none;">
    <td colspan="$($columns.Count)">No matching articles found.</td>
</tr>
</table>
</body>
</html>
"@

# --- Step 7: Write output ---
$htmlContent = $htmlHeader + $htmlRows + $htmlFooter
Set-Content -Path $OutputHTML -Value $htmlContent -Encoding UTF8

Write-Host "✅ Interactive HTML created successfully with live search, highlighting, and sorting!"
