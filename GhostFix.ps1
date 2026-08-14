<#
.SYNOPSIS
    GhostFix — NFD→NFC Unicode filename repair tool | NFD→NFC Unicode 文件名修复工具
.DESCRIPTION
    Recursively scans the specified folder, detects and repairs NFD (decomposed)
    Unicode filename encoding issues caused by the Tuxera NTFS driver, normalizing
    filenames to NFC (composed) form so that files are accessible on macOS again.
    递归扫描指定文件夹，检测并修复因 Tuxera NTFS 驱动导致的
    NFD (分解形式) Unicode 文件名编码问题，将文件名规范化为
    NFC (预组合形式)，使文件在 macOS 上可正常访问。
.AUTHOR
    GhostFix
.VERSION
    1.0.0
#>

# ============================================================
# Load WinForms assemblies | 加载 WinForms 程序集
# ============================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================================
# Core logic functions | 核心逻辑函数
# ============================================================

function Test-NFDName {
    <#
    .SYNOPSIS
        Detect whether a filename is in NFD (decomposed) Unicode form | 检测文件名是否为 NFD (分解) Unicode 形式
    .PARAMETER FileName
        The filename to test (without path) | 要检测的文件名（不含路径）
    .OUTPUTS
        Boolean — $true means the filename is in NFD form and needs repair | Boolean — $true 表示文件名为 NFD 形式，需要修复
    #>
    param([string]$FileName)

    $nfc = $FileName.Normalize([System.Text.NormalizationForm]::FormC)

    # Ordinal-compare the filename against its NFC-normalized form | 将文件名与其 NFC 规范化形式做 Ordinal 比较
    # Different → the filename is currently NFD (decomposed) → needs repair | 不同 → 文件名当前为 NFD（分解）形式 → 需要修复
    # Equal     → the filename is already NFC (composed)   → no repair needed | 相同 → 文件名已是 NFC（预组合）形式 → 无需修复
    return (-not [string]::Equals($FileName, $nfc, [StringComparison]::Ordinal))
}

function Get-NFCName {
    <#
    .SYNOPSIS
        Normalize a filename to NFC form | 将文件名规范化为 NFC 形式
    #>
    param([string]$FileName)
    return $FileName.Normalize([System.Text.NormalizationForm]::FormC)
}

# ============================================================
# Global variables | 全局变量
# ============================================================
$script:ScanResults = New-Object System.Collections.Generic.List[PSObject]
$script:SelectedFolder = ""

# ============================================================
# Build the UI | 构建 UI
# ============================================================

$form = New-Object System.Windows.Forms.Form
$form.Text = "GhostFix — NFD→NFC Unicode Filename Repair Tool | 文件名修复工具 v1.0"
$form.Size = New-Object System.Drawing.Size(1050, 680)
$form.StartPosition = "CenterScreen"
$form.MinimumSize = New-Object System.Drawing.Size(850, 550)
$form.Icon = $null
$form.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9)

# ============================================================
# Menu bar | 菜单栏
# ============================================================
$menuStrip = New-Object System.Windows.Forms.MenuStrip

$menuFile = New-Object System.Windows.Forms.ToolStripMenuItem("File 文件(&F)")
$menuExit = New-Object System.Windows.Forms.ToolStripMenuItem("Exit 退出(&X)")
$menuExit.Add_Click({ $form.Close() })
$menuFile.DropDownItems.Add($menuExit)

$menuHelp = New-Object System.Windows.Forms.ToolStripMenuItem("Help 帮助(&H)")
$menuAbout = New-Object System.Windows.Forms.ToolStripMenuItem("About 关于(&A)")
$menuAbout.Add_Click({
    $aboutText = "GhostFix v1.0.0`nNFD→NFC Unicode Filename Repair Tool | 文件名修复工具`n`nPurpose:`n  Recursively scan all files in a folder, detect and`n  repair NFD (decomposed) Unicode filenames.`n用途:`n  递归扫描文件夹中的全部文件，检测并修复`n  NFD (分解形式) Unicode 编码的文件名。`n`nUse case:`n  Ghost-file problems on macOS caused by the Tuxera`n  NTFS driver (directory entry exists but is unreachable).`n适用场景:`n  因 Tuxera NTFS 驱动在 macOS 上导致的`n  幽灵文件问题（目录项存在但无法访问）。`n`nTechniques:`n  · NFD detection via Ordinal comparison`n  · NFC normalization (FormC) repair`n  · Atomic Rename-Item operation, content unchanged`n技术:`n  · 使用 Ordinal 比较检测 NFD 文件名`n  · NFC 规范化 (FormC) 修复`n  · 原子 Rename-Item 操作，文件内容不变"
    [System.Windows.Forms.MessageBox]::Show($aboutText, "About GhostFix | 关于 GhostFix", "OK", "Information")
})

$menuGuide = New-Object System.Windows.Forms.ToolStripMenuItem("User Guide 用户文档(&G)")
$menuGuide.Add_Click({
    $docPath = Join-Path $PSScriptRoot "用户文档.md"
    if (Test-Path $docPath) {
        Start-Process $docPath
    } else {
        [System.Windows.Forms.MessageBox]::Show("User guide file not found.`n未找到用户文档文件。", "Notice | 提示", "OK", "Information")
    }
})

$menuHelp.DropDownItems.Add($menuGuide)
$menuHelp.DropDownItems.Add($menuAbout)

$menuStrip.Items.Add($menuFile) | Out-Null
$menuStrip.Items.Add($menuHelp) | Out-Null
$form.MainMenuStrip = $menuStrip
$form.Controls.Add($menuStrip)

# ============================================================
# Top panel — folder selection | 顶部面板 — 文件夹选择
# ============================================================
$panelTop = New-Object System.Windows.Forms.Panel
$panelTop.Location = New-Object System.Drawing.Point(12, 30)
$panelTop.Size = New-Object System.Drawing.Size(1010, 45)
$panelTop.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

$lblFolder = New-Object System.Windows.Forms.Label
$lblFolder.Text = "Target Folder: 目标文件夹:"
$lblFolder.Location = New-Object System.Drawing.Point(5, 14)
$lblFolder.Size = New-Object System.Drawing.Size(150, 23)
$lblFolder.TextAlign = "MiddleLeft"

$txtFolder = New-Object System.Windows.Forms.TextBox
$txtFolder.Location = New-Object System.Drawing.Point(160, 12)
$txtFolder.Size = New-Object System.Drawing.Size(700, 23)
$txtFolder.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$txtFolder.Text = ""
$txtFolder.Add_TextChanged({
    $script:SelectedFolder = $txtFolder.Text
})

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "📂 Browse... 浏览..."
$btnBrowse.Location = New-Object System.Drawing.Point(870, 10)
$btnBrowse.Size = New-Object System.Drawing.Size(140, 28)
$btnBrowse.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$btnBrowse.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Select the folder to scan | 选择要扫描的文件夹"
    $dialog.ShowNewFolderButton = $false
    if ($dialog.ShowDialog() -eq "OK") {
        $txtFolder.Text = $dialog.SelectedPath
        $script:SelectedFolder = $dialog.SelectedPath
    }
})

$panelTop.Controls.Add($lblFolder)
$panelTop.Controls.Add($txtFolder)
$panelTop.Controls.Add($btnBrowse)
$form.Controls.Add($panelTop)

# ============================================================
# Action button bar | 操作按钮栏
# ============================================================
$panelButtons = New-Object System.Windows.Forms.Panel
$panelButtons.Location = New-Object System.Drawing.Point(12, 80)
$panelButtons.Size = New-Object System.Drawing.Size(1010, 35)
$panelButtons.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

$btnScan = New-Object System.Windows.Forms.Button
$btnScan.Text = "🔍 Scan Ghosts 扫描幽灵文件"
$btnScan.Location = New-Object System.Drawing.Point(5, 2)
$btnScan.Size = New-Object System.Drawing.Size(200, 30)
$btnScan.BackColor = [System.Drawing.Color]::FromArgb(52, 152, 219)
$btnScan.ForeColor = [System.Drawing.Color]::White
$btnScan.FlatStyle = "Flat"
$btnScan.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9, [System.Drawing.FontStyle]::Bold)
$btnScan.Add_Click({ Start-Scan })

$btnFix = New-Object System.Windows.Forms.Button
$btnFix.Text = "🔧 Fix All 修复全部幽灵"
$btnFix.Location = New-Object System.Drawing.Point(215, 2)
$btnFix.Size = New-Object System.Drawing.Size(160, 30)
$btnFix.BackColor = [System.Drawing.Color]::FromArgb(231, 76, 60)
$btnFix.ForeColor = [System.Drawing.Color]::White
$btnFix.FlatStyle = "Flat"
$btnFix.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9, [System.Drawing.FontStyle]::Bold)
$btnFix.Enabled = $false
$btnFix.Add_Click({ Start-Fix })

$btnExport = New-Object System.Windows.Forms.Button
$btnExport.Text = "📋 Export Log 导出日志"
$btnExport.Location = New-Object System.Drawing.Point(385, 2)
$btnExport.Size = New-Object System.Drawing.Size(150, 30)
$btnExport.Enabled = $false
$btnExport.Add_Click({ Export-Log })

$btnClear = New-Object System.Windows.Forms.Button
$btnClear.Text = "🗑 Clear 清空结果"
$btnClear.Location = New-Object System.Drawing.Point(545, 2)
$btnClear.Size = New-Object System.Drawing.Size(120, 30)
$btnClear.Add_Click({
    $script:ScanResults.Clear()
    $dataGrid.DataSource = $null
    $btnFix.Enabled = $false
    $btnExport.Enabled = $false
    Update-Stats
})

$panelButtons.Controls.Add($btnScan)
$panelButtons.Controls.Add($btnFix)
$panelButtons.Controls.Add($btnExport)
$panelButtons.Controls.Add($btnClear)
$form.Controls.Add($panelButtons)

# ============================================================
# DataGridView — results table | 结果表格
# ============================================================
$dataGrid = New-Object System.Windows.Forms.DataGridView
$dataGrid.Location = New-Object System.Drawing.Point(12, 120)
$dataGrid.Size = New-Object System.Drawing.Size(1010, 410)
$dataGrid.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$dataGrid.AllowUserToAddRows = $false
$dataGrid.AllowUserToDeleteRows = $false
$dataGrid.ReadOnly = $true
$dataGrid.AutoSizeColumnsMode = "None"
$dataGrid.SelectionMode = "FullRowSelect"
$dataGrid.MultiSelect = $true
$dataGrid.RowHeadersVisible = $false
$dataGrid.BackgroundColor = [System.Drawing.Color]::White
$dataGrid.GridColor = [System.Drawing.Color]::FromArgb(230, 230, 230)
$dataGrid.AlternatingRowsDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(248, 248, 248)

# Define columns | 定义列
$colStatus = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colStatus.Name = "Status"
$colStatus.HeaderText = "Status 状态"
$colStatus.Width = 115
$colStatus.DefaultCellStyle.Alignment = "MiddleCenter"

$colDir = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colDir.Name = "Directory"
$colDir.HeaderText = "Directory 子目录"
$colDir.Width = 160

$colOldName = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colOldName.Name = "OldName"
$colOldName.HeaderText = "Original Name (NFD) 原文件名"
$colOldName.Width = 260

$colNewName = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colNewName.Name = "NewName"
$colNewName.HeaderText = "Fixed Name (NFC) 修复后"
$colNewName.Width = 260

$colSize = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colSize.Name = "Size"
$colSize.HeaderText = "Size 大小"
$colSize.Width = 80
$colSize.DefaultCellStyle.Alignment = "MiddleRight"

$colError = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colError.Name = "Error"
$colError.HeaderText = "Error 错误信息"
$colError.Width = 135

$dataGrid.Columns.AddRange([System.Windows.Forms.DataGridViewColumn[]]($colStatus, $colDir, $colOldName, $colNewName, $colSize, $colError))

# Bind the data source | 绑定数据源
$bindingList = New-Object System.ComponentModel.BindingList[PSObject](@())
$bindingSource = New-Object System.Windows.Forms.BindingSource
$bindingSource.DataSource = $bindingList
$dataGrid.DataSource = $bindingSource

$form.Controls.Add($dataGrid)

# ============================================================
# Bottom panel — stats + progress + status | 底部面板 — 统计 + 进度条 + 状态
# ============================================================
$panelBottom = New-Object System.Windows.Forms.Panel
$panelBottom.Location = New-Object System.Drawing.Point(12, 535)
$panelBottom.Size = New-Object System.Drawing.Size(1010, 55)
$panelBottom.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

# Stats label | 统计标签
$lblStats = New-Object System.Windows.Forms.Label
$lblStats.Text = "Total 总计: 0 files 文件  |  Ghosts 幽灵: 0  |  Fixed 已修复: 0  |  Failed 失败: 0"
$lblStats.Location = New-Object System.Drawing.Point(5, 0)
$lblStats.Size = New-Object System.Drawing.Size(900, 20)
$lblStats.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9, [System.Drawing.FontStyle]::Bold)

# Progress bar | 进度条
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(5, 22)
$progressBar.Size = New-Object System.Drawing.Size(800, 22)
$progressBar.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$progressBar.Style = "Continuous"
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0

# Status bar text | 状态栏文字
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Ready — please select a target folder and click Scan | 就绪 — 请选择目标文件夹并点击扫描"
$lblStatus.Location = New-Object System.Drawing.Point(5, 45)
$lblStatus.Size = New-Object System.Drawing.Size(1000, 15)
$lblStatus.ForeColor = [System.Drawing.Color]::Gray

$panelBottom.Controls.Add($lblStats)
$panelBottom.Controls.Add($progressBar)
$panelBottom.Controls.Add($lblStatus)
$form.Controls.Add($panelBottom)

# ============================================================
# Update the stats display | 更新统计显示
# ============================================================
function Update-Stats {
    $total = $script:ScanResults.Count
    $ghost = ($script:ScanResults | Where-Object { $_.IsGhost }).Count
    $fixed = ($script:ScanResults | Where-Object { $_.Status -eq "✅ Fixed 已修复" }).Count
    $failed = ($script:ScanResults | Where-Object { $_.Status -eq "❌ Failed 失败" }).Count

    $lblStats.Text = "Total 总计: $total files 文件  |  Ghosts 幽灵: $ghost  |  Fixed 已修复: $fixed  |  Failed 失败: $failed"
}

# ============================================================
# Show progress | 显示进度
# ============================================================
function Set-Progress {
    param([int]$Value, [string]$StatusText)
    $progressBar.Value = [Math]::Min(100, [Math]::Max(0, $Value))
    if ($StatusText) {
        $lblStatus.Text = $StatusText
    }
    [System.Windows.Forms.Application]::DoEvents()
}

# ============================================================
# Scan feature | 扫描功能
# ============================================================
function Start-Scan {
    $folder = $script:SelectedFolder

    if (-not $folder) {
        [System.Windows.Forms.MessageBox]::Show("Please select a target folder first.`n请先选择目标文件夹。", "Notice | 提示", "OK", "Warning")
        return
    }

    if (-not (Test-Path -LiteralPath $folder)) {
        [System.Windows.Forms.MessageBox]::Show("The selected folder does not exist.`n所选文件夹不存在。`n$folder", "Error | 错误", "OK", "Error")
        return
    }

    # Reset | 重置
    $script:ScanResults.Clear()
    $dataGrid.DataSource = $null
    $bindingList.Clear()
    $btnScan.Enabled = $false
    $btnFix.Enabled = $false
    $btnExport.Enabled = $false
    $lblStatus.Text = "Scanning... | 正在扫描..."
    Set-Progress 0

    try {
        # Recursively get all files | 递归获取所有文件
        $allFiles = @(Get-ChildItem -LiteralPath $folder -File -Recurse -ErrorAction SilentlyContinue)
        $totalCount = $allFiles.Count
        $ghostCount = 0
        $processedCount = 0

        Set-Progress 0 "Scanning... $totalCount files found | 扫描中... 发现 $totalCount 个文件"

        foreach ($file in $allFiles) {
            $processedCount++

            # Update progress | 更新进度
            if ($processedCount % 50 -eq 0 -or $processedCount -eq $totalCount) {
                $pct = [math]::Floor($processedCount / $totalCount * 100)
                Set-Progress $pct "Scanning $processedCount / $totalCount ... | 正在扫描 $processedCount / $totalCount ..."
            }

            $fileName = $file.Name
            $isGhost = Test-NFDName -FileName $fileName

            if ($isGhost) {
                $ghostCount++
                $nfcName = Get-NFCName -FileName $fileName
                $relDir = ""
                try {
                    $relDir = $file.DirectoryName.Substring($folder.Length).TrimStart('\')
                } catch {}

                $sizeDisplay = Format-FileSize -Bytes $file.Length

                $row = [PSCustomObject]@{
                    Status      = "⚠️ Pending 待修复"
                    Directory   = $relDir
                    OldName     = $fileName
                    NewName     = $nfcName
                    Size        = $sizeDisplay
                    Error       = ""
                    IsGhost     = $true
                    FullPath    = $file.FullName
                    SizeBytes   = $file.Length
                }

                $script:ScanResults.Add($row)
                $bindingList.Add($row)
            }
        }

        # Refresh the table | 刷新表格
        $dataGrid.DataSource = $bindingSource
        $dataGrid.Refresh()

        # Update status | 更新状态
        Set-Progress 100 "Scan complete: $totalCount files scanned, $ghostCount ghost file(s) found | 扫描完成: 共 $totalCount 个文件，发现 $ghostCount 个幽灵文件"

        if ($ghostCount -gt 0) {
            $btnFix.Enabled = $true
            $btnExport.Enabled = $true
            $lblStatus.Text = "✅ Scan complete — $ghostCount ghost file(s) found; click 'Fix All' to repair | ✅ 扫描完成 — 发现 $ghostCount 个幽灵文件，点击「修复全部幽灵」进行修复"
            $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(192, 57, 43)
        } else {
            $btnFix.Enabled = $false
            $btnExport.Enabled = $true
            $lblStatus.Text = "✅ Scan complete — no ghost files found, nothing to fix | ✅ 扫描完成 — 未发现幽灵文件，无需修复"
            $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(39, 174, 96)
        }

        Update-Stats

    } catch {
        Set-Progress 0
        $lblStatus.Text = "Scan error: $($_.Exception.Message) | 扫描出错: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show("An error occurred during scanning:`n扫描过程中发生错误:`n$($_.Exception.Message)", "Error | 错误", "OK", "Error")
    } finally {
        $btnScan.Enabled = $true
    }
}

# ============================================================
# Fix feature | 修复功能
# ============================================================
function Start-Fix {
    $ghostItems = @($script:ScanResults | Where-Object { $_.Status -eq "⚠️ Pending 待修复" })

    if ($ghostItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No ghost files pending repair.`n没有待修复的幽灵文件。", "Notice | 提示", "OK", "Information")
        return
    }

    $confirmMsg = "About to fix $($ghostItems.Count) ghost file(s).`n`nThis operation only renames files (NFD→NFC); file content is never modified.`n`nContinue?`n`n即将修复 $($ghostItems.Count) 个幽灵文件。`n`n此操作仅重命名文件（NFD→NFC），不修改文件内容。`n`n是否继续？"
    $result = [System.Windows.Forms.MessageBox]::Show($confirmMsg, "Confirm Fix | 确认修复", "YesNo", "Question")
    if ($result -ne "Yes") { return }

    $btnScan.Enabled = $false
    $btnFix.Enabled = $false
    $btnExport.Enabled = $false

    $total = $ghostItems.Count
    $success = 0
    $fail = 0
    $processed = 0

    Set-Progress 0 "Fixing 0 / $total ... | 正在修复 0 / $total ..."

    foreach ($item in $ghostItems) {
        try {
            $newName = $item.NewName

            # Check whether it is already NFC | 检查是否已经是 NFC
            if ([string]::Equals($item.OldName, $newName, [StringComparison]::Ordinal)) {
                $item.Status = "✅ Fixed 已修复"
                $success++
                $processed++
                continue
            }

            Rename-Item -LiteralPath $item.FullPath -NewName $newName -ErrorAction Stop

            # Update the file path | 更新文件路径
            $parentDir = Split-Path $item.FullPath -Parent
            $item.FullPath = Join-Path $parentDir $newName

            $item.Status = "✅ Fixed 已修复"
            $success++

        } catch {
            $item.Status = "❌ Failed 失败"
            $item.Error = $_.Exception.Message
            $fail++
        }

        $processed++
        $pct = [math]::Floor($processed / $total * 100)
        Set-Progress $pct "Fixing $processed / $total ... | 正在修复 $processed / $total ..."
    }

    # Refresh the table | 刷新表格
    $dataGrid.Refresh()

    # Update status | 更新状态
    Set-Progress 100 "Fix complete: $success succeeded, $fail failed | 修复完成: 成功 $success, 失败 $fail"

    if ($fail -eq 0) {
        $lblStats.Text = "Total 总计: $total files 文件  |  Ghosts 幽灵: 0  |  Fixed 已修复: $success  |  Failed 失败: 0"
        $lblStatus.Text = "🎉 All fixed! $success file(s) renamed to NFC form. | 🎉 全部修复成功！$success 个文件已重命名为 NFC 规范化形式。"
        $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(39, 174, 96)
    } else {
        $lblStats.Text = "Total 总计: $total files 文件  |  Ghosts 幽灵: 0  |  Fixed 已修复: $success  |  Failed 失败: $fail"
        $lblStatus.Text = "⚠️ Fix complete: $fail file(s) failed. See error details. | ⚠️ 修复完成，$fail 个文件失败。请查看详细错误信息。"
        $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(243, 156, 18)
    }

    Update-Stats

    $btnScan.Enabled = $true
    $btnFix.Enabled = ($fail -gt 0)
    $btnExport.Enabled = $true
}

# ============================================================
# Export log | 导出日志
# ============================================================
function Export-Log {
    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Filter = "CSV Files CSV 文件 (*.csv)|*.csv|JSON Files JSON 文件 (*.json)|*.json|Text Files 文本文件 (*.txt)|*.txt"
    $saveDialog.DefaultExt = "csv"
    $saveDialog.FileName = "GhostFix_Log_日志_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"

    if ($saveDialog.ShowDialog() -ne "OK") { return }

    try {
        $exportData = $script:ScanResults | Select-Object Status, Directory, OldName, NewName, Size, Error

        switch ([System.IO.Path]::GetExtension($saveDialog.FileName).ToLower()) {
            ".json" {
                $exportData | ConvertTo-Json -Depth 3 | Out-File -FilePath $saveDialog.FileName -Encoding UTF8
            }
            ".txt" {
                $lines = @()
                $lines += "GhostFix Fix Log 修复日志 — $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
                $lines += "Source Folder 源文件夹: $script:SelectedFolder"
                $lines += "=" * 80
                $lines += ""
                foreach ($item in $exportData) {
                    $lines += "[$($item.Status)] $($item.Directory)\$($item.OldName) → $($item.NewName)"
                    if ($item.Error) { $lines += "  Error 错误: $($item.Error)" }
                }
                $lines += ""
                $lines += "=" * 80
                $lines | Out-File -FilePath $saveDialog.FileName -Encoding UTF8
            }
            default {
                $exportData | Export-Csv -Path $saveDialog.FileName -NoTypeInformation -Encoding UTF8
            }
        }

        $lblStatus.Text = "📋 Log exported to: $($saveDialog.FileName) | 📋 日志已导出到: $($saveDialog.FileName)"
        $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(39, 174, 96)

    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to export log:`n导出日志失败:`n$($_.Exception.Message)", "Error | 错误", "OK", "Error")
    }
}

# ============================================================
# Utility functions | 工具函数
# ============================================================
function Format-FileSize {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { return "$([math]::Round($Bytes / 1GB, 1)) GB" }
    if ($Bytes -ge 1MB) { return "$([math]::Round($Bytes / 1MB, 1)) MB" }
    if ($Bytes -ge 1KB) { return "$([math]::Round($Bytes / 1KB, 1)) KB" }
    return "$Bytes B"
}

# ============================================================
# Keyboard shortcuts | 键盘快捷键
# ============================================================
$form.Add_KeyDown({
    param($sender, $e)
    if ($e.Control -and $e.KeyCode -eq "F") { Start-Scan }
    if ($e.Control -and $e.KeyCode -eq "R") { Start-Fix }
    if ($e.Control -and $e.KeyCode -eq "S") { Export-Log }
})
$form.KeyPreview = $true

# ============================================================
# Window closing event | 窗口关闭事件
# ============================================================
$form.Add_FormClosing({
    if ($script:ScanResults.Count -gt 0 -and ($script:ScanResults | Where-Object { $_.Status -eq "⚠️ Pending 待修复" }).Count -gt 0) {
        $pending = ($script:ScanResults | Where-Object { $_.Status -eq "⚠️ Pending 待修复" }).Count
        $r = [System.Windows.Forms.MessageBox]::Show(
            "$pending ghost file(s) not fixed yet. Exit anyway?`n还有 $pending 个幽灵文件未修复，确定退出吗？",
            "Confirm Exit | 确认退出",
            "YesNo",
            "Warning"
        )
        if ($r -ne "Yes") { $_.Cancel = $true }
    }
})

# ============================================================
# Start the application | 启动应用
# ============================================================
$form.Add_Shown({
    $form.Activate()
    $lblStatus.Text = "Ready — please select a target folder and click 'Scan Ghosts' | 就绪 — 请选择目标文件夹并点击「扫描幽灵文件」"
})

Write-Host "GhostFix v1.0 starting... | 启动中..."
Write-Host "Working directory 工作目录: $PSScriptRoot"
[System.Windows.Forms.Application]::Run($form)
