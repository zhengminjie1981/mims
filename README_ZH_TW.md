# MIMS - Make Idea Make Sense

> 迷悟師：透過對話協助非技術使用者完成軟體需求、設計文件與可點擊 HTML 原型。

**版本**：1.6.0

## MIMS 是什麼？

MIMS 可安裝到 Claude Code、Codex、Cursor 等 AI 編程工具中。它會用日常語言引導你整理系統想法，並生成：

- `domain-model.yaml`：結構化領域模型
- `srs.md`：軟體需求規格書
- `sdd.md`：軟體設計文件
- `prototype/`：零依賴 HTML 原型

MIMS v1.6.0 帶來升級鏈路加固與專案生命週期管理：

- 升級鏈路：內網 GitLab 私有庫走 `/api/v4` + token 鑑權；啟動器 `-fsSL` 加固；發布包附 `SHA256SUMS` 完整性校驗；升級前自動快照、一鍵回滾；本地改動保留為 `.local`。
- 專案生命週期：`/mims status|pause|resume|persist|detach`；設計完成後可暫停進入開發狀態。
- 工作產品搬遷：暫停時可選把設計產物整體搬到 `design/`，恢復時自動定位。
- 版本管理：`mims update --check` / `--edge`；`.mims-commit` 標識內容來源。

## 安裝與更新

安裝一次，所有專案可用。

如果已經安裝過 MIMS，建議優先使用本地更新器。更新器會預設讀取 `~/.mims/install-state.json` 中記錄的上次安裝來源（GitHub 或 GitLab），並依照該來源更新：

```powershell
& "$HOME\.mims\update.ps1"
```

Linux / macOS：

```bash
bash ~/.mims/update.sh
```

公司內網或 VPN 使用者可指定 GitLab 來源：

```powershell
& "$HOME\.mims\update.ps1" -Source gitlab
```

```bash
bash ~/.mims/update.sh gitlab
```

也可以重新執行下面的安裝命令更新。更新會覆蓋全域 MIMS Skill 和 Agents，但不會覆蓋專案中的 `domain-model.yaml`、`srs.md`、`sdd.md`、`prototype/`、`CLAUDE.md` 或 `AGENTS.md`。

### GitHub

Linux / macOS：

```bash
curl -sSL https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.sh | bash
```

Windows PowerShell：

```powershell
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.ps1'))
```

### GitLab

適合公司內網或 VPN 使用者。

Linux / macOS：

```bash
curl -sSL https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/raw/main/install/install-global.sh | bash
```

Windows PowerShell：

```powershell
iex ((New-Object System.Net.WebClient).DownloadString('https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/raw/main/install/install-global.ps1'))
```

## 開始使用

進入你的專案目錄：

```bash
cd /your-project
```

Claude Code：

```text
/mims design
```

Codex 或不穩定支援 slash command 的工具：

```text
請用 MIMS 幫我開始需求建模
```

## 常用命令

| 命令 | 用途 |
|---|---|
| `/mims` | 查看說明 |
| `/mims design` | 啟動或繼續設計 |
| `/mims model` | 查看目前設計摘要 |
| `/mims status` | 查看目前專案的 MIMS 啟用狀態 |
| `/mims validate` | 檢查模型 |
| `/mims prototype` | 生成 HTML 原型 |
| `/mims change` | 修改既有設計 |
| `/mims srs` | 生成需求文件 |
| `/mims sdd` | 生成設計文件 |
| `/mims pause` | 暫停專案常駐載入，進入開發狀態 |
| `/mims resume` | 僅本次臨時啟用 MIMS |
| `/mims persist` | 重新將 MIMS 持久化到專案入口 |
| `/mims detach` | 移除專案級 MIMS 入口 |

設計完成並進入開發階段後，建議使用 `/mims pause` 暫停目前專案的 MIMS 常駐載入。這不會卸載 MIMS，也不會刪除 `domain-model.yaml`、`srs.md`、`sdd.md` 或 `prototype/`；之後可用 `/mims resume` 臨時啟用，或 `/mims persist` 重新常駐啟用。

## 生成文件

| 文件 | 說明 |
|---|---|
| `domain-model.yaml` | 持久化領域模型與進度 |
| `srs.md` | 需求文件 |
| `sdd.md` | 設計文件 |
| `prototype/` | 可點擊瀏覽器原型 |

## 適用範圍

MIMS 適合管理系統、工作流程、內部工具、CRM/ERP 類系統與早期產品驗證。生成的原型用於確認需求，不是可直接上線的正式系統。

## 授權

MIT License
