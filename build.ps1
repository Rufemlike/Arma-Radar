param(
    [string]$toolsDir = "C:\Program Files (x86)\Steam\steamapps\common\Arma 3 Tools"
)

$addonBuilder = Join-Path $toolsDir "AddonBuilder\AddonBuilder.exe"
$projectRoot = $PSScriptRoot
$sourceDir = Join-Path $projectRoot "Source\arma_radar"
$destModDir = Join-Path $projectRoot "@AirDefender_Radar\addons"
$workshopDir = "C:\Program Files (x86)\Steam\steamapps\common\Arma 3\!Workshop\@Arma Radar\addons"

Write-Host "Building arma_radar.pbo with AddonBuilder..." -ForegroundColor Cyan

$arma = Get-Process -Name "arma3_x64", "arma3" -ErrorAction SilentlyContinue
if ($arma) {
    Write-Warning "Arma 3 is currently running! Please close Arma 3 so the PBO file can be replaced."
    exit 1
}

& $addonBuilder "$sourceDir" "$destModDir" -prefix=arma_radar -project="$projectRoot\Source" -packonly -clear

if (Test-Path "$destModDir\arma_radar.pbo") {
    Write-Host "Build successful: $destModDir\arma_radar.pbo" -ForegroundColor Green
    if (Test-Path (Split-Path $workshopDir)) {
        Copy-Item "$destModDir\arma_radar.pbo" "$workshopDir\arma_radar.pbo" -Force -ErrorAction SilentlyContinue
        Write-Host "Copied to Workshop: $workshopDir\arma_radar.pbo" -ForegroundColor Green
    }
} else {
    Write-Error "Build failed!"
}
