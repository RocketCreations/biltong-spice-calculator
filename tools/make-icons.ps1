# Generates every app icon from one vector mark: a boerewors coil.
# Pure .NET GDI+ - no Python, Node or ImageMagick needed.
# Run from anywhere:  powershell -ExecutionPolicy Bypass -File tools\make-icons.ps1

Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'
$root    = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$iconDir = Join-Path $root 'icons'
if (-not (Test-Path $iconDir)) { New-Item -ItemType Directory -Path $iconDir | Out-Null }

$INK  = '#8E2F22'   # oxblood ground
$WORS = '#F2E7D5'   # cured-cream coil

# --- the mark, described in units where the sausage is exactly 1.0 thick ---
function Get-CoilPoints {
    $strokeUnits = 1.0
    $turns       = 1.9
    $spacing     = 1.25 * $strokeUnits          # gap between successive turns
    $b           = $spacing / (2 * [Math]::PI)  # Archimedean growth
    $r0          = 1.35 * $strokeUnits          # inner radius -> a visible hole
    $thetaMax    = $turns * 2 * [Math]::PI
    $steps       = 480

    $pts = New-Object 'System.Collections.Generic.List[System.Drawing.PointF]'
    for ($i = 0; $i -le $steps; $i++) {
        $t = $thetaMax * $i / $steps
        $r = $r0 + $b * $t
        $a = $t - [Math]::PI / 2      # start the tail at the bottom
        $pts.Add([System.Drawing.PointF]::new([float]($r * [Math]::Cos($a)), [float]($r * [Math]::Sin($a))))
    }
    return $pts
}

function New-Icon {
    param(
        [int]    $Size,
        [string] $Path,
        [double] $Fill = 0.80   # fraction of the canvas the mark spans
    )

    $pts = Get-CoilPoints
    $strokeUnits = 1.0

    # fit the mark to the canvas: centre its bounding box, scale to $Fill
    $minX = ($pts | ForEach-Object { $_.X } | Measure-Object -Minimum).Minimum
    $maxX = ($pts | ForEach-Object { $_.X } | Measure-Object -Maximum).Maximum
    $minY = ($pts | ForEach-Object { $_.Y } | Measure-Object -Minimum).Minimum
    $maxY = ($pts | ForEach-Object { $_.Y } | Measure-Object -Maximum).Maximum

    $extent = [Math]::Max($maxX - $minX, $maxY - $minY) + $strokeUnits
    $scale  = ($Size * $Fill) / $extent
    $offX   = ($Size / 2.0) - (($minX + $maxX) / 2.0) * $scale
    $offY   = ($Size / 2.0) - (($minY + $maxY) / 2.0) * $scale

    $scaled = foreach ($p in $pts) {
        [System.Drawing.PointF]::new([float]($p.X * $scale + $offX), [float]($p.Y * $scale + $offY))
    }

    $bmp = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.ColorTranslator]::FromHtml($INK))   # opaque: iOS forbids alpha

    $pen = New-Object System.Drawing.Pen(
        [System.Drawing.ColorTranslator]::FromHtml($WORS),
        [float]($strokeUnits * $scale))
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $g.DrawLines($pen, [System.Drawing.PointF[]]$scaled)

    $pen.Dispose(); $g.Dispose()
    $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    '{0,-28} {1}x{1}' -f (Split-Path -Leaf $Path), $Size
}

New-Icon -Size 192 -Path (Join-Path $iconDir 'icon-192.png')
New-Icon -Size 512 -Path (Join-Path $iconDir 'icon-512.png')
New-Icon -Size 180 -Path (Join-Path $iconDir 'apple-touch-icon.png')
New-Icon -Size  32 -Path (Join-Path $iconDir 'favicon-32.png') -Fill 0.88
# maskable: Android crops to a circle, so pull the mark inside the safe zone
New-Icon -Size 512 -Path (Join-Path $iconDir 'icon-maskable-512.png') -Fill 0.70

Write-Host "`nIcons written to $iconDir"
