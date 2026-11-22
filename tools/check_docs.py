# -*- coding: utf-8 -*-
# check_docs.py (แม่แบบ New_Strategies): ตรวจความสอดคล้องของเอกสาร (อ่านอย่างเดียว ไม่แก้ไฟล์ใด)
#   python tools/check_docs.py
# ตรวจ: ไฟล์เอกสารหลักครบ, Core ฐานมี PINNED_FROM, เลขมติ D-NN ไม่เกินที่คัดลอกมา, เลขมติกลยุทธ์ S-NN ไม่ซ้ำและไม่ใช้ D-NN,
#       ตัวตนกลยุทธ์ (STRATEGY_IDENTITY.txt) ตรงกับโฟลเดอร์, ค่า {{...}} ที่ยังไม่ถูกเติม, path ที่เอกสารหลักอ้างถึงแต่ไม่มีไฟล์,
#       AI_READ_SCOPE เทียบกับรายการไฟล์ของ make_ai_bundle, สถานะ CURRENT_STATE ตามหลัง HEAD
# รหัสออก: 0 ไม่มี ERROR | 1 มี ERROR
import fnmatch
import importlib.util
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEC = ROOT / "docs" / "decisions"
PLATFORM_MAX = 30          # เลขมติ D-NN สูงสุดที่คัดลอกมากับแม่แบบนี้ (ปรับเมื่ออัปเดตแม่แบบ)

REQUIRED = [
    "README_FIRST.md", "TEMPLATE_VERSION",
    "docs/START_HERE.md", "docs/RULES.md", "docs/AI_READ_SCOPE.md", "docs/AI_START_PROMPT.md",
    "docs/SPEC_FORM.md", "docs/BLUEPRINT.md",
    "docs/handoff/HANDOFF_NEW_STRATEGY.md", "docs/handoff/JIGSAW_PATCH_RULE.txt",
    "docs/work/CURRENT_STATE.md", "docs/work/LOG.md", "docs/work/TEST_MATRIX.md",
    "docs/decisions/STRATEGY_DECISIONS.md",
]
LIVE_GLOBS = ["README_FIRST.md", "docs/*.md", "docs/handoff/*.md", "docs/work/*.md",
              "docs/decisions/STRATEGY_DECISIONS.md", "tools/README_tools.md"]
PATH_CHECK_DOCS = ["README_FIRST.md", "docs/START_HERE.md", "docs/RULES.md", "docs/AI_READ_SCOPE.md"]

ID_RE = re.compile(r"\bD-(\d{2})(?:\.\d+)?\b")
TICK_RE = re.compile(r"`([^`\n]+)`")
EXT_RE = re.compile(r"\.[A-Za-z0-9]{2,4}$")
SCOPE = ROOT / "docs" / "AI_READ_SCOPE.md"
STATE_FILE = ROOT / "docs" / "work" / "CURRENT_STATE.md"
STATE_MAX_BEHIND = 3
COMMIT_RE = re.compile(r"Commit ที่ Push แล้ว:\s*([0-9a-fA-F]{7,40})")

errors = []
warns = []


def err(msg):
    errors.append("[ERROR] " + msg)


def warn(msg):
    warns.append("[WARN] " + msg)


def read(p):
    try:
        return p.read_text(encoding="utf-8-sig")
    except (OSError, UnicodeDecodeError):
        return None


def rel(p):
    return p.relative_to(ROOT).as_posix()


def live_docs():
    out = []
    for g in LIVE_GLOBS:
        for f in sorted(ROOT.glob(g)):
            if f.is_file() and f not in out:
                out.append(f)
    return out


def check_required():
    for p in REQUIRED:
        if not (ROOT / p).is_file():
            err("ไม่พบไฟล์หลักของแม่แบบ: %s" % p)
    if not list((ROOT / "Core").glob("v*/PINNED_FROM.txt")):
        err("ไม่พบ Core/v*/PINNED_FROM.txt (ต้องระบุรุ่นและ Commit ของ Core ฐาน)")
    if not list((ROOT / "Core").glob("v*/include")):
        err("ไม่พบ Core/v*/include (Core ต้นฉบับที่ปักไว้)")


def check_decision_refs():
    for f in live_docs():
        text = read(f)
        if text is None:
            continue
        for n, line in enumerate(text.splitlines(), 1):
            for m in ID_RE.finditer(line):
                num = int(m.group(1))
                if num < 1 or num > PLATFORM_MAX:
                    err("%s:%d อ้างเลขมติ D-%02d ที่ไม่ได้คัดลอกมากับแม่แบบ (D-NN เป็นของแพลตฟอร์ม D-01 ถึง D-%02d; มติของกลยุทธ์ใช้ S-NN)"
                        % (rel(f), n, num, PLATFORM_MAX))


def check_strategy_decisions():
    f = DEC / "STRATEGY_DECISIONS.md"
    text = read(f)
    if text is None:
        return
    seen = {}
    for n, line in enumerate(text.splitlines(), 1):
        m = re.match(r"^\s*(?:\|\s*|#+\s*|[-*]\s*)(S-\d{2})\b", line)
        if m:
            sid = m.group(1)
            if sid in seen:
                err("เลขมติกลยุทธ์ซ้ำ %s (บรรทัด %d และ %d)" % (sid, seen[sid], n))
            seen[sid] = n
        if re.match(r"^\s*(?:\|\s*|#+\s*|[-*]\s*)D-\d{2}\b", line):
            err("STRATEGY_DECISIONS.md:%d ใช้เลข D-NN (ต้องเป็น S-NN ตาม R-9)" % n)


def identity():
    f = ROOT / "STRATEGY_IDENTITY.txt"
    text = read(f)
    if text is None:
        return None
    d = {}
    for line in text.splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            d[k.strip()] = v.strip()
    return d


def check_identity():
    d = identity()
    if d is None:
        print("ยังไม่ได้ตั้งชื่อกลยุทธ์ (ไม่มี STRATEGY_IDENTITY.txt) ถือเป็นแม่แบบ")
        return
    name = d.get("name", "")
    if not name or not (ROOT / "Strategies" / name).is_dir():
        err("STRATEGY_IDENTITY.txt ระบุ name=%s แต่ไม่พบ Strategies/%s" % (name, name))
    if (ROOT / "Strategies" / "Template").exists():
        warn("ยังมี Strategies/Template อยู่ทั้งที่ตั้งชื่อกลยุทธ์แล้ว")
    for f in live_docs():
        text = read(f)
        if text and re.search(r"\{\{[A-Z_]+\}\}", text):
            warn("%s ยังมีค่า {{...}} ที่ไม่ได้เติม" % rel(f))


def check_paths():
    for p in PATH_CHECK_DOCS:
        f = ROOT / p
        text = read(f) if f.is_file() else None
        if text is None:
            continue
        for n, line in enumerate(text.splitlines(), 1):
            for tok in TICK_RE.findall(line):
                t = tok.strip().replace("\\", "/")
                parts = [x for x in t.split() if "/" in x]
                t = parts[0] if parts else t
                if "/" not in t or not EXT_RE.search(t) or re.search(r"[<>*{}]", t) or t.startswith("..."):
                    continue
                if t.startswith("ai_bundle") or t.startswith("tools/out"):
                    continue
                if not (ROOT / t).exists():
                    warn("%s:%d อ้างถึง %s แต่ไม่พบไฟล์" % (p, n, t))


def git_out(args):
    try:
        p = subprocess.run(["git"] + args, cwd=str(ROOT), capture_output=True,
                           text=True, encoding="utf-8", errors="replace", timeout=20)
    except (OSError, subprocess.SubprocessError):
        return None
    return p.stdout.strip() if p.returncode == 0 else None


def check_state():
    text = read(STATE_FILE)
    if text is None:
        return
    m = COMMIT_RE.search(text)
    if not m:
        if "Commit ที่ Push แล้ว" in text and "ยังไม่มี" in text:
            return
        warn("docs/work/CURRENT_STATE.md ไม่มี 'Commit ที่ Push แล้ว: <รหัสจริง>'")
        return
    sha = m.group(1)
    if git_out(["rev-parse", "--git-dir"]) is None:
        return
    if git_out(["cat-file", "-e", sha + "^{commit}"]) is None:
        warn("CURRENT_STATE.md อ้าง Commit %s ที่ไม่พบใน Repo นี้" % sha)
        return
    behind = git_out(["rev-list", "--count", sha + "..HEAD"])
    if behind and behind.isdigit() and int(behind) > STATE_MAX_BEHIND:
        warn("CURRENT_STATE.md บันทึก Commit %s ตามหลัง HEAD อยู่ %s Commit (เกิน %d) ตรวจว่าบันทึกยังเป็นปัจจุบัน"
             % (sha, behind, STATE_MAX_BEHIND))


def parse_scope():
    text = read(SCOPE)
    if text is None:
        return None
    allowed, forbidden = [], []
    mode = None
    for n, line in enumerate(text.splitlines(), 1):
        if line.startswith("## "):
            if "ห้ามอ่าน" in line:
                mode = "forbidden"
            elif "ทุกเฟส" in line or re.search(r"เฟส \d", line):
                mode = "allowed"
            else:
                mode = None
            continue
        if mode is None:
            continue
        if line.startswith("|") and line.count("|") >= 2:
            cell = line.split("|")[1]
        elif line.startswith("- "):
            cell = line
        else:
            continue
        for tok in TICK_RE.findall(cell):
            t = tok.strip().replace("\\", "/")
            if "/" not in t or re.search(r"[{}]", t):
                continue
            ph = bool(re.search(r"<[^>]*>", t))
            pat = re.sub(r"<[^>]*>", "*", t)
            (forbidden if mode == "forbidden" else allowed).append((pat, n, ph))
    return allowed, forbidden


def scope_exists(path):
    p = path.rstrip("/")
    if "*" in p or "?" in p:
        return bool(list(ROOT.glob(p)))
    return (ROOT / p).exists()


def scope_match(path, pattern):
    p = path.rstrip("/")
    q = pattern.rstrip("/")
    if p == q or p.startswith(q + "/"):
        return True
    return fnmatch.fnmatch(p, q) or fnmatch.fnmatch(p, q + "/*")


def bundle_listed():
    script = ROOT / "tools" / "make_ai_bundle.py"
    if not script.is_file():
        return []
    try:
        spec = importlib.util.spec_from_file_location("make_ai_bundle_scope", str(script))
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        docs, code = mod.all_listed()
        return list(docs) + list(code)
    except Exception as e:
        warn("อ่านรายการไฟล์จาก make_ai_bundle ไม่ได้: %s" % e)
        return []


def check_scope():
    parsed = parse_scope()
    if parsed is None:
        return
    allowed, forbidden = parsed
    if not allowed or not forbidden:
        warn("AI_READ_SCOPE.md อ่านรายการไม่ได้ (ตารางหรือรายการต้องมี path ใน backtick และมีหัวข้อ เฟส / ห้ามอ่าน)")
        return
    for path, n, ph in allowed:
        if not ph and not scope_exists(path):
            warn("AI_READ_SCOPE.md:%d รายการอนุญาตชี้ไปที่ไม่มี: %s" % (n, path))
        for bad, bn, _ in forbidden:
            if scope_match(path, bad):
                err("AI_READ_SCOPE.md:%d อยู่ทั้งรายการอนุญาต (%s) และห้ามอ่าน (บรรทัด %d: %s)" % (n, path, bn, bad))
    forb = [p for p, _, _ in forbidden]
    allow = [p for p, _, _ in allowed]
    for p in bundle_listed():
        if "/" not in p:
            continue
        if any(scope_match(p, f) for f in forb):
            err("Bundle รวมไฟล์ที่ AI_READ_SCOPE.md ห้ามอ่าน: %s" % p)
        elif not any(scope_match(p, a) for a in allow):
            warn("Bundle รวม %s ซึ่งไม่อยู่ในรายการอนุญาตของ AI_READ_SCOPE.md" % p)


def main():
    check_required()
    check_decision_refs()
    check_strategy_decisions()
    check_identity()
    check_paths()
    check_scope()
    check_state()
    for line in errors + warns:
        print(line)
    print("สรุป: ERROR %d | WARN %d" % (len(errors), len(warns)))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())