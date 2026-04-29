$ErrorActionPreference = "Stop"
$target = "e:\ticket-sales-microservices"

Write-Output "Replacing text in files..."
Get-ChildItem -Path $target -Recurse -File | Where-Object {
    $_.FullName -notmatch "\\\.git\\" -and
    $_.Extension -notmatch "\.(jar|class|png|jpg|jpeg|gif|ico)$"
} | ForEach-Object {
    try {
        $content = [System.IO.File]::ReadAllText($_.FullName)
        if ($content -match "krimo|Krimo") {
            $newContent = $content -replace "krimo", "karanpraja902" -replace "Krimo", "Karanpraja902"
            [System.IO.File]::WriteAllText($_.FullName, $newContent)
            Write-Output "Updated file: $($_.FullName)"
        }
    } catch {
        Write-Warning "Could not read $($_.FullName): $($_.Exception.Message)"
    }
}

Write-Output "Renaming directories..."
Get-ChildItem -Path $target -Recurse -Directory | Where-Object {
    $_.FullName -notmatch "\\\.git\\" -and
    $_.Name -match "krimo|Krimo"
} | Sort-Object -Property @{Expression={$_.FullName.Length}; Descending=$true} | ForEach-Object {
    $newName = $_.Name -replace "krimo", "karanpraja902" -replace "Krimo", "Karanpraja902"
    Rename-Item -Path $_.FullName -NewName $newName
    Write-Output "Renamed dir: $($_.FullName) to $newName"
}

Write-Output "Refactoring complete."
