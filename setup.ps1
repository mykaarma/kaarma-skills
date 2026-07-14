# skills installer for PowerShell
#
# Symlinks (or copies) skills, agents, hooks, commands, and engineering-principles
# files into each detected CLI, desktop app, or IDE-extension config directory.

param (
    [switch]$Copy,
    [switch]$DryRun,
    [switch]$Help
)

if ($Help) {
    Write-Host 'Usage: .\setup.ps1 [--copy] [--dry-run] [--help]'
    exit 0
}

$REPO_DIR = $PSScriptRoot
$BACKUP_TS = Get-Date -Format 'yyyyMMdd-HHmmss'
$MODE = 'copy'

function Write-Info {
    param($msg)
    Write-Host "[OK] $msg" -ForegroundColor Green
}

function Write-Warn {
    param($msg)
    Write-Host "[WARN] $msg" -ForegroundColor Yellow
}

function Write-Action {
    param($msg)
    if ($DryRun) {
        Write-Host "[DRY-RUN] $msg" -ForegroundColor Yellow
    } else {
        Write-Host "[OK] $msg" -ForegroundColor Green
    }
}

function Maybe-Backup {
    param($target, $backup_dir)
    if (Test-Path $target) {
        $item = Get-Item $target
        if ($null -eq $item.LinkType) {
            if ($DryRun) {
                Write-Action "would back up $target -> $backup_dir/"
                return
            }
            if (-not (Test-Path $backup_dir)) {
                $null = New-Item -ItemType Directory -Path $backup_dir -Force
            }
            Move-Item -Path $target -Destination "$backup_dir/" -Force
            $leaf = Split-Path $target -Leaf
            Write-Info "Backed up $leaf -> $backup_dir/"
        }
    }
}

function Install-Path {
    param($target, $source)
    if ($DryRun) {
        Write-Action "would install $source -> $target ($MODE)"
        return
    }
    if (Test-Path $target) {
        Remove-Item -Path $target -Force -Recurse
    }
    if ($MODE -eq 'copy') {
        Copy-Item -Path $source -Destination $target -Recurse -Force
    } else {
        $null = New-Item -ItemType SymbolicLink -Path $target -Value $source -Force
    }
    Write-Info "$source -> $target"
}

function Install-SkillsAsCopies {
    param($dest_dir)
    if (-not (Test-Path $dest_dir)) {
        $null = New-Item -ItemType Directory -Path $dest_dir -Force
    }
    $copied = 0
    $skills = Get-ChildItem -Path "$REPO_DIR/skills" -Directory
    foreach ($skill in $skills) {
        $skill_name = $skill.Name
        $target = Join-Path $dest_dir $skill_name
        if ($DryRun) {
            Write-Action "would copy $skill_name -> $target"
        } else {
            if (Test-Path $target) {
                Remove-Item -Path $target -Force -Recurse
            }
            Copy-Item -Path $skill.FullName -Destination $target -Recurse -Force
        }
        $copied++
    }
    Write-Info "$copied skills -> $dest_dir/"
}

function Test-MatchingChildDirectory {
    param($dir)
    if (-not (Test-Path $dir)) { return $false }
    $match = Get-ChildItem -Path $dir -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '(?i)(claude|anthropic)' } |
        Select-Object -First 1
    return $null -ne $match
}

function Test-ClaudeSurface {
    if (Get-Command claude -ErrorAction SilentlyContinue) { return $true }

    $paths = @(
        (Join-Path $HOME '.claude'),
        (Join-Path $HOME 'Library/Application Support/Claude'),
        (Join-Path $HOME '.config/Claude'),
        (Join-Path $HOME '.config/claude')
    )

    if ($env:APPDATA) {
        $paths += @(
            (Join-Path $env:APPDATA 'Claude'),
            (Join-Path $env:APPDATA 'Anthropic/Claude')
        )
    }

    if ($env:LOCALAPPDATA) {
        $paths += @(
            (Join-Path $env:LOCALAPPDATA 'Claude'),
            (Join-Path $env:LOCALAPPDATA 'Programs/Claude'),
            (Join-Path $env:LOCALAPPDATA 'Programs/Claude/Claude.exe')
        )
    }

    if ($env:USERPROFILE) {
        $paths += @(
            (Join-Path $env:USERPROFILE '.claude'),
            (Join-Path $env:USERPROFILE 'AppData/Roaming/Claude'),
            (Join-Path $env:USERPROFILE 'AppData/Roaming/Anthropic/Claude'),
            (Join-Path $env:USERPROFILE 'AppData/Local/Claude'),
            (Join-Path $env:USERPROFILE 'AppData/Local/Programs/Claude'),
            (Join-Path $env:USERPROFILE 'AppData/Local/Programs/Claude/Claude.exe')
        )
    }

    $programRoots = @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ }
    foreach ($root in $programRoots) {
        $paths += @(
            (Join-Path $root 'Claude'),
            (Join-Path $root 'Anthropic/Claude'),
            (Join-Path $root 'Claude/Claude.exe'),
            (Join-Path $root 'Anthropic/Claude/Claude.exe')
        )
    }

    foreach ($path in $paths) {
        if ($path -and (Test-Path $path)) { return $true }
    }

    $extensionDirs = @(
        (Join-Path $HOME '.vscode/extensions'),
        (Join-Path $HOME '.vscode-insiders/extensions'),
        (Join-Path $HOME '.cursor/extensions'),
        (Join-Path $HOME '.antigravity-ide/extensions')
    )

    if ($env:USERPROFILE) {
        $extensionDirs += @(
            (Join-Path $env:USERPROFILE '.vscode/extensions'),
            (Join-Path $env:USERPROFILE '.vscode-insiders/extensions'),
            (Join-Path $env:USERPROFILE '.cursor/extensions'),
            (Join-Path $env:USERPROFILE '.antigravity-ide/extensions')
        )
    }

    foreach ($dir in $extensionDirs) {
        if (Test-MatchingChildDirectory $dir) { return $true }
    }

    return $false
}

function Setup-Claude {
    Write-Host '--- Claude Code / Desktop / IDE Extension ---'
    if (-not (Test-ClaudeSurface)) {
        Write-Warn 'Claude surface not found - skipping. Install Claude Code, Claude Desktop, or the Claude extension for VS Code/Antigravity.'
        Write-Host ''
        return
    }
    Write-Info 'Claude surface found'
    $dir = Join-Path $HOME '.claude'
    $backup_dir = Join-Path $dir "backup-$BACKUP_TS"
    if (-not (Test-Path $dir)) { $null = New-Item -ItemType Directory -Path $dir -Force }
    $items = @('skills', 'agents', 'hooks', 'commands', 'CLAUDE.md', 'AGENTS.md')
    foreach ($item in $items) {
        $p = Join-Path $dir $item
        Maybe-Backup $p $backup_dir
    }
    foreach ($item in $items) {
        $t = Join-Path $dir $item
        $s = Join-Path $REPO_DIR $item
        Install-Path $t $s
    }
    Write-Host ''
}

function Setup-Codex {
    Write-Host '--- Codex CLI ---'
    if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
        Write-Warn 'codex not found - skipping.'
        Write-Host ''
        return
    }
    Write-Info 'codex found'
    $dir = Join-Path $HOME '.codex'
    $backup_dir = Join-Path $dir "backup-$BACKUP_TS"
    if (-not (Test-Path $dir)) { $null = New-Item -ItemType Directory -Path $dir -Force }
    $items = @('skills', 'AGENTS.md')
    foreach ($item in $items) {
        $p = Join-Path $dir $item
        Maybe-Backup $p $backup_dir
    }
    foreach ($item in $items) {
        $t = Join-Path $dir $item
        $s = Join-Path $REPO_DIR $item
        Install-Path $t $s
    }
    Write-Host ''
}

function Setup-Gemini {
    Write-Host '--- Gemini CLI ---'
    if (-not (Get-Command gemini -ErrorAction SilentlyContinue)) {
        Write-Warn 'gemini not found - skipping.'
        Write-Host ''
        return
    }
    Write-Info 'gemini found'
    $dir = Join-Path $HOME '.gemini'
    $backup_dir = Join-Path $dir "backup-$BACKUP_TS"
    if (-not (Test-Path $dir)) { $null = New-Item -ItemType Directory -Path $dir -Force }

    $t1 = Join-Path $dir 'GEMINI.md'
    Maybe-Backup $t1 $backup_dir
    $s1 = Join-Path $REPO_DIR 'GEMINI.md'
    Install-Path $t1 $s1

    $t2 = Join-Path $dir 'skills'
    Maybe-Backup $t2 $backup_dir
    $s2 = Join-Path $REPO_DIR 'skills'
    Install-Path $t2 $s2

    $t3 = Join-Path $dir 'commands'
    Maybe-Backup $t3 $backup_dir
    $s3 = Join-Path $REPO_DIR 'gemini-commands'
    Install-Path $t3 $s3
    Write-Host ''
}

function Setup-Cursor {
    Write-Host '--- Cursor ---'
    if (-not (Get-Command cursor -ErrorAction SilentlyContinue)) {
        Write-Warn 'cursor not found - skipping.'
        Write-Host ''
        return
    }
    Write-Info 'cursor found'
    $dest = Join-Path $HOME '.cursor/skills'
    Install-SkillsAsCopies $dest
    Write-Host ''
}

function Test-AntigravityIDE {
    if (Get-Command antigravity -ErrorAction SilentlyContinue) { return $true }
    if (Get-Command agy -ErrorAction SilentlyContinue) { return $true }

    $paths = @(
        (Join-Path $HOME '.gemini/antigravity-ide'),
        (Join-Path $HOME '.gemini/config'),
        (Join-Path $HOME '.gemini/antigravity')
    )

    if ($env:APPDATA) {
        $paths += @(
            (Join-Path $env:APPDATA 'Antigravity'),
            (Join-Path $env:APPDATA 'Antigravity IDE')
        )
    }

    if ($env:LOCALAPPDATA) {
        $paths += @(
            (Join-Path $env:LOCALAPPDATA 'Programs/Antigravity IDE'),
            (Join-Path $env:LOCALAPPDATA 'Programs/Antigravity'),
            (Join-Path $env:LOCALAPPDATA 'Programs/Google Antigravity'),
            (Join-Path $env:LOCALAPPDATA 'Programs/Antigravity IDE/Antigravity IDE.exe'),
            (Join-Path $env:LOCALAPPDATA 'Programs/Antigravity/Antigravity.exe'),
            (Join-Path $env:LOCALAPPDATA 'Programs/Google Antigravity/Antigravity.exe')
        )
    }

    if ($env:USERPROFILE) {
        $paths += @(
            (Join-Path $env:USERPROFILE 'AppData/Local/Programs/Antigravity IDE'),
            (Join-Path $env:USERPROFILE 'AppData/Local/Programs/Antigravity IDE/Antigravity IDE.exe'),
            (Join-Path $env:USERPROFILE 'AppData/Local/Programs/Antigravity'),
            (Join-Path $env:USERPROFILE 'AppData/Local/Programs/Antigravity/Antigravity.exe'),
            (Join-Path $env:USERPROFILE 'AppData/Local/Programs/Google Antigravity'),
            (Join-Path $env:USERPROFILE 'AppData/Local/Programs/Google Antigravity/Antigravity.exe')
        )
    }

    $programRoots = @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ }
    foreach ($root in $programRoots) {
        $paths += @(
            (Join-Path $root 'Antigravity'),
            (Join-Path $root 'Antigravity IDE'),
            (Join-Path $root 'Google/Antigravity'),
            (Join-Path $root 'Google Antigravity'),
            (Join-Path $root 'Antigravity/Antigravity.exe'),
            (Join-Path $root 'Antigravity IDE/Antigravity IDE.exe'),
            (Join-Path $root 'Google/Antigravity/Antigravity.exe'),
            (Join-Path $root 'Google Antigravity/Antigravity.exe')
        )
    }

    foreach ($path in $paths) {
        if ($path -and (Test-Path $path)) { return $true }
    }

    return $false
}

function Setup-Antigravity {
    Write-Host '--- Antigravity ---'
    if (-not (Test-AntigravityIDE)) {
        Write-Warn 'Antigravity IDE not found - skipping. Download from https://antigravity.google'
        Write-Host ''
        return
    }
    Write-Info 'Antigravity IDE found'
    $s = Join-Path $REPO_DIR 'skills'
    $skills_dirs = @(
        (Join-Path $HOME '.gemini/antigravity-ide/skills'),
        (Join-Path $HOME '.gemini/config/skills')
    )
    foreach ($skills_dir in $skills_dirs) {
        $backup_dir = Join-Path (Split-Path $skills_dir -Parent) "backup-$BACKUP_TS"
        $parent_dir = Split-Path $skills_dir -Parent
        if (-not (Test-Path $parent_dir)) { $null = New-Item -ItemType Directory -Path $parent_dir -Force }
        Maybe-Backup $skills_dir $backup_dir
        Install-Path $skills_dir $s
    }
    Write-Host ''
}

# Main Execution Flow

Write-Host '======================================'
Write-Host '  skills installer (PowerShell)'
Write-Host '======================================'
Write-Host "  mode: $MODE"
Write-Host ''

Setup-Claude
Setup-Codex
Setup-Gemini
Setup-Cursor
Setup-Antigravity

Write-Host '======================================'
if ($DryRun) {
    Write-Host '  Dry run complete - no changes made.'
} else {
    Write-Info 'Setup complete!'
}
Write-Host ''
