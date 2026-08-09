<#
.SYNOPSIS
    Generate UI screenshots for GhostFix README
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$outputDir = Join-Path $PSScriptRoot "..\screenshots"
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

function New-Screenshot($title, $description, $rows, $filename) {
    $w = 920; $h = 580
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = "AntiAlias"
    $g.TextRenderingHint = "AntiAlias"

    # 背景
    $g.Clear([System.Drawing.Color]::White)

    # 标题栏
    $titleBar = New-Object System.Drawing.Rectangle(0, 0, $w, 30)
    $g.FillRectangle((New-Object System.Drawing.Drawing2D.LinearGradientBrush($titleBar, [System.Drawing.Color]::FromArgb(0,120,212), [System.Drawing.Color]::FromArgb(0,80,180), 0)), $titleBar)
    $g.DrawString($title, (New-Object System.Drawing.Font("Microsoft YaHei UI", 10, [System.Drawing.FontStyle]::Bold)), [System.Drawing.Brushes]::White, 12, 5)

    # 关闭按钮
    $g.FillRectangle([System.Drawing.Brushes]::White, $w-28, 6, 20, 20)
    $g.DrawString("X", (New-Object System.Drawing.Font("Microsoft YaHei UI", 9)), [System.Drawing.Brushes]::DarkRed, $w-24, 6)

    # 文件夹选择栏
    $y = 44
    $g.DrawString("Target Folder:", (New-Object System.Drawing.Font("Microsoft YaHei UI", 9)), [System.Drawing.Brushes]::Black, 15, $y+5)
    $g.FillRectangle([System.Drawing.Brushes]::White, 108, $y, 650, 26)
    $g.DrawRectangle([System.Drawing.Pens]::LightGray, 108, $y, 650, 26)
    $g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(52,152,219))), 768, $y, 130, 26)
    $g.DrawString("Browse...", (New-Object System.Drawing.Font("Microsoft YaHei UI", 9)), [System.Drawing.Brushes]::White, 785, $y+4)

    # 按钮栏
    $y = 84
    $btn1 = New-Object System.Drawing.Rectangle(10, $y, 160, 32)
    $btn2 = New-Object System.Drawing.Rectangle(178, $y, 160, 32)
    $btn3 = New-Object System.Drawing.Rectangle(346, $y, 110, 32)
    $g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(52,152,219))), $btn1)
    $g.DrawString("Scan Ghost Files", (New-Object System.Drawing.Font("Microsoft YaHei UI", 9, [System.Drawing.FontStyle]::Bold)), [System.Drawing.Brushes]::White, 25, $y+6)
    $g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(231,76,60))), $btn2)
    $g.DrawString("Fix All Ghosts", (New-Object System.Drawing.Font("Microsoft YaHei UI", 9, [System.Drawing.FontStyle]::Bold)), [System.Drawing.Brushes]::White, 193, $y+6)
    $g.FillRectangle([System.Drawing.Brushes]::White, $btn3)
    $g.DrawRectangle([System.Drawing.Pens]::LightGray, $btn3)
    $g.DrawString("Export Log", (New-Object System.Drawing.Font("Microsoft YaHei UI", 9)), [System.Drawing.Brushes]::Black, 358, $y+6)

    # 表格
    $gridY = 128
    $rowH = 28
    $colW = @(60, 140, 250, 250, 80, 120)
    $colX = @(10, 70, 210, 460, 710, 790)
    $headers = @("Status", "Directory", "Old Filename (NFD)", "New Filename (NFC)", "Size", "Error")

    # 表头
    $g.FillRectangle([System.Drawing.Brushes]::LightGray, 10, $gridY, $w-30, $rowH)
    for ($c = 0; $c -lt 6; $c++) {
        $g.DrawString($headers[$c], (New-Object System.Drawing.Font("Microsoft YaHei UI", 8, [System.Drawing.FontStyle]::Bold)), [System.Drawing.Brushes]::Black, $colX[$c], $gridY+4)
    }

    # 数据行
    for ($r = 0; $r -lt [Math]::Min($rows.Count, 10); $r++) {
        $ry = $gridY + ($r+1)*$rowH
        $bg = if ($r % 2 -eq 0) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::FromArgb(248,248,248) }
        $g.FillRectangle((New-Object System.Drawing.SolidBrush($bg)), 10, $ry, $w-30, $rowH)
        for ($c = 0; $c -lt 6; $c++) {
            $color = if ($c -eq 0) {
                if ($rows[$r][0] -like "*fixed*") { [System.Drawing.Color]::Green }
                elseif ($rows[$r][0] -like "*pending*") { [System.Drawing.Color]::DarkOrange }
                else { [System.Drawing.Color]::Red }
            } else { [System.Drawing.Color]::Black }
            $font = (New-Object System.Drawing.Font("Microsoft YaHei UI", 8))
            $g.DrawString($rows[$r][$c].Substring(0, [Math]::Min($rows[$r][$c].Length, 35)), $font, (New-Object System.Drawing.SolidBrush($color)), $colX[$c], $ry+4)
        }
    }

    # 底部统计
    $statY = $h - 56
    $g.DrawLine([System.Drawing.Pens]::LightGray, 10, $statY, $w-20, $statY)

    $totalRows = $rows.Count
    $fixed = ($rows | Where-Object { $_[0] -like "*fixed*" }).Count
    $g.DrawString("Total: $totalRows files | Ghosts: $totalRows | Fixed: $fixed | Failed: 0", (New-Object System.Drawing.Font("Microsoft YaHei UI", 9, [System.Drawing.FontStyle]::Bold)), [System.Drawing.Brushes]::Black, 15, $statY+8)

    # 状态栏
    $statY2 = $h - 24
    $g.FillRectangle([System.Drawing.Brushes]::WhiteSmoke, 0, $statY2, $w, 24)
    $g.DrawLine([System.Drawing.Pens]::LightGray, 0, $statY2, $w, $statY2)
    $g.DrawString($description, (New-Object System.Drawing.Font("Microsoft YaHei UI", 8)), [System.Drawing.Brushes]::Gray, 12, $statY2+3)

    # 保存
    $path = Join-Path $outputDir $filename
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    Write-Host "Saved: $filename"
}

# Screenshot 1: After scanning - ghosts found
$scanRows = @(
    @("⚠ pending", "18 classical", "Nocturn a Chloé.m4a", "Nocturn a Chloé.m4a", "11.2 MB", ""),
    @("⚠ pending", "17 Funky80", "真夜中のドア - 松原みき.mp3", "真夜中のドア - 松原みき.mp3", "12.1 MB", ""),
    @("⚠ pending", "17 Funky80", "モーニング・フライト.wav", "モーニング・フライト.wav", "42.4 MB", ""),
    @("⚠ pending", "12 Vapourwave", "Doki Doki no Disco 「ドキ...」.mp3", "Doki Doki no Disco 「ドキ...」.mp3", "8.7 MB", ""),
    @("⚠ pending", "18 classical", "François Couperin - Mystérieuses.m4a", "François Couperin - Mystérieuses.m4a", "4.5 MB", ""),
    @("⚠ pending", "8", "白金ディスコ - 神前暁.mp3", "白金ディスコ - 神前暁.mp3", "9.8 MB", ""),
    @("⚠ pending", "15", "丸の内サディスティック - 椎名林檎.mp3", "丸の内サディスティック - 椎名林檎.mp3", "9.0 MB", ""),
    @("⚠ pending", "14", "おどるポンポコリン.mp3", "おどるポンポコリン.mp3", "7.4 MB", "")
)
New-Screenshot "GhostFix - NFD to NFC Unicode Filename Repair Tool" "5 ghosts found - Click 'Fix All Ghosts' to repair" $scanRows "01_scan_result.png"

# Screenshot 2: After fix
$fixRows = @(
    @("✅ fixed", "18 classical", "Nocturn a Chloé.m4a", "Nocturn a Chloé.m4a", "11.2 MB", ""),
    @("✅ fixed", "17 Funky80", "真夜中のドア - 松原みき.mp3", "真夜中のドア - 松原みき.mp3", "12.1 MB", ""),
    @("✅ fixed", "17 Funky80", "モーニング・フライト.wav", "モーニング・フライト.wav", "42.4 MB", ""),
    @("✅ fixed", "12 Vapourwave", "Doki Doki no Disco 「ドキ...」.mp3", "Doki Doki no Disco 「ドキ...」.mp3", "8.7 MB", ""),
    @("✅ fixed", "18 classical", "François Couperin - Mystérieuses.m4a", "François Couperin - Mystérieuses.m4a", "4.5 MB", ""),
    @("✅ fixed", "8", "白金ディスコ - 神前暁.mp3", "白金ディスコ - 神前暁.mp3", "9.8 MB", ""),
    @("✅ fixed", "15", "丸の内サディスティック - 椎名林檎.mp3", "丸の内サディスティック - 椎名林檎.mp3", "9.0 MB", ""),
    @("✅ fixed", "14", "おどるポンポコリン.mp3", "おどるポンポコリン.mp3", "7.4 MB", "")
)
New-Screenshot "GhostFix - NFD to NFC Unicode Filename Repair Tool" "All fixed! 8 files repaired successfully" $fixRows "02_fix_complete.png"

Write-Host "Done! Screenshots saved to: $outputDir"
