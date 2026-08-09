# 👻 GhostFix — NFD→NFC Unicode Filename Repair Tool

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell)](https://github.com/cyberflax2020/GhostFix)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-lightgrey?logo=windows)](https://github.com/cyberflax2020/GhostFix)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen)](https://github.com/cyberflax2020/GhostFix/releases)

> **English** | A Windows GUI tool that recursively scans and repairs ghost files — filenames corrupted by **NFD (decomposed) Unicode encoding** caused by the Tuxera NTFS driver on macOS, rendering files inaccessible.
>
> **中文** | 一款 Windows GUI 工具，递归扫描并修复因 macOS Tuxera NTFS 驱动导致的 **NFD 分解式 Unicode 文件名编码**问题（俗称"幽灵文件"），使文件在 macOS 上恢复正常访问。

---

## 📖 Table of Contents | 目录

- [Problem | 问题](#-problem--问题)
- [Screenshots | 截图](#-screenshots--截图)
- [Installation | 安装](#-installation--安装)
- [Usage | 使用](#-usage--使用)
- [How It Works | 原理](#-how-it-works--原理)
- [Safety | 安全性](#-safety--安全性)
- [FAQ | 常见问题](#-faq--常见问题)

---

## 🎯 Problem | 问题

### The Ghost File Phenomenon | 幽灵文件现象

When an NTFS-formatted external drive is used on macOS via the **Tuxera NTFS** driver, filenames containing diacritics or CJK characters are written in **NFD (Normalization Form D — decomposed)** form instead of **NFC (Normalization Form C — composed)**:

| Character | NFC (Correct) | NFD (Corrupted) |
|-----------|---------------|-----------------|
| **é** | `U+00E9` (1 codepoint) | `U+0065` + `U+0301` (2 codepoints) |
| **ド** | `U+30C9` (1 codepoint) | `U+30C8` + `U+3099` (2 codepoints) |
| **ü** | `U+00FC` (1 codepoint) | `U+0075` + `U+0308` (2 codepoints) |

**Symptom on macOS | 症状：**
```
$ ls        → ✅ File is listed
$ stat      → ❌ No such file or directory
$ ffprobe   → ❌ Cannot read
$ Finder    → ❌ Cannot open
```

The file **exists on disk** and the data is intact, but the NFD-encoded path is **unreachable** through Tuxera's driver layer.

---

## 📸 Screenshots | 截图

### Scan: Detecting Ghost Files | 扫描幽灵文件
![Scan Result](screenshots/01_scan_result.png)

### Fix: All Repaired | 全部修复
![Fix Complete](screenshots/02_fix_complete.png)

---

## 📦 Installation | 安装

### Requirements | 系统要求

- **Windows 10** or **Windows 11**
- **PowerShell 5.1+** (built-in, no installation needed)
- **No third-party dependencies** | 零第三方依赖

### Download | 下载

```bash
git clone git@github.com:cyberflax2020/GhostFix.git
```

Or download the latest release ZIP from [Releases](https://github.com/cyberflax2020/GhostFix/releases).

### Launch | 启动

```
Double-click:  启动GhostFix.bat
          OR:  Right-click GhostFix.ps1 → Run with PowerShell
```

---

## 🚀 Usage | 使用

### 3-Step Workflow | 三步操作

| Step | Action | Description |
|------|--------|-------------|
| **1** | 📂 **Select** folder | Choose the target directory (e.g., SD card music folder) |
| **2** | 🔍 **Scan** | Recursively find all NFD-encoded filenames |
| **3** | 🔧 **Fix** | One-click rename all ghosts to NFC-normalized form |

### Keyboard Shortcuts | 快捷键

| Key | Action |
|-----|--------|
| `Ctrl + F` | Start scan |
| `Ctrl + R` | Start fix |
| `Ctrl + S` | Export log |

### Export Formats | 日志导出

- **CSV** — Open in Excel
- **JSON** — Programmatic processing
- **TXT** — Human-readable plain text

---

## ⚙️ How It Works | 原理

### Detection Algorithm | 检测算法

```powershell
# Core detection — Ordinal comparison
$nfc = $filename.Normalize([System.Text.NormalizationForm]::FormC)
$isGhost = -not [string]::Equals($filename, $nfc, [StringComparison]::Ordinal)
```

If `filename ≠ NFC(filename)` → the filename is in **NFD decomposed form** → needs repair.

### Fix Operation | 修复操作

```powershell
Rename-Item -LiteralPath <NFD_path> -NewName <NFC_normalized_name>
```

`Rename-Item` is an **atomic operation** on NTFS — it either fully succeeds or fully fails, never a partial state.

### Why Windows? | 为什么在 Windows 上修复？

- **Windows** uses NTFS natively → NFD-encoded paths ARE accessible
- **macOS + Tuxera** → NFD paths are ghosted (driver bug)
- Fix on Windows → drive works on both platforms

---

## 🔒 Safety | 安全性

| Guarantee | Detail |
|-----------|--------|
| **Content-safe** | Only renames the file; file content is **never modified** |
| **Atomic** | NTFS rename is atomic — no intermediate broken state |
| **Selective** | Only touches files with NFD encoding; ASCII/normal files are **never affected** |
| **Logged** | Every operation is logged; exportable for audit |

### Before/After Verification | 操作前后验证

```
Before:  Nocturn a Chloé.m4a  (NFD, macOS: ❌ inaccessible)
After:   Nocturn a Chloé.m4a  (NFC, macOS: ✅ accessible)

$ sha256sum before after   → identical (content unchanged)
```

---

## ❓ FAQ | 常见问题

### Q: Will this affect my normal files? | 会影响正常文件吗？
**A:** No. GhostFix only touches files whose names differ between NFC and NFD forms (Ordinal comparison). Pure ASCII or already-NFC files are **completely skipped**.

### Q: Can I undo the fix? | 能撤销吗？
**A:** To undo, simply rename the files back to NFD form. However, this would re-create the macOS accessibility problem. The fix is a standard NFC normalization — what Windows and modern macOS use by default.

### Q: Does it work on macOS? | 能在 macOS 上运行吗？
**A:** No. GhostFix must run on Windows because the macOS Tuxera driver **cannot even access** the ghost files to rename them. Fix on Windows → use anywhere.

### Q: Is it only for music files? | 只支持音乐文件吗？
**A:** No. GhostFix works on **all file types** — documents, images, videos, archives, anything. It only checks the filename encoding, not the content.

### Q: Why does this problem happen? | 为什么会发生这个问题？
**A:** macOS's filesystem layer historically uses NFD internally, while Windows/NTFS uses NFC. The **Tuxera NTFS driver** (third-party) has a long-standing bug where it fails to properly translate between these forms during path resolution, creating "ghost" directory entries.

---

## 📂 Project Structure | 项目结构

```
GhostFix/
├── GhostFix.ps1           ← Main application
├── 启动GhostFix.bat        ← One-click launcher
├── 用户文档.md              ← Chinese user manual
├── README.md              ← This file
├── .gitignore
├── screenshots/           ← UI screenshots
│   ├── 01_scan_result.png
│   └── 02_fix_complete.png
└── scripts/
    └── gen_screenshots.ps1
```

---

## 📄 License

MIT © [cyberflax2020](https://github.com/cyberflax2020)

---

*Made with ❤️ for the music collector who just wants their files to work everywhere.*
