<#
.SYNOPSIS
    Generate UI screenshots for the GhostFix README | 为 GhostFix README 生成界面截图
.DESCRIPTION
    Renders a bilingual (EN/ZH) mock of the GhostFix main window and saves two
    PNG screenshots (scan result / fix complete) into ../screenshots.
    渲染 GhostFix 主窗口的双语（英/中）模拟界面，并将两张 PNG 截图
    （扫描结果 / 修复完成）保存到 ../screenshots。
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$outputDir = Join-Path $PSScriptRoot "..\screenshots"
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

# Draw text via TextRenderer (GDI) so emoji/CJK fall back correctly | 用 TextRenderer (GDI) 绘制文本，确保 emoji/中日韩字符正确回退
function Draw-Txt($g, $text, $font, $x, $y, $fg, $bg) {
    $pt = New-Object System.Drawing.Point($x, $y)
    if ($bg) {
        [System.Windows.Forms.TextRenderer]::DrawText($g, $text, $font, $pt, $fg, $bg)
    } else {
        [System.Windows.Forms.TextRenderer]::DrawText($g, $text, $font, $pt, $fg)
    }
}

function New-Screenshot($title, $description, $rows, $filename) {
    $w = 920; $h = 580
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = "AntiAlias"
    $g.TextRenderingHint = "AntiAlias"

    # Background | 背景
    $g.Clear([System.Drawing.Color]::White)

    # Title bar | 标题栏
    $titleBar = New-Object System.Drawing.Rectangle(0, 0, $w, 30)
    $g.FillRectangle((New-Object System.Drawing.Drawing2D.LinearGradientBrush($titleBar, [System.Drawing.Color]::FromArgb(0,120,212), [System.Drawing.Color]::FromArgb(0,80,180), 0)), $titleBar)
    $g.DrawString($title, (New-Object System.Drawing.Font("Microsoft YaHei UI", 10, [System.Drawing.FontStyle]::Bold)), [System.Drawing.Brushes]::White, 12, 5)

    # Close button | 关闭按钮
    $g.FillRectangle([System.Drawing.Brushes]::White, $w-28, 6, 20, 20)
    $g.DrawString("X", (New-Object System.Drawing.Font("Microsoft YaHei UI", 9)), [System.Drawing.Brushes]::DarkRed, $w-24, 6)

    # Folder selection row | 文件夹选择栏
    $y = 44
    $g.DrawString("Target Folder: 目标文件夹:", (New-Object System.Drawing.Font("Microsoft YaHei UI", 9)), [System.Drawing.Brushes]::Black, 15, $y+5)
    $g.FillRectangle([System.Drawing.Brushes]::White, 195, $y, 560, 26)
    $g.DrawRectangle([System.Drawing.Pens]::LightGray, 195, $y, 560, 26)
    $g.DrawString("J:\Music\AllTracks", (New-Object System.Drawing.Font("Microsoft YaHei UI", 9)), [System.Drawing.Brushes]::Black, 200, $y+5)
    $g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(52,152,219))), 768, $y, 140, 26)
    Draw-Txt $g "📂 Browse... 浏览..." (New-Object System.Drawing.Font("Microsoft YaHei UI", 9)) 780 ($y+5) ([System.Drawing.Color]::White) ([System.Drawing.Color]::FromArgb(52,152,219))

    # Button bar | 按钮栏
    $y = 84
    $btn1 = New-Object System.Drawing.Rectangle(10, $y, 200, 32)
    $btn2 = New-Object System.Drawing.Rectangle(220, $y, 160, 32)
    $btn3 = New-Object System.Drawing.Rectangle(390, $y, 150, 32)
    $g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(52,152,219))), $btn1)
    Draw-Txt $g "🔍 Scan Ghosts 扫描幽灵文件" (New-Object System.Drawing.Font("Microsoft YaHei UI", 9, [System.Drawing.FontStyle]::Bold)) 25 ($y+7) ([System.Drawing.Color]::White) ([System.Drawing.Color]::FromArgb(52,152,219))
    $g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(231,76,60))), $btn2)
    Draw-Txt $g "🔧 Fix All 修复全部幽灵" (New-Object System.Drawing.Font("Microsoft YaHei UI", 9, [System.Drawing.FontStyle]::Bold)) 238 ($y+7) ([System.Drawing.Color]::White) ([System.Drawing.Color]::FromArgb(231,76,60))
    $g.FillRectangle([System.Drawing.Brushes]::White, $btn3)
    $g.DrawRectangle([System.Drawing.Pens]::LightGray, $btn3)
    Draw-Txt $g "📋 Export Log 导出日志" (New-Object System.Drawing.Font("Microsoft YaHei UI", 9)) 402 ($y+7) ([System.Drawing.Color]::Black) ([System.Drawing.Color]::White)

    # Table | 表格
    $gridY = 128
    $rowH = 28
    $colW = @(100, 120, 230, 230, 70, 130)
    $colX = @(10, 110, 230, 460, 690, 760)
    $headers = @("Status 状态", "Directory 子目录", "Original Name (NFD) 原文件名", "Fixed Name (NFC) 修复后", "Size 大小", "Error 错误信息")

    # Header row | 表头
    $g.FillRectangle([System.Drawing.Brushes]::LightGray, 10, $gridY, $w-30, $rowH)
    for ($c = 0; $c -lt 6; $c++) {
        $g.DrawString($headers[$c], (New-Object System.Drawing.Font("Microsoft YaHei UI", 8, [System.Drawing.FontStyle]::Bold)), [System.Drawing.Brushes]::Black, $colX[$c], $gridY+4)
    }

    # Data rows | 数据行
    for ($r = 0; $r -lt [Math]::Min($rows.Count, 10); $r++) {
        $ry = $gridY + ($r+1)*$rowH
        $bg = if ($r % 2 -eq 0) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::FromArgb(248,248,248) }
        $g.FillRectangle((New-Object System.Drawing.SolidBrush($bg)), 10, $ry, $w-30, $rowH)
        for ($c = 0; $c -lt 6; $c++) {
            $color = if ($c -eq 0) {
                if ($rows[$r][0] -like "*Fixed*") { [System.Drawing.Color]::Green }
                elseif ($rows[$r][0] -like "*Pending*") { [System.Drawing.Color]::DarkOrange }
                else { [System.Drawing.Color]::Red }
            } else { [System.Drawing.Color]::Black }
            $font = (New-Object System.Drawing.Font("Microsoft YaHei UI", 8))
            $val = $rows[$r][$c].Substring(0, [Math]::Min($rows[$r][$c].Length, 35))
            if ($c -eq 0) {
                # Status column contains emoji — draw via TextRenderer | 状态列含 emoji — 用 TextRenderer 绘制
                Draw-Txt $g $val $font ($colX[$c]+2) ($ry+6) $color $null
            } else {
                $g.DrawString($val, $font, (New-Object System.Drawing.SolidBrush($color)), $colX[$c], $ry+4)
            }
        }
    }

    # Bottom stats | 底部统计
    $statY = $h - 56
    $g.DrawLine([System.Drawing.Pens]::LightGray, 10, $statY, $w-20, $statY)

    $totalRows = $rows.Count
    $fixed = ($rows | Where-Object { $_[0] -like "*Fixed*" }).Count
    $g.DrawString("Total 总计: $totalRows files 文件 | Ghosts 幽灵: $totalRows | Fixed 已修复: $fixed | Failed 失败: 0", (New-Object System.Drawing.Font("Microsoft YaHei UI", 9, [System.Drawing.FontStyle]::Bold)), [System.Drawing.Brushes]::Black, 15, $statY+8)

    # Status bar | 状态栏
    $statY2 = $h - 24
    $g.FillRectangle([System.Drawing.Brushes]::WhiteSmoke, 0, $statY2, $w, 24)
    $g.DrawLine([System.Drawing.Pens]::LightGray, 0, $statY2, $w, $statY2)
    Draw-Txt $g $description (New-Object System.Drawing.Font("Microsoft YaHei UI", 8)) 12 ($statY2+4) ([System.Drawing.Color]::Gray) ([System.Drawing.Color]::WhiteSmoke)

    # Save | 保存
    $path = Join-Path $outputDir $filename
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    Write-Host "Saved: $filename"
}

# Screenshot 1: After scanning — ghosts found | 截图一：扫描后 — 发现幽灵文件
$scanRows = @(
    @("⚠ Pending 待修复", "18 classical", "Nocturn a Chloé.m4a", "Nocturn a Chloé.m4a", "11.2 MB", ""),
    @("⚠ Pending 待修复", "17 Funky80", "真夜中のドア - 松原みき.mp3", "真夜中のドア - 松原みき.mp3", "12.1 MB", ""),
    @("⚠ Pending 待修复", "17 Funky80", "モーニング・フライト.wav", "モーニング・フライト.wav", "42.4 MB", ""),
    @("⚠ Pending 待修复", "12 Vapourwave", "Doki Doki no Disco 「ドキ...」.mp3", "Doki Doki no Disco 「ドキ...」.mp3", "8.7 MB", ""),
    @("⚠ Pending 待修复", "18 classical", "François Couperin - Mystérieuses.m4a", "François Couperin - Mystérieuses.m4a", "4.5 MB", ""),
    @("⚠ Pending 待修复", "8", "白金ディスコ - 神前暁.mp3", "白金ディスコ - 神前暁.mp3", "9.8 MB", ""),
    @("⚠ Pending 待修复", "15", "丸の内サディスティック - 椎名林檎.mp3", "丸の内サディスティック - 椎名林檎.mp3", "9.0 MB", ""),
    @("⚠ Pending 待修复", "14", "おどるポンポコリン.mp3", "おどるポンポコリン.mp3", "7.4 MB", "")
)
New-Screenshot "GhostFix — NFD→NFC Unicode Filename Repair Tool | 文件名修复工具 v1.0" "✅ Scan complete — 8 ghost file(s) found; click 'Fix All' to repair | ✅ 扫描完成 — 发现 8 个幽灵文件，点击「修复全部幽灵」进行修复" $scanRows "01_scan_result.png"

# Screenshot 2: After fix | 截图二：修复后
$fixRows = @(
    @("✅ Fixed 已修复", "18 classical", "Nocturn a Chloé.m4a", "Nocturn a Chloé.m4a", "11.2 MB", ""),
    @("✅ Fixed 已修复", "17 Funky80", "真夜中のドア - 松原みき.mp3", "真夜中のドア - 松原みき.mp3", "12.1 MB", ""),
    @("✅ Fixed 已修复", "17 Funky80", "モーニング・フライト.wav", "モーニング・フライト.wav", "42.4 MB", ""),
    @("✅ Fixed 已修复", "12 Vapourwave", "Doki Doki no Disco 「ドキ...」.mp3", "Doki Doki no Disco 「ドキ...」.mp3", "8.7 MB", ""),
    @("✅ Fixed 已修复", "18 classical", "François Couperin - Mystérieuses.m4a", "François Couperin - Mystérieuses.m4a", "4.5 MB", ""),
    @("✅ Fixed 已修复", "8", "白金ディスコ - 神前暁.mp3", "白金ディスコ - 神前暁.mp3", "9.8 MB", ""),
    @("✅ Fixed 已修复", "15", "丸の内サディスティック - 椎名林檎.mp3", "丸の内サディスティック - 椎名林檎.mp3", "9.0 MB", ""),
    @("✅ Fixed 已修复", "14", "おどるポンポコリン.mp3", "おどるポンポコリン.mp3", "7.4 MB", "")
)
New-Screenshot "GhostFix — NFD→NFC Unicode Filename Repair Tool | 文件名修复工具 v1.0" "🎉 All fixed! 8 file(s) renamed to NFC form. | 🎉 全部修复成功！8 个文件已重命名为 NFC 规范化形式。" $fixRows "02_fix_complete.png"

Write-Host "Done! Screenshots saved to: $outputDir | 完成！截图已保存到: $outputDir"
