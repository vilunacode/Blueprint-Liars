# Automatisches Git-Publish-Script (Windows)
# Ausfuehren mit: Doppelklick auf publish.bat im Projektordner

param(
    [string]$CommitMessage = "Auto-commit: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
)

$env:PATH += ";C:\Program Files\Git\cmd"

$repoRoot = git rev-parse --show-toplevel
Set-Location $repoRoot

$currentBranch = git rev-parse --abbrev-ref HEAD
if ($currentBranch -ne "main") {
    Write-Host "Achtung: aktueller Branch ist '$currentBranch', nicht 'main'. Abbruch." -ForegroundColor Red
    exit 1
}

$status = git status --porcelain
if ($status) {
    Write-Host "Aenderungen gefunden. Committe und pushe..." -ForegroundColor Green
    git add .
    git commit -m $CommitMessage
    git push origin main
    Write-Host "Erfolgreich veroeffentlicht!" -ForegroundColor Green
} else {
    Write-Host "Keine Aenderungen gefunden." -ForegroundColor Yellow
}
