# MIMS - Make Idea Make Sense

> 막연한 소프트웨어 아이디어를 요구사항, 설계 문서, 클릭 가능한 HTML 프로토타입으로 정리하는 대화형 AI 가이드입니다.

**버전**: 1.4

## MIMS란?

MIMS는 Claude Code, Codex, Cursor 같은 AI 코딩 도구에 설치해서 사용하는 설계 도우미입니다. 기술 용어를 몰라도 자연어 대화로 시스템 아이디어를 정리하고 다음 파일을 생성합니다.

- `domain-model.yaml`: 구조화된 도메인 모델
- `srs.md`: 소프트웨어 요구사항 문서
- `sdd.md`: 소프트웨어 설계 문서
- `prototype/`: 브라우저에서 바로 열 수 있는 HTML 프로토타입

MIMS v1.4는 Codex 호환성과 모델 품질 관리를 강화했습니다.

- Codex에서는 `AGENTS.md`를 통해 자연어 트리거를 사용할 수 있습니다.
- 하위 에이전트를 사용할 수 없을 때도 동일한 규칙 기반 fallback을 실행합니다.
- 단계 완료는 `metadata.validation` 기록이 있어야만 가능합니다.
- SRS/SDD에는 모델 id를 유지하여 `domain-model.yaml`로 추적할 수 있습니다.
- 프로토타입은 기기별 절대 경로 대신 기본적으로 상대 경로 `prototype/`에 생성됩니다.

## 설치 또는 업데이트

한 번 설치하면 모든 프로젝트에서 사용할 수 있습니다.

이미 MIMS가 설치되어 있다면 로컬 updater 사용을 권장합니다. 기본적으로 `~/.mims/install-state.json`에 기록된 이전 설치 소스(GitHub 또는 GitLab)를 읽고 해당 소스에서 업데이트합니다.

```powershell
& "$HOME\.mims\update.ps1"
```

Linux / macOS:

```bash
bash ~/.mims/update.sh
```

GitLab / 사내 네트워크에서 업데이트하려면:

```powershell
& "$HOME\.mims\update.ps1" -Source gitlab
```

```bash
bash ~/.mims/update.sh gitlab
```

아래 설치 명령을 다시 실행해서 업데이트할 수도 있습니다. 업데이트는 전역 MIMS Skill과 Agents를 덮어쓰지만, 프로젝트의 `domain-model.yaml`, `srs.md`, `sdd.md`, `prototype/`, `CLAUDE.md`, `AGENTS.md`는 덮어쓰지 않습니다.

### GitHub

Linux / macOS:

```bash
curl -sSL https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.sh | bash
```

Windows PowerShell:

```powershell
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/zhengminjie1981/mims/main/install/install-global.ps1'))
```

### GitLab

사내 네트워크 또는 VPN 사용자를 위한 방법입니다.

Linux / macOS:

```bash
curl -sSL https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/raw/main/install/install-global.sh | bash
```

Windows PowerShell:

```powershell
iex ((New-Object System.Net.WebClient).DownloadString('https://gitlab.xyitech.com/antwork/CloudServer/it/MIMS/-/raw/main/install/install-global.ps1'))
```

## 시작하기

프로젝트 폴더로 이동합니다.

```bash
cd /your-project
```

Claude Code:

```text
/mims design
```

Codex 또는 slash command 지원이 불안정한 도구:

```text
MIMS로 요구사항 모델링을 시작해 주세요
```

## 명령어

| 명령어 | 용도 |
|---|---|
| `/mims` | 도움말 보기 |
| `/mims design` | 설계 시작 또는 이어서 진행 |
| `/mims model` | 현재 설계 요약 보기 |
| `/mims status` | 현재 프로젝트의 MIMS 활성 상태 보기 |
| `/mims validate` | 모델 검증 |
| `/mims prototype` | HTML 프로토타입 생성 |
| `/mims change` | 기존 설계 변경 |
| `/mims srs` | 요구사항 문서 생성 |
| `/mims sdd` | 설계 문서 생성 |
| `/mims pause` | 프로젝트 상주 MIMS 로딩을 일시 중지하고 개발 상태로 전환 |
| `/mims resume` | 이번 세션에서만 MIMS 임시 활성화 |
| `/mims persist` | MIMS를 프로젝트入口에 다시 영구 활성화 |
| `/mims detach` | 프로젝트 수준 MIMS入口 제거 |

설계가 완료되어 개발 단계로 넘어갈 때는 `/mims pause`로 현재 프로젝트의 MIMS 상주 로딩을 중지하는 것을 권장합니다. 이 명령은 MIMS를 제거하지 않으며 `domain-model.yaml`, `srs.md`, `sdd.md`, `prototype/`도 삭제하지 않습니다. 필요하면 `/mims resume`으로 임시 활성화하거나 `/mims persist`로 다시 상주 활성화할 수 있습니다.

## 생성 파일

| 파일 | 설명 |
|---|---|
| `domain-model.yaml` | 도메인 모델과 진행 상태 |
| `srs.md` | 요구사항 문서 |
| `sdd.md` | 설계 문서 |
| `prototype/` | 브라우저에서 확인하는 프로토타입 |

## 적합한 사용처

MIMS는 관리 시스템, 업무 흐름, 내부 도구, CRM/ERP 유형 시스템, 초기 제품 검증에 적합합니다. 생성된 프로토타입은 검토와 소통을 위한 것이며 운영용 시스템이 아닙니다.

## 라이선스

MIT License
