# Generate 1440x1440 square promo image (GDI+, ASCII-only source)
Add-Type -AssemblyName System.Drawing
$W = 1440; $H = 1440
$bmp = New-Object System.Drawing.Bitmap($W, $H)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'

# 1. night sky gradient (deep ink green)
$sky = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.Rectangle(0,0,$W,$H)),
    [System.Drawing.Color]::FromArgb(255,12,20,16),
    [System.Drawing.Color]::FromArgb(255,6,10,8),
    90)
$g.FillRectangle($sky, 0, 0, $W, $H)

# 2. soft radial mists
function Add-Mist($cx, $cy, $rad, $r, $gc, $b, $alpha) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p.AddEllipse($cx-$rad, $cy-$rad, $rad*2, $rad*2)
    $pg = New-Object System.Drawing.Drawing2D.PathGradientBrush($p)
    $pg.CenterColor = [System.Drawing.Color]::FromArgb($alpha, $r, $gc, $b)
    $pg.SurroundColors = @([System.Drawing.Color]::FromArgb(0,0,0,0))
    $script:g.FillPath($pg, $p)
    $p.Dispose(); $pg.Dispose()
}
Add-Mist 260 220 420 46 125 90 46
Add-Mist 1180 1180 520 190 140 40 36
Add-Mist 1000 260 380 40 90 120 26

# 3. moon (top right) with halo
Add-Mist 1130 260 260 240 230 170 60
$g.FillEllipse([System.Drawing.Brushes]::Ivory, 1085, 215, 90, 90)

# 4. layered mountains (bottom)
$mount1 = New-Object System.Drawing.Drawing2D.GraphicsPath
$mount1.AddPolygon(@([System.Drawing.PointF]::new(0,1290),[System.Drawing.PointF]::new(180,1100),[System.Drawing.PointF]::new(380,1260),[System.Drawing.PointF]::new(560,1080),[System.Drawing.PointF]::new(760,1250),[System.Drawing.PointF]::new(980,1050),[System.Drawing.PointF]::new(1200,1240),[System.Drawing.PointF]::new(1440,1120),[System.Drawing.PointF]::new(1440,1440),[System.Drawing.PointF]::new(0,1440)))
$mBrush1 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,10,18,14))
$g.FillPath($mBrush1, $mount1)
$mount2 = New-Object System.Drawing.Drawing2D.GraphicsPath
$mount2.AddPolygon(@([System.Drawing.PointF]::new(0,1380),[System.Drawing.PointF]::new(240,1230),[System.Drawing.PointF]::new(480,1360),[System.Drawing.PointF]::new(720,1200),[System.Drawing.PointF]::new(1000,1350),[System.Drawing.PointF]::new(1240,1210),[System.Drawing.PointF]::new(1440,1330),[System.Drawing.PointF]::new(1440,1440),[System.Drawing.PointF]::new(0,1440)))
$mBrush2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,6,11,9))
$g.FillPath($mBrush2, $mount2)
$mount1.Dispose(); $mount2.Dispose(); $mBrush1.Dispose(); $mBrush2.Dispose()

# 5. jade orb (center) with layered glow
Add-Mist 720 640 430 58 161 116 40
Add-Mist 720 640 300 58 161 116 70
$orbRect = New-Object System.Drawing.Rectangle(500, 420, 440, 440)
$orbPath = New-Object System.Drawing.Drawing2D.GraphicsPath
$orbPath.AddEllipse($orbRect)
$pgb = New-Object System.Drawing.Drawing2D.PathGradientBrush($orbPath)
$pgb.CenterColor = [System.Drawing.Color]::FromArgb(255,26,74,62)
$pgb.SurroundColors = @([System.Drawing.Color]::FromArgb(255,8,26,21))
$pgb.FocusScales = [System.Drawing.PointF]::new(0.55, 0.55)
$g.FillPath($pgb, $orbPath)
$orbPath.Dispose(); $pgb.Dispose()
# orb rim
$rim = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150,87,217,163), 3)
$g.DrawEllipse($rim, 500, 420, 440, 440)
$rim.Dispose()

# 6. gold orbit rings
$pen1 = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(90,212,175,55), 3)
$g.DrawEllipse($pen1, 460, 380, 520, 520)
$pen2 = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(50,212,175,55), 2)
$g.DrawEllipse($pen2, 415, 335, 610, 610)
$pen1.Dispose(); $pen2.Dispose()
# orbit highlight arcs
$penH = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(220,240,217,140), 5)
$g.DrawArc($penH, 460, 380, 520, 520, 300, 40)
$g.DrawArc($penH, 415, 335, 610, 610, 120, 22)
$penH.Dispose()

# 7. glyph Qi (U+7081) in gold gradient with glow
Add-Mist 720 640 170 240 217 140 90
$fmt = New-Object System.Drawing.StringFormat
$fmt.Alignment = 'Center'; $fmt.LineAlignment = 'Center'
$gx = 720; $gy = 640
$glyphRect = New-Object System.Drawing.RectangleF(($gx-160), ($gy-165), 320, 330)
$glowText = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(70,212,175,55))
$bigFont = New-Object System.Drawing.Font('KaiTi', 210, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$glowRect = New-Object System.Drawing.RectangleF(($gx-175), ($gy-180), 350, 360)
$g.DrawString([string][char]0x7081, $bigFont, $glowText, $glowRect, $fmt)
$goldGrad = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.Rectangle(560,480,320,320)),
    [System.Drawing.Color]::FromArgb(255,244,226,158),
    [System.Drawing.Color]::FromArgb(255,196,152,52),
    90)
$g.DrawString([string][char]0x7081, $bigFont, $goldGrad, $glyphRect, $fmt)
$bigFont.Dispose(); $goldGrad.Dispose(); $glowText.Dispose(); $fmt.Dispose()

# 8. floating light dots
$rand = New-Object System.Random(42)
for ($i=0; $i -lt 46; $i++) {
    $x = $rand.Next(40, $W-40); $y = $rand.Next(60, $H-80)
    $sz = $rand.Next(2, 6); $al = $rand.Next(40, 170)
    $dot = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($al,240,217,140))
    $g.FillEllipse($dot, $x, $y, $sz, $sz)
    $dot.Dispose()
}

# 9. title LingXuXiuXianLu (matches 16:9 promo style)
$titleFam = New-Object System.Drawing.FontFamily('KaiTi')
$titleFmt = New-Object System.Drawing.StringFormat
$titleFmt.Alignment = 'Center'; $titleFmt.LineAlignment = 'Center'
$titleRect = New-Object System.Drawing.RectangleF(120, 1030, 1200, 220)
$tpath = New-Object System.Drawing.Drawing2D.GraphicsPath
$tpath.AddString('灵墟修仙录', $titleFam, 1, 150, $titleRect, $titleFmt)
# soft glow behind title
$g.DrawPath((New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(60,212,175,55), 14)), $tpath)
# dark brown stroke
$g.DrawPath((New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255,60,40,12), 6)), $tpath)
# gold gradient fill
$tGold = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.Rectangle(240,1030,960,220)),
    [System.Drawing.Color]::FromArgb(255,248,232,168),
    [System.Drawing.Color]::FromArgb(255,202,156,56),
    90)
$g.FillPath($tGold, $tpath)
$tpath.Dispose(); $tGold.Dispose(); $titleFmt.Dispose(); $titleFam.Dispose()

# 10. inner frame line
$frame = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(70,212,175,55), 2)
$g.DrawRectangle($frame, 24, 24, $W-48, $H-48)
$frame.Dispose()

$g.Dispose()
$out = 'd:\demogame1\demo1\taptap\square_promo.png'
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host "saved: $out"
Write-Host ((Get-Item $out).Length)
