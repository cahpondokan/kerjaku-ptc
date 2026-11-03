param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

# Run after `dart run flutter_launcher_icons`. This packages the approved raster
# assets for Android's circular and adaptive masks without redrawing the emblem.
$resourceRoot = Join-Path $ProjectRoot 'android/app/src/main/res'
$outputRoot = Join-Path $ProjectRoot 'output/icons'
New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
$adaptivePath = Join-Path $resourceRoot 'mipmap-anydpi-v26/ic_launcher.xml'
$adaptiveXml = Get-Content -LiteralPath $adaptivePath -Raw
$adaptiveXml = $adaptiveXml.Replace('@color/ic_launcher_background', '@drawable/ic_launcher_gradient')
[IO.File]::WriteAllText($adaptivePath, $adaptiveXml)
[IO.File]::WriteAllText((Join-Path $resourceRoot 'mipmap-anydpi-v26/ic_launcher_round.xml'), $adaptiveXml)

$foreground = [System.Drawing.Image]::FromFile((Join-Path $ProjectRoot 'assets/icons/app_icon_foreground.png'))
$layer = [System.Drawing.Bitmap]::new(1080, 1080, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$canvas = [System.Drawing.Graphics]::FromImage($layer)
$gradient = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
    [System.Drawing.Rectangle]::new(0, 0, 1080, 1080),
    [System.Drawing.ColorTranslator]::FromHtml('#38B9F8'),
    [System.Drawing.ColorTranslator]::FromHtml('#0323B6'), [single]45)
$stops = [System.Drawing.Drawing2D.ColorBlend]::new(3)
$stops.Colors = @([System.Drawing.ColorTranslator]::FromHtml('#38B9F8'),
    [System.Drawing.ColorTranslator]::FromHtml('#086AFF'),
    [System.Drawing.ColorTranslator]::FromHtml('#0323B6'))
$stops.Positions = @([single]0, [single]0.5, [single]1)
$gradient.InterpolationColors = $stops
$canvas.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$canvas.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$canvas.FillRectangle($gradient, 0, 0, 1080, 1080)
# Match the 20% inset in Android's adaptive XML. Android displays the central 72dp
# of the 108dp layer; the document and clock remain inside the mask's safe area.
$canvas.DrawImage($foreground, [System.Drawing.Rectangle]::new(216, 216, 648, 648))
$canvas.Dispose()
$gradient.Dispose()
$foreground.Dispose()

function Save-MaskedIcon([int]$Size, [string]$Path, [bool]$Round) {
    $icon = [System.Drawing.Bitmap]::new($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($icon)
    $mask = [System.Drawing.Drawing2D.GraphicsPath]::new()
    try {
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        if ($Round) { $mask.AddEllipse(0, 0, $Size, $Size) } else {
            $corner = [single]($Size * 0.4)
            $edge = [single]($Size - $corner)
            $mask.AddArc(0, 0, $corner, $corner, 180, 90)
            $mask.AddArc($edge, 0, $corner, $corner, 270, 90)
            $mask.AddArc($edge, $edge, $corner, $corner, 0, 90)
            $mask.AddArc(0, $edge, $corner, $corner, 90, 90)
            $mask.CloseFigure()
        }
        $graphics.SetClip($mask)
        $graphics.DrawImage($layer, [System.Drawing.Rectangle]::new(0, 0, $Size, $Size),
            180, 180, 720, 720, [System.Drawing.GraphicsUnit]::Pixel)
        $icon.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally { $mask.Dispose(); $graphics.Dispose(); $icon.Dispose() }
}

try {
    $densities = [ordered]@{mdpi = 48; hdpi = 72; xhdpi = 96; xxhdpi = 144; xxxhdpi = 192}
    foreach ($density in $densities.GetEnumerator()) {
        $roundPath = Join-Path $resourceRoot "mipmap-$($density.Key)/ic_launcher_round.png"
        Save-MaskedIcon -Size $density.Value -Path $roundPath -Round $true
    }
    Save-MaskedIcon -Size 512 -Path (Join-Path $outputRoot 'preview-adaptive-round.png') -Round $true
    Save-MaskedIcon -Size 512 -Path (Join-Path $outputRoot 'preview-adaptive-rounded.png') -Round $false
    Write-Output 'Updated circular launcher icons, adaptive XML, and mask previews.'
} finally { $layer.Dispose() }
