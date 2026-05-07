# skills installer for PowerShell
#
# Symlinks (or copies) skills, agents, hooks, commands, and engineering-principles
# files into each detected CLI's config directory.

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

function Setup-Claude {
    Write-Host '--- Claude Code ---'
    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        Write-Warn 'claude not found - skipping.'
        Write-Host ''
        return
    }
    Write-Info 'claude found'
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

function Setup-Antigravity {
    Write-Host '--- Antigravity ---'
    if (-not (Get-Command antigravity -ErrorAction SilentlyContinue)) {
        Write-Warn 'antigravity not found - skipping.'
        Write-Host ''
        return
    }
    Write-Info 'antigravity found'
    $skills_dir = Join-Path $HOME '.gemini/antigravity/skills'
    $backup_dir = Join-Path $HOME ".gemini/backup-$BACKUP_TS"
    $parent_dir = Split-Path $skills_dir -Parent
    if (-not (Test-Path $parent_dir)) { $null = New-Item -ItemType Directory -Path $parent_dir -Force }
    Maybe-Backup $skills_dir $backup_dir
    $s = Join-Path $REPO_DIR 'skills'
    Install-Path $skills_dir $s
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
