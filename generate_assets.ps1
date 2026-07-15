# PowerShell script to generate placeholder asset files for ChronoQuest
# Creates minimal PNG files (1x1 pixel colored rectangles) and empty sound files

$base = "c:\Users\PC\Documents\CHRONO GAME APP\assets"

# Create directories
$dirs = @(
    "backgrounds", "characters", "enemies", "bosses",
    "obstacles", "collectibles", "powerups", "ui", "sounds", "animations"
)
foreach ($d in $dirs) {
    New-Item -ItemType Directory -Path "$base\$d" -Force | Out-Null
}

# Function to create a minimal 1x1 PNG file (smallest valid PNG)
function Create-PlaceholderPng {
    param([string]$path)
    # Minimal valid 1x1 red pixel PNG (67 bytes)
    $bytes = [byte[]]@(
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, # PNG signature
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, # IHDR chunk
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, # 1x1
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, # 8-bit RGB
        0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54, # IDAT chunk
        0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00, 0x00, # compressed data
        0x00, 0x02, 0x00, 0x01, 0xE2, 0x21, 0xBC, 0x33, # 
        0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, # IEND chunk
        0xAE, 0x42, 0x60, 0x82
    )
    [System.IO.File]::WriteAllBytes($path, $bytes)
}

# Backgrounds
$bgFiles = @(
    "login_bg", "character_select_bg", "bookshelf_bg",
    "precolonial_far", "precolonial_near",
    "spanish_far", "spanish_near",
    "american_far", "american_near",
    "ww2_far", "ww2_near",
    "modern_far", "modern_near"
)
foreach ($f in $bgFiles) { Create-PlaceholderPng "$base\backgrounds\$f.png" }

# Characters (5 chars x 6 images)
$chars = @("lapu", "rizal", "luna", "bonifacio", "delpilar")
foreach ($c in $chars) {
    for ($i = 1; $i -le 4; $i++) { Create-PlaceholderPng "$base\characters\${c}_walk_$i.png" }
    Create-PlaceholderPng "$base\characters\${c}_jump.png"
    Create-PlaceholderPng "$base\characters\${c}_hurt.png"
}

# Enemies (10 types x 2 frames)
$enemies = @(
    "tribal_warrior", "dark_spirit", "spanish_soldier", "tax_collector",
    "american_soldier", "propaganda", "japanese_soldier", "tank",
    "corruption_figure", "misinfo_cloud"
)
foreach ($e in $enemies) {
    Create-PlaceholderPng "$base\enemies\${e}_1.png"
    Create-PlaceholderPng "$base\enemies\${e}_2.png"
}

# Bosses (5 x 3 images)
$bosses = @("bakunawa", "governor", "general", "commander", "corruption_boss")
foreach ($b in $bosses) {
    Create-PlaceholderPng "$base\bosses\${b}_idle.png"
    Create-PlaceholderPng "$base\bosses\${b}_attack.png"
    Create-PlaceholderPng "$base\bosses\${b}_defeated.png"
}

# Obstacles
$eras = @("precolonial", "spanish", "american", "ww2", "modern")
foreach ($e in $eras) { Create-PlaceholderPng "$base\obstacles\${e}_wall.png" }

# Collectibles
Create-PlaceholderPng "$base\collectibles\coin.png"
for ($i = 1; $i -le 5; $i++) { Create-PlaceholderPng "$base\collectibles\artifact_$i.png" }

# Powerups
Create-PlaceholderPng "$base\powerups\fifty_fifty.png"
Create-PlaceholderPng "$base\powerups\time_freeze.png"
Create-PlaceholderPng "$base\powerups\shield.png"

# UI
$uiFiles = @("heart_full", "heart_empty", "star_full", "star_empty", "lock_icon")
foreach ($u in $uiFiles) { Create-PlaceholderPng "$base\ui\$u.png" }

# Sounds - create empty MP3 files (just needs to exist)
$sounds = @(
    "correct", "wrong", "jump", "enemy_defeat", "player_hurt",
    "coin", "powerup", "level_complete", "level_failed",
    "boss_appear", "boss_defeat", "era_complete", "footsteps",
    "bgm_precolonial", "bgm_spanish", "bgm_american", "bgm_ww2", "bgm_modern"
)
foreach ($s in $sounds) {
    # Create minimal valid MP3 (MPEG frame header + silence)
    $mp3bytes = [byte[]]@(0xFF, 0xFB, 0x90, 0x00)
    [System.IO.File]::WriteAllBytes("$base\sounds\$s.mp3", $mp3bytes)
}

# Lottie animation placeholder
$lottie = '{"v":"5.5.7","fr":30,"ip":0,"op":60,"w":300,"h":300,"assets":[],"layers":[]}'
Set-Content -Path "$base\animations\fireworks.json" -Value $lottie

Write-Host "Created all placeholder assets!"
Write-Host "  - Backgrounds: $($bgFiles.Count)"
Write-Host "  - Characters: $($chars.Count * 6)"
Write-Host "  - Enemies: $($enemies.Count * 2)"
Write-Host "  - Bosses: $($bosses.Count * 3)"
Write-Host "  - Obstacles: $($eras.Count)"
Write-Host "  - Collectibles: 6"
Write-Host "  - Powerups: 3"
Write-Host "  - UI: $($uiFiles.Count)"
Write-Host "  - Sounds: $($sounds.Count)"
Write-Host "  - Animations: 1"
