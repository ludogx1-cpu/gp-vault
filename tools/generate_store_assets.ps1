Add-Type -AssemblyName System.Drawing

$src = [System.Drawing.Image]::FromFile((Join-Path (Get-Location) "assets\Goldenpawicon.png"))
$targetWidth = 512
$targetHeight = 512
$dest = New-Object System.Drawing.Bitmap($targetWidth, $targetHeight)
$graphics = [System.Drawing.Graphics]::FromImage($dest)
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

$graphics.Clear([System.Drawing.Color]::Transparent)
$graphics.DrawImage($src, 0, 0, $targetWidth, $targetHeight)

$outDir = Join-Path (Get-Location) "fastlane\metadata\android\en-US\images"
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$dest.Save((Join-Path $outDir "icon.png"), [System.Drawing.Imaging.ImageFormat]::Png)

$graphics.Dispose()
$dest.Dispose()
$src.Dispose()

Write-Host "512x512 icon generated successfully at $outDir\icon.png"

# Generate 1024x500 Feature Graphic
$fgWidth = 1024
$fgHeight = 500
$fgBitmap = New-Object System.Drawing.Bitmap($fgWidth, $fgHeight)
$fgG = [System.Drawing.Graphics]::FromImage($fgBitmap)
$fgG.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$fgG.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$fgG.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

# Background: draw bg.png or gradient
$bgPath = Join-Path (Get-Location) "assets\bg.png"
if (Test-Path $bgPath) {
    $bgImg = [System.Drawing.Image]::FromFile($bgPath)
    $fgG.DrawImage($bgImg, 0, 0, $fgWidth, $fgHeight)
    $bgImg.Dispose()
} else {
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(26, 26, 36))
    $fgG.FillRectangle($brush, 0, 0, $fgWidth, $fgHeight)
    $brush.Dispose()
}

# Dark overlay for contrast
$overlayBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(120, 10, 10, 15))
$fgG.FillRectangle($overlayBrush, 0, 0, $fgWidth, $fgHeight)
$overlayBrush.Dispose()

# Draw Golden Paw Icon on left side
$iconPath = Join-Path (Get-Location) "fastlane\metadata\android\en-US\images\icon.png"
if (Test-Path $iconPath) {
    $iconImg = [System.Drawing.Image]::FromFile($iconPath)
    $fgG.DrawImage($iconImg, 70, 75, 350, 350)
    $iconImg.Dispose()
}

# Draw Title Logo on right side
$titlePath = Join-Path (Get-Location) "assets\Golen Paw Title.png"
if (Test-Path $titlePath) {
    $titleImg = [System.Drawing.Image]::FromFile($titlePath)
    # Scale title to fit right half
    $titleW = 500
    $titleH = [int]($titleImg.Height * ($titleW / $titleImg.Width))
    $fgG.DrawImage($titleImg, 460, 160, $titleW, $titleH)
    $titleImg.Dispose()
}

# Draw Shiba companion on bottom right
$shibaPath = Join-Path (Get-Location) "assets\shiba_adult.png"
if (Test-Path $shibaPath) {
    $shibaImg = [System.Drawing.Image]::FromFile($shibaPath)
    $fgG.DrawImage($shibaImg, 820, 240, 180, 240)
    $shibaImg.Dispose()
}

$fgBitmap.Save((Join-Path $outDir "featureGraphic.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$fgG.Dispose()
$fgBitmap.Dispose()

Write-Host "1024x500 Feature Graphic generated successfully at $outDir\featureGraphic.png"

