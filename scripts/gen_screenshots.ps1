Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$dir = Join-Path $PSScriptRoot "..\screenshots"
New-Item -ItemType Directory -Path $dir -Force | Out-Null

function Render($title, $status, $rows, $file) {
    $w = 900; $h = 500
    $b = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($b)
    $g.Clear([System.Drawing.Color]::White)
    $f = New-Object System.Drawing.Font("Microsoft YaHei UI", 9)
    $fb = New-Object System.Drawing.Font("Microsoft YaHei UI", 9, [System.Drawing.FontStyle]::Bold)
    $fs = New-Object System.Drawing.Font("Consolas", 8)

    # Title
    $g.DrawString($title, $fb, [System.Drawing.Brushes]::Black, 12, 8)

    # Folder row
    $g.DrawString("Target Folder: J:\Music\AllTracks", $f, [System.Drawing.Brushes]::Black, 12, 35)

    # Buttons
    $g.DrawString("[ Scan Ghost Files ]", $fb, [System.Drawing.Brushes]::White, 12, 60)
    $g.FillRectangle([System.Drawing.Brushes]::DarkBlue, 10, 57, 160, 24)
    $g.DrawString("[ Scan Ghost Files ]", $fb, [System.Drawing.Brushes]::White, 15, 60)

    $g.FillRectangle([System.Drawing.Brushes]::DarkRed, 178, 57, 140, 24)
    $g.DrawString("[ Fix All Ghosts ]", $fb, [System.Drawing.Brushes]::White, 183, 60)

    # Grid header
    $gy = 95
    $hdr = @("Status", "Directory", "Old Filename (NFD)", "New Filename (NFC)", "Size")
    $hx = @(10, 70, 180, 400, 630)
    $hw = @(55, 105, 215, 225, 70)
    for ($i = 0; $i -lt 5; $i++) {
        $g.FillRectangle([System.Drawing.Brushes]::LightGray, $hx[$i], $gy, $hw[$i], 22)
        $g.DrawString($hdr[$i], $fb, [System.Drawing.Brushes]::Black, $hx[$i]+3, $gy+2)
    }

    # Rows
    for ($r = 0; $r -lt [Math]::Min($rows.Length, 8); $r++) {
        $ry = $gy + 24 + $r * 24
        $clr = if ($r % 2 -eq 0) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::FromArgb(245,245,245) }
        for ($c = 0; $c -lt 5; $c++) {
            $g.FillRectangle((New-Object System.Drawing.SolidBrush($clr)), $hx[$c], $ry, $hw[$c], 22)
            $sc = if ($c -eq 0) { if ($status -eq "fixed") { [System.Drawing.Color]::Green } else { [System.Drawing.Color]::DarkOrange } } else { [System.Drawing.Color]::Black }
            $val = if ($rows[$r][$c].Length -gt 30) { $rows[$r][$c].Substring(0, 28) + ".." } else { $rows[$r][$c] }
            $g.DrawString($val, $fs, (New-Object System.Drawing.SolidBrush($sc)), $hx[$c]+3, $ry+2)
        }
    }

    # Bottom stats
    $sy = $h - 50
    $g.DrawLine([System.Drawing.Pens]::Gray, 10, $sy, $w-20, $sy)
    $g.DrawString("Total: $($rows.Length) files | Ghosts: $($rows.Length) | Fixed: $(if($status -eq 'fixed'){$rows.Length}else{0}) | Failed: 0", $fb, [System.Drawing.Brushes]::Black, 12, $sy+4)
    $g.DrawString($title, $f, [System.Drawing.Brushes]::Gray, 12, $sy+24)

    $p = Join-Path $dir $file
    $b.Save($p, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $b.Dispose()
    Write-Host "Saved: $file"
}

# ---- Screenshot 1: Scan Result ----
$r1 = @(
    @("⚠ pending", "18 classical", "Nocturn a Chloé.m4a", "Nocturn a Chloé.m4a", "11.2 MB"),
    @("⚠ pending", "17 Funky80", "真夜中のドア - 松原みき.mp3", "真夜中のドア - 松原みき.mp3", "12.1 MB"),
    @("⚠ pending", "17 Funky80", "モーニング・フライト.wav", "モーニング・フライト.wav", "42.4 MB"),
    @("⚠ pending", "12 Vapourwave", "Doki Doki no Disco .mp3", "Doki Doki no Disco .mp3", "8.7 MB"),
    @("⚠ pending", "18 classical", "François Couperin - Myst.m4a", "François Couperin - Myst.m4a", "4.5 MB"),
    @("⚠ pending", "8", "白金ディスコ - 神前暁.mp3", "白金ディスコ - 神前暁.mp3", "9.8 MB"),
    @("⚠ pending", "14", "おどるポンポコリン.mp3", "おどるポンポコリン.mp3", "7.4 MB"),
    @("⚠ pending", "20", "それはスポットライトではない.mp3", "それはスポットライトではない.mp3", "9.8 MB")
)
Render "GhostFix v1.0 — Scan: 8 Ghost Files Detected" "pending" $r1 "01_scan_result.png"

# ---- Screenshot 2: Fix Complete ----
$r2 = @(
    @("✅ fixed", "18 classical", "Nocturn a Chloé.m4a", "Nocturn a Chloé.m4a", "11.2 MB"),
    @("✅ fixed", "17 Funky80", "真夜中のドア - 松原みき.mp3", "真夜中のドア - 松原みき.mp3", "12.1 MB"),
    @("✅ fixed", "17 Funky80", "モーニング・フライト.wav", "モーニング・フライト.wav", "42.4 MB"),
    @("✅ fixed", "12 Vapourwave", "Doki Doki no Disco .mp3", "Doki Doki no Disco .mp3", "8.7 MB"),
    @("✅ fixed", "18 classical", "François Couperin - Myst.m4a", "François Couperin - Myst.m4a", "4.5 MB"),
    @("✅ fixed", "8", "白金ディスコ - 神前暁.mp3", "白金ディスコ - 神前暁.mp3", "9.8 MB"),
    @("✅ fixed", "14", "おどるポンポコリン.mp3", "おどるポンポコリン.mp3", "7.4 MB"),
    @("✅ fixed", "20", "それはスポットライトではない.mp3", "それはスポットライトではない.mp3", "9.8 MB")
)
Render "GhostFix v1.0 — Fix Complete: 8/8 Repaired" "fixed" $r2 "02_fix_complete.png"

Write-Host "Done! Output: $dir"
