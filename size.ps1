Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile("c:\Users\zupxy\Desktop\gpvault\gp-vault-main\assets\pets\puppy\corgi puppy trans running happily.webp")
Write-Host "$($img.Width)x$($img.Height)"
