# Regenerates the Jolt C++ source list in build.zig from lib/jolt/Jolt/**/*.cpp
# Usage: .\update-build-zig-sources.ps1 [-CheckOnly]

param(
    [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$buildZigPath = Join-Path $root "build.zig"
$joltRoot = Join-Path $root "lib\jolt\Jolt"

if (-not (Test-Path $buildZigPath)) {
    throw "build.zig not found at $buildZigPath"
}
if (-not (Test-Path $joltRoot)) {
    throw "Jolt sources not found at $joltRoot (is the submodule initialized?)"
}

$relativePaths = Get-ChildItem -Path $joltRoot -Recurse -Filter "*.cpp" |
    ForEach-Object {
        $rel = $_.FullName.Substring($joltRoot.Length + 1).Replace("\", "/")
        "Jolt/$rel"
    } |
    Sort-Object

$lines = $relativePaths | ForEach-Object { "        jolt_dir ++ `"$_`"," }

$startMarker = "    lib.addCSourceFiles(&.{"
$endMarker = "    }, flags);"

$content = Get-Content $buildZigPath -Raw
$pattern = '(?s)(    // add jolt sources\r?\n\r?\n    const jolt_dir = "lib/jolt/";\r?\n\r?\n    lib\.addIncludePath\(\.\{\r?\n        \.path = jolt_dir\r?\n    \}\);\r?\n\r?\n    lib\.addCSourceFiles\(&\.\{\r?\n).*?(\r?\n    \}, flags\);\r?\n\r?\n    b\.installArtifact)'

$newBlock = @"
    // add jolt sources

    const jolt_dir = "lib/jolt/";

    lib.addIncludePath(.{
        .path = jolt_dir
    });

    lib.addCSourceFiles(&.{
$($lines -join "`n")
    }, flags);

    b.installArtifact
"@

if ($content -notmatch $pattern) {
    throw "Could not locate Jolt addCSourceFiles block in build.zig"
}

$updated = [regex]::Replace($content, $pattern, $newBlock)

$diskCount = $relativePaths.Count
$zigCount = ([regex]::Matches($content, 'jolt_dir \+\+ "Jolt/')).Count
Write-Host "Jolt .cpp on disk: $diskCount"
Write-Host "Jolt .cpp in build.zig (before): $zigCount"

if ($content -eq $updated) {
    Write-Host "build.zig is already up to date."
    exit 0
}

if ($CheckOnly) {
    Write-Host "build.zig is out of date. Run without -CheckOnly to update."
    exit 1
}

Set-Content -Path $buildZigPath -Value $updated -NoNewline
Write-Host "Updated build.zig with $diskCount source files."
