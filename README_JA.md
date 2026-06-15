# MIMS - Make Idea Make Sense

> あいまいなソフトウェアのアイデアを、要件、設計ドキュメント、クリック可能な HTML プロトタイプへ整理する対話型 AI ガイドです。

**バージョン**：1.5.2

## MIMS とは

MIMS は Claude Code、Codex、Cursor などの AI コーディングツールにインストールして使います。専門用語を知らなくても、自然な会話で設計を進め、次の成果物を生成します。

- `domain-model.yaml`：構造化されたドメインモデル
- `srs.md`：ソフトウェア要求仕様書
- `sdd.md`：ソフトウェア設計書
- `prototype/`：依存関係なしで開ける HTML プロトタイプ

MIMS v1.5.2 はアップグレードチェーンの強化とプロジェクトライフサイクル管理を追加します：

- アップグレードチェーン：社内 GitLab の非公開リポジトリは `/api/v4` + トークン認証を使用。起動スクリプトは `-fsSL` で強化。パッケージに `SHA256SUMS` 完全性チェックを同梱。アップグレード前にスナップショット、ワンクリックでロールバック。ローカル変更は `.local` として保持。
- プロジェクトライフサイクル：`/mims status|pause|resume|persist|detach`。設計完了後に一時停止して開発へ移行可能。
- 成果物の再配置：一時停止時に設計成果物を `design/` に移動可能。再開時に自動で再検出。
- バージョン管理：`mims update --check` / `--edge`。`.mims-commit` が内容の発生源を記録。

## インストールまたは更新

一度インストールすれば、すべてのプロジェクトで利用できます。

すでに MIMS をインストールしている場合は、ローカル updater の利用を推奨します。既定では `~/.mims/install-state.json` に記録された前回のインストール元（GitHub または GitLab）を読み取り、その元から更新します。

```powershell
& "$HOME\.mims\update.ps1"
```

Linux / macOS：

```bash
bash ~/.mims/update.sh
```

GitLab / 社内ネットワークから更新する場合：

```powershell
& "$HOME\.mims\update.ps1" -Source gitlab
```

```bash
bash ~/.mims/update.sh gitlab
```

以下のインストールコマンドを再実行して更新することもできます。更新によりグローバルな MIMS Skill と Agents は上書きされますが、プロジェクト内の `domain-model.yaml`、`srs.md`、`sdd.md`、`prototype/`、`CLAUDE.md`、`AGENTS.md` は上書きされません。

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

社内ネットワークまたは VPN ユーザー向けです。

Linux / macOS：

```bash
curl -sSL https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/raw/main/install/install-global.sh | bash
```

Windows PowerShell：

```powershell
iex ((New-Object System.Net.WebClient).DownloadString('https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/raw/main/install/install-global.ps1'))
```

## 使い始める

プロジェクトフォルダに移動します。

```bash
cd /your-project
```

Claude Code：

```text
/mims design
```

Codex など slash command が安定しない環境：

```text
MIMS を使って要件整理を始めてください
```

## コマンド

| コマンド | 用途 |
|---|---|
| `/mims` | ヘルプ表示 |
| `/mims design` | 設計を開始または再開 |
| `/mims model` | 現在の設計概要を表示 |
| `/mims status` | このプロジェクトの MIMS 有効状態を表示 |
| `/mims validate` | モデルを検証 |
| `/mims prototype` | HTML プロトタイプを生成 |
| `/mims change` | 既存設計を変更 |
| `/mims srs` | 要求仕様書を生成 |
| `/mims sdd` | 設計書を生成 |
| `/mims pause` | プロジェクト常駐の MIMS を一時停止して開発状態にする |
| `/mims resume` | このセッションだけ MIMS を一時的に有効化 |
| `/mims persist` | MIMS をプロジェクト入口に再度永続化 |
| `/mims detach` | プロジェクトレベルの MIMS 入口を削除 |

設計完了後に開発へ進む場合は、`/mims pause` でプロジェクト常駐の MIMS を一時停止することを推奨します。これは MIMS のアンインストールではなく、`domain-model.yaml`、`srs.md`、`sdd.md`、`prototype/` も削除しません。必要になったら `/mims resume` で一時的に、または `/mims persist` で永続的に再有効化できます。

## 生成されるファイル

| ファイル | 説明 |
|---|---|
| `domain-model.yaml` | ドメインモデルと進捗 |
| `srs.md` | 要求仕様書 |
| `sdd.md` | 設計書 |
| `prototype/` | ブラウザで確認できるプロトタイプ |

## 適用範囲

MIMS は業務システム、ワークフロー、社内ツール、CRM/ERP 系システム、初期プロダクト検証に向いています。生成されるプロトタイプは確認用であり、本番システムではありません。

## ライセンス

MIT License
