#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""MIMS 项目生命周期脚本（B4）。

在脚本内完成 CLAUDE.md / AGENTS.md 的 managed block 替换与 .mims/state.yaml 读写，
不经 Edit/Write，规避多字节 old_string 失配（R2）与 read-tracking（R3）问题；
内置 block 外残留扫描（R5）、old-style 迁移、工作产品搬迁。

用法：
  python scripts/mims-lifecycle.py status
  python scripts/mims-lifecycle.py pause [--move-design] [--reason TEXT]
  python scripts/mims-lifecycle.py persist
  python scripts/mims-lifecycle.py detach
  python scripts/mims-lifecycle.py resume

设计要点：
  - 所有文件改写用 Python open/read/write，调用方（SKILL.md/LLM）不再用 Edit/Write。
  - 按标记行 MIMS-START / MIMS-END 精确 splice，不依赖整段匹配。
  - 粒度判定保守：block 外有任何非 MIMS 内容→只换 block；仅 MIMS/空→整文件替换。
"""

import argparse
import datetime
import json
import os
import re
import shutil
import sys
from pathlib import Path

# MIMS_HOME 覆盖：测试或重定向时可用（默认真实用户主目录）。
# 注意 Windows 上 Path.home() 走 USERPROFILE 而非 HOME，故提供显式覆盖。
_home_env = os.environ.get("MIMS_HOME")
HOME = Path(_home_env) if _home_env else Path.home()
MIMS_HOME = HOME / ".mims"
STATE_FILE = MIMS_HOME / "state.yaml"
ENTRY_FILES = [Path("CLAUDE.md"), Path("AGENTS.md")]
DESIGN_RELOCATE = "design"
WORK_PRODUCTS = ["domain-model.yaml", "srs.md", "sdd.md", "prototype"]

# selfcheck 核心文件硬清单（SKILL.md 运行时强依赖，缺失即阻断）
SELFCHECK_CORE_REFS = ["schema-contract.md", "schema.md"]
SELFCHECK_CORE_AGENTS = [
    "mims-validator.md",
    "mims-prototyper.md",
    "mims-change-manager.md",
    "mims-spec-generator.md",
]

START_RE = re.compile(r"<!--\s*MIMS-START([^>]*)-->")
END_RE = re.compile(r"<!--\s*MIMS-END\s-->")

# block 外已知 MIMS 模式（粒度判定：仅这些→可整文件替换）
MIMS_OUTSIDE = [
    re.compile(r"^#\s*迷悟师", re.M),
    re.compile(r"^#\s*MIMS\b", re.M),
    re.compile(r"你是\*{0,2}迷悟师"),
    re.compile(r"保持迷悟师身份待机"),
    re.compile(r"完整人设扩展规则由"),
    re.compile(r"^>\s.*MIMS", re.M),
    re.compile(r"^>\s*输入\s*`?/mims", re.M),
    re.compile(r"^<!--\s*完整人设扩展规则", re.M),
]

GREEN, YELLOW, RED, CYAN, NC = "\033[0;32m", "\033[1;33m", "\033[0;31m", "\033[0;36m", "\033[0m"


def ok(m):
    print(f"{GREEN}✓{NC} {m}")


def info(m):
    print(f"{CYAN}ℹ{NC} {m}")


def warn(m):
    print(f"{YELLOW}⚠{NC} {m}")


def die(m):
    print(f"{RED}✗{NC} {m}", file=sys.stderr)
    sys.exit(1)


# ---------------------------------------------------------------------------
# 模板与 skill 定位
# ---------------------------------------------------------------------------
def references_dir():
    cands = [
        HOME / ".claude/skills/mims/references",
        HOME / ".agents/skills/mims/references",
        Path(__file__).resolve().parent.parent / "mims-release/.claude/skills/mims/references",
    ]
    for c in cands:
        if (c / "claude-md-template.md").is_file():
            return c
    return None


def read_template(name):
    d = references_dir()
    if not d:
        die("找不到 MIMS references 目录（skill 未安装或不在 dev 仓库）")
    p = d / name
    if not p.is_file():
        die(f"找不到模板 {name}")
    return p.read_text(encoding="utf-8")


def mims_version():
    for p in [
        HOME / ".claude/skills/mims/SKILL.md",
        HOME / ".agents/skills/mims/SKILL.md",
        Path(__file__).resolve().parent.parent / "mims-release/.claude/skills/mims/SKILL.md",
    ]:
        if p.is_file():
            m = re.search(r'version:\s*"([^"]+)"', p.read_text(encoding="utf-8"))
            if m:
                return m.group(1)
    return "unknown"


def detect_source():
    g = (HOME / ".claude/skills/mims/SKILL.md").is_file() or (HOME / ".agents/skills/mims/SKILL.md").is_file()
    p = Path(".claude/skills/mims/SKILL.md").is_file() or Path(".agents/skills/mims/SKILL.md").is_file()
    if g and p:
        return "both"
    if g:
        return "global"
    if p:
        return "project"
    return "none"


# ---------------------------------------------------------------------------
# selfcheck 辅助（只读检测原语）
# ---------------------------------------------------------------------------
def _end_version(root):
    """某端（~/.claude 或 ~/.agents）的 MIMS 版本：优先 skills/.mims-version，回退 SKILL.md frontmatter。"""
    vf = root / "skills" / ".mims-version"
    if vf.is_file():
        v = vf.read_text(encoding="utf-8").strip()
        if v:
            return v
    smd = root / "skills" / "mims" / "SKILL.md"
    if smd.is_file():
        m = re.search(r'version:\s*"([^"]+)"', smd.read_text(encoding="utf-8"))
        if m:
            return m.group(1)
    return None


def _frontmatter_intact(skill_md):
    """SKILL.md frontmatter 是否含 name 与 version（防下载截断/损坏）。"""
    if not skill_md.is_file():
        return False
    txt = skill_md.read_text(encoding="utf-8")
    has_name = re.search(r"^name:\s*\S", txt, re.M) is not None
    has_ver = re.search(r'version:\s*"[^"]+"', txt) is not None
    return has_name and has_ver


def _mims_skill_dupes(skills_dir):
    """skills 目录下 mims* 且 ≠ mims 的目录名（重复 Skill 残留，加载歧义源）。"""
    if not skills_dir.is_dir():
        return []
    return sorted(
        d.name for d in skills_dir.iterdir()
        if d.is_dir() and d.name.startswith("mims") and d.name != "mims"
    )


# ---------------------------------------------------------------------------
# block 解析
# ---------------------------------------------------------------------------
def find_block(text):
    m = START_RE.search(text)
    if not m:
        return None
    e = END_RE.search(text, m.end())
    if not e:
        return None
    return m, e


def block_state(text):
    f = find_block(text)
    if not f:
        return None
    sm = re.search(r"state=(\w+)", f[0].group(1))
    return sm.group(1) if sm else "active"  # 无 state 视为 active（old-style）


def split_text(text):
    """返回 (before, block_including_markers, after)。"""
    f = find_block(text)
    if not f:
        return None
    m, e = f
    return text[: m.start()], text[m.start() : e.end()], text[e.end() :]


def extract_template_block(tpl):
    """模板整体即一个 block；返回 MIMS-START..MIMS-END 子串。"""
    f = find_block(tpl)
    if not f:
        return tpl.rstrip("\n")
    m, e = f
    return tpl[m.start() : e.end()]


def outside_is_mims_only(before, after):
    """block 外是否仅 MIMS 内容/空。保守：任何非空非 MIMS 行→False。"""
    combined = before + "\n" + after
    for line in combined.splitlines():
        s = line.strip()
        if not s:
            continue
        if any(p.search(s) for p in MIMS_OUTSIDE):
            continue
        return False
    return True


# ---------------------------------------------------------------------------
# state.yaml
# ---------------------------------------------------------------------------
def read_state_location():
    if not STATE_FILE.is_file():
        return "."
    m = re.search(r'location:\s*"([^"]*)"', STATE_FILE.read_text(encoding="utf-8"))
    return m.group(1) if m else "."


def write_state(activation_state, location=".", reason="", target_files=None):
    MIMS_HOME.mkdir(parents=True, exist_ok=True)
    ts = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    tf = ", ".join(target_files) if target_files else ""
    content = f"""# MIMS 运行状态（由 mims-lifecycle.py 维护）
mims_runtime:
  activation_state: "{activation_state}"
  version: "{mims_version()}"
  last_changed_at: "{ts}"
  reason: "{reason}"
installation:
  detected_source: "{detect_source()}"
project_activation:
  target_files: [{tf}]
  marker: "MIMS-START"
design_artifacts:
  location: "{location}"
  domain_model: "domain-model.yaml"
  srs: "srs.md"
  sdd: "sdd.md"
  prototype_dir: "prototype/"
"""
    with open(STATE_FILE, "w", encoding="utf-8", newline="\n") as f:
        f.write(content)


# ---------------------------------------------------------------------------
# 文件入口与操作
# ---------------------------------------------------------------------------
def entry_files_with_block():
    out = []
    for f in ENTRY_FILES:
        if f.is_file():
            txt = f.read_text(encoding="utf-8")
            if find_block(txt):
                out.append(f)
    return out


def replace_in_file(path, new_text):
    # 强制 LF（与仓库存量一致；Python 默认在 Windows 写 CRLF 会造成全文件 diff）
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(new_text)


def apply_template(target_state, reason=""):
    """把入口文件的 block 替换为目标模板（paused/active）。返回 (改动的文件, 粒度)。"""
    template_name = {
        "paused": "claude-md-paused-template.md",
        "active": "claude-md-template.md",
    }[target_state]
    tpl = read_template(template_name)
    tpl_block = extract_template_block(tpl)  # 带标记
    tpl_full = tpl.rstrip("\n") + "\n"

    changed = []
    for f in entry_files_with_block():
        text = f.read_text(encoding="utf-8")
        parts = split_text(text)
        if not parts:
            continue
        before, _old_block, after = parts
        if outside_is_mims_only(before, after):
            # 整文件替换（清除 block 外 MIMS 残文）
            replace_in_file(f, tpl_full)
            changed.append((f, "whole-file"))
        else:
            # 仅替换 block，保留 block 外用户内容
            new_text = before + tpl_block + after
            replace_in_file(f, new_text)
            changed.append((f, "block-only"))
    return changed


# ---------------------------------------------------------------------------
# 工作产品搬迁
# ---------------------------------------------------------------------------
def relocate_workproducts(src_loc, dst_loc):
    """把工作产品从 src_loc 整组搬到 dst_loc。pause→design/，persist --move-root→根目录。"""
    src = Path(src_loc)
    dst = Path(dst_loc)
    if src.resolve() == dst.resolve():
        info(f"工作产品已在 {dst}/，无需搬迁")
        return
    # 仅当目标处已有同名工作产品（会覆盖）时中止；dst 含其它无关内容（如根目录）不阻塞
    for wp in WORK_PRODUCTS:
        if (src / wp).exists() and (dst / wp).exists():
            die(f"目标已存在 {dst}/{wp}，已中止搬迁（避免覆盖）。请手动处理后重试。")
    dst.mkdir(parents=True, exist_ok=True)
    moved = []
    for wp in WORK_PRODUCTS:
        s = src / wp
        if s.exists():
            d = dst / wp
            if s.is_dir():
                shutil.copytree(s, d)
                shutil.rmtree(s)
            else:
                shutil.move(str(s), str(d))
            moved.append(wp)
    if moved:
        ok(f"工作产品已搬到 {dst}/：{', '.join(moved)}")
    else:
        warn(f"未在 {src}/ 发现任何工作产品，跳过搬迁")


# ---------------------------------------------------------------------------
# 命令
# ---------------------------------------------------------------------------
def cmd_status():
    files = entry_files_with_block()
    loc = read_state_location()
    src = detect_source()
    ver = mims_version()
    print(f"{CYAN}MIMS 项目状态{NC}")
    print(f"  安装来源：{src}")
    print(f"  MIMS 版本：{ver}")
    if not files:
        print("  项目激活状态：absent（入口无 managed block）")
    else:
        states = {f.name: block_state(f.read_text(encoding="utf-8")) for f in files}
        print(f"  入口文件：{', '.join(states.keys())}")
        print(f"  各文件 block state：{states}")
    print(f"  设计产物位置：{loc}")
    print(f"  设计产物存在性：")
    for wp in WORK_PRODUCTS:
        p = Path(loc) / wp
        print(f"    {wp}: {'✓' if p.exists() else '✗'}")
    # 安装位置
    print(f"  全局安装：claude={ (HOME/'.claude/skills/mims/SKILL.md').is_file() }  codex={ (HOME/'.agents/skills/mims/SKILL.md').is_file() }")


def cmd_selfcheck():
    """安装完整性自检：只读、不联网、不写文件。

    输出分级文本，供 SKILL.md 加载时解析：
      [OK] / [ERROR][needs_reinstall] / [WARN][local_fixable|needs_reinstall] / [INFO]
      SUMMARY: errors=N warns=N infos=N
    退出码：errors>0 → 1（仅 WARN/INFO → 0，不阻断加载，仅触发修复流程）。
    """
    errors = warns = infos = 0
    claude_root = HOME / ".claude"
    codex_root = HOME / ".agents"
    claude_md = claude_root / "skills" / "mims" / "SKILL.md"
    codex_md = codex_root / "skills" / "mims" / "SKILL.md"
    claude_present = claude_md.is_file()
    codex_present = codex_md.is_file()
    ends = [("claude", claude_root, claude_present), ("codex", codex_root, codex_present)]

    # 1) 已存在端：frontmatter + 核心文件（SKILL.md 运行时强依赖）
    for name, root, present in ends:
        if not present:
            continue
        smd = root / "skills" / "mims" / "SKILL.md"
        if not _frontmatter_intact(smd):
            print(f"[ERROR][needs_reinstall] {name} 端 SKILL.md frontmatter 缺失/损坏（无 name 或 version）：{smd}")
            errors += 1
        else:
            print(f"[OK]      SKILL.md ({name}={_end_version(root) or '?'})")
        refs = root / "skills" / "mims" / "references"
        for r in SELFCHECK_CORE_REFS:
            if not (refs / r).is_file():
                print(f"[ERROR][needs_reinstall] {name} 端缺失 references/{r}")
                errors += 1
        agents_dir = root / "agents"
        for a in SELFCHECK_CORE_AGENTS:
            if not (agents_dir / a).is_file():
                print(f"[ERROR][needs_reinstall] {name} 端缺失 agents/{a}")
                errors += 1

    # 2) 两端版本一致性
    if claude_present and codex_present:
        cv, sv = _end_version(claude_root), _end_version(codex_root)
        if cv and sv and cv != sv:
            print(f"[WARN][needs_reinstall]  两端版本不一致：claude={cv} codex={sv}")
            warns += 1

    # 3) 两端 references / mims-* agents 文件名对称（镜像不一致=残留或损坏）
    if claude_present and codex_present:
        def _names(d, prefix=None):
            if not d.is_dir():
                return set()
            return {
                p.name for p in d.iterdir()
                if p.is_file() and (prefix is None or p.name.startswith(prefix))
            }
        cr = _names(claude_root / "skills" / "mims" / "references")
        sr = _names(codex_root / "skills" / "mims" / "references")
        if cr != sr:
            print(f"[WARN][needs_reinstall]  两端 references 不对称：仅 claude={sorted(cr - sr) or '无'} 仅 codex={sorted(sr - cr) or '无'}")
            warns += 1
        ca = _names(claude_root / "agents", "mims-")
        sa = _names(codex_root / "agents", "mims-")
        if ca != sa:
            print(f"[WARN][needs_reinstall]  两端 mims-* agents 不对称：仅 claude={sorted(ca - sa) or '无'} 仅 codex={sorted(sa - ca) or '无'}")
            warns += 1

    # 4) 重复 Skill 目录（mims* ≠ mims）—— 本地可清理
    for name, root, _present in ends:
        for d in _mims_skill_dupes(root / "skills"):
            print(f"[WARN][local_fixable]    重复 Skill 目录：{root}/skills/{d}")
            warns += 1

    # 5) ~/.mims 工具链
    if MIMS_HOME.is_dir():
        for tool in ["mims-lifecycle.py", "update.sh", "update.ps1"]:
            if not (MIMS_HOME / tool).is_file():
                print(f"[WARN][needs_reinstall]  ~/.mims 工具链缺失：{tool}")
                warns += 1
        # rollback 脚本 Windows 仅 .ps1、Linux 仅 .sh，故按"至少一个"判断
        if not (MIMS_HOME / "rollback.sh").is_file() and not (MIMS_HOME / "rollback.ps1").is_file():
            print("[WARN][needs_reinstall]  ~/.mims 缺失回滚脚本（rollback.sh / rollback.ps1 均无）")
            warns += 1
        state = MIMS_HOME / "install-state.json"
        commit = None
        if state.is_file():
            try:
                commit = json.loads(state.read_text(encoding="utf-8")).get("commit")
            except Exception:
                commit = None
        if not commit:
            print("[INFO]                   本地无 commit 记录（edge/dev 安装），update --check 不可用")
            infos += 1

    # 6) 单端 / 来源 INFO（仅提示，不介入修复）
    if claude_present and not codex_present:
        print("[INFO]                   单端安装（仅 claude，未装 codex 兼容）")
        infos += 1
    elif codex_present and not claude_present:
        print("[INFO]                   单端安装（仅 codex）")
        infos += 1
    elif not claude_present and not codex_present:
        src = detect_source()
        if src == "none":
            print("[INFO]                   未检测到全局 MIMS 安装（global=none）；从开发仓运行属正常")
        else:
            print(f"[INFO]                   全局未安装，检测到 project 级安装（source={src}）")
        infos += 1

    print(f"SUMMARY: errors={errors} warns={warns} infos={infos}")
    sys.exit(1 if errors else 0)


def cmd_pause(relocate, reason):
    files = entry_files_with_block()
    if not files:
        die("当前项目入口无 MIMS managed block（未初始化）。先运行 /mims design。")
    # 产物体检（C7）
    loc = read_state_location()
    missing = [wp for wp in ["srs.md", "sdd.md"] if not (Path(loc) / wp).exists()]
    if missing:
        warn(f"设计产物缺失：{', '.join(missing)}。建议先 /mims srs 或 /mims sdd 补生成再暂停。")
    changed = apply_template("paused", reason)
    for f, gran in changed:
        ok(f"{f.name} → paused（{gran}）")
    new_loc = loc
    if relocate:
        relocate_workproducts(loc, DESIGN_RELOCATE)
        new_loc = DESIGN_RELOCATE
    write_state("paused", location=new_loc, reason=reason or "pause", target_files=[f.name for f in files])
    ok("已暂停 MIMS 常驻加载。升级（/mims update）不受影响（全局操作）。")


def append_active_block(f):
    """detached/absent → 按初始化流程追加 active block（不破坏已有用户内容）。"""
    tpl = read_template("claude-md-template.md").rstrip("\n") + "\n"
    cur = f.read_text(encoding="utf-8") if f.exists() else ""
    replace_in_file(f, cur.rstrip("\n") + "\n\n" + tpl)


def cmd_persist(relocate_root):
    files = entry_files_with_block()
    loc = read_state_location()
    if not files:
        # detached/absent：按初始化流程追加 active block
        appended = []
        for f in ENTRY_FILES:
            if f.name == "CLAUDE.md" or f.exists():
                append_active_block(f)
                appended.append(f.name)
        for fn in appended:
            ok(f"{fn} → active（append，原本无 managed block）")
        target_files = appended
    else:
        changed = apply_template("active", reason="persist")
        for f, gran in changed:
            ok(f"{f.name} → active（{gran}）")
        target_files = [f.name for f in files]
    new_loc = loc
    if relocate_root and loc not in (".", ""):
        relocate_workproducts(loc, ".")
        new_loc = "."
    write_state("active", location=new_loc, reason="persist", target_files=target_files)
    ok("已重新持久化 MIMS（active）。")


def cmd_detach():
    files = entry_files_with_block()
    if not files:
        die("当前项目入口无 MIMS managed block。")
    for f in files:
        text = f.read_text(encoding="utf-8")
        parts = split_text(text)
        if not parts:
            continue
        before, _block, after = parts
        if outside_is_mims_only(before, after):
            # 整文件只剩 MIMS 内容→清空为占位
            replace_in_file(f, f"# {f.stem}\n\n（MIMS managed block 已移除。如需恢复运行 /mims design 或 /mims persist。）\n")
        else:
            replace_in_file(f, before.rstrip("\n") + "\n" + after.lstrip("\n"))
        ok(f"{f.name} → detached（移除 managed block）")
    write_state("detached", location=read_state_location(), reason="detach", target_files=[f.name for f in files])
    warn("已 detach（仅移除入口 block，未删除设计产物或全局 MIMS）。")


def cmd_resume():
    loc = read_state_location()
    info("resume 为会话级行为（不改文件）。按以下依据恢复：")
    print(f"  设计产物位置：{loc}")
    for wp in WORK_PRODUCTS:
        p = Path(loc) / wp
        print(f"    {wp}: {'✓' if p.exists() else '✗'}")
    # 验证模型可读 + 展示设计进度，便于定位从哪继续
    model = Path(loc) / "domain-model.yaml"
    if model.exists():
        try:
            txt = model.read_text(encoding="utf-8")
            ph = re.search(r'design_phase:\s*"([^"]*)"', txt)
            cs = re.search(r'current_step:\s*"([^"]*)"', txt)
            if ph or cs:
                print(f"  设计进度：phase={ph.group(1) if ph else '?'}  current_step={cs.group(1) if cs else '?'}")
            else:
                warn("domain-model.yaml 无 design_progress 元数据，将按 confidence_level 推断或从 P1 开始。")
        except Exception as e:
            warn(f"读取 domain-model.yaml 失败：{e}")
    else:
        warn(f"未在 {loc}/ 找到 domain-model.yaml（可能未初始化或位置已变）。")
    info("读取 .claude/skills/mims/SKILL.md，按 metadata.design_progress 恢复进度。")
    info("如需重新常驻，运行 /mims persist。")


def main():
    ap = argparse.ArgumentParser(description="MIMS 项目生命周期")
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("status")
    sub.add_parser("selfcheck")
    pp = sub.add_parser("persist")
    pp.add_argument("--move-root", action="store_true", help="同时把工作产品从 design/ 搬回根目录")
    sub.add_parser("detach")
    sub.add_parser("resume")
    p = sub.add_parser("pause")
    p.add_argument("--move-design", action="store_true", help="同时把工作产品搬到 design/")
    p.add_argument("--reason", default="")
    args = ap.parse_args()
    if args.cmd == "status":
        cmd_status()
    elif args.cmd == "selfcheck":
        cmd_selfcheck()
    elif args.cmd == "pause":
        cmd_pause(args.move_design, args.reason)
    elif args.cmd == "persist":
        cmd_persist(args.move_root)
    elif args.cmd == "detach":
        cmd_detach()
    elif args.cmd == "resume":
        cmd_resume()


if __name__ == "__main__":
    main()
