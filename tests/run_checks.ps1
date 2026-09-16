param([Parameter(Mandatory=$true)][string]$GodotPath)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
foreach ($check in @('test_journey.gd', 'test_battle.gd', 'test_save.gd', 'test_ui.gd')) {
    $output = & $GodotPath --headless --debug --ignore-error-breaks --path $projectRoot --script "res://tests/$check" 2>&1
    $result = $LASTEXITCODE
    $output | Write-Output
    if ($result -ne 0 -or ($output -join "`n") -match '(SCRIPT ERROR:|ERROR:|WARNING:|FAIL:)') {
        throw "Verification failed: $check"
    }
}
Write-Output 'All journey checks passed.'
