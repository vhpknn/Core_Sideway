# -*- coding: utf-8 -*-
# log_entry.py : ช่วยเขียนรายการใหม่ใน docs/work/LOG_<งาน>.md (ต่อท้ายอย่างเดียว)
#   python tools/log_entry.py                          สร้างร่างรายการ (ไม่แตะ LOG) บันทึกที่ tools/out/LOG_DRAFT.txt
#   python tools/log_entry.py --type ปัญหา --title "หัวข้อสั้นๆ"
#   python tools/log_entry.py --append                 ต่อท้ายร่างที่กรอกครบแล้วเข้า LOG (ตรวจรูปแบบก่อน)
#   python tools/log_entry.py --tail 10                แสดง 10 รายการล่าสุด (ไว้วางให้ AI)
#   python tools/log_entry.py --log docs/work/LOG_Core_v1.0.1.md   ระบุไฟล์ LOG เอง
# เติมให้เอง: เวลา, เลขรายการถัดไป, รายชื่อไฟล์จาก git, สรุปผล run_checks, สถานะ Commit/Push
# ไม่ลบหรือแก้รายการเก่า ไม่ Commit ไม่ Push
# รหัสออก: 0 สำเร็จ | 1 ตรวจรูปแบบไม่ผ่าน | 2 ผิดพลาดของสภาพแวดล้อม
import argparse
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WORK = ROOT / "docs" / "work"
OUT = ROOT / "tools" / "out"
REPORT = OUT / "RUN_REPORT.txt"
DRAFT = OUT / "LOG_DRAFT.txt"

TYPES = ["งาน", "ตัดสินใจ", "ปัญหา", "ทดสอบ", "แชต"]
FIELDS = ["ทำอะไร", "ไฟล์", "ตรวจ", "ผู้ใช้ตัดสินใจ", "ข้อเสนอของ AI (รอยืนยัน)",
          "ปัญหา/สิ่งที่เรียนรู้", "Commit", "ขั้นถัดไป"]
HEAD_RE = re.compile(r"^### (\d{4}-\d{2}-\d{2} \d{2}:\d{2}) \| #(\d+) \| \[([^\]]+)\] (.+)$")
BLANK = "[[กรอก]]"
REVIEW = "[[ตรวจ]]"
MAX_FILES = 15


def setup_stdout():
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8")
        except (AttributeError, ValueError):
            pass


def git(args):
    try:
        p = subprocess.run(["git", "-c", "core.quotepath=false"] + args, cwd=str(ROOT),
                           capture_output=True, text=True, encoding="utf-8",
                           errors="replace", timeout=20)
    except (OSError, subprocess.SubprocessError):
        return None
    if p.returncode != 0:
        return None
    return p.stdout


def rel(p):
    try:
        return p.resolve().relative_to(ROOT.resolve()).as_posix()
    except ValueError:
        return str(p)


def find_log(arg):
    if arg:
        p = Path(arg)
        p = p if p.is_absolute() else ROOT / arg
        if not p.is_file():
            print("[ERROR] ไม่พบไฟล์ LOG: %s" % arg)
            return None
        return p
    default = WORK / "LOG.md"
    if default.is_file():
        return default
    files = sorted(WORK.glob("LOG_*.md"), key=lambda f: f.stat().st_mtime)
    if not files:
        print("[ERROR] ไม่พบ docs/work/LOG_*.md (สร้างจากแม่แบบ LOG_Core_v1.0.1.md ก่อน)")
        return None
    if len(files) > 1:
        print("[INFO] มี LOG หลายไฟล์ ใช้ไฟล์ที่แก้ล่าสุด: %s (เลือกเองด้วย --log)" % rel(files[-1]))
    return files[-1]


def parse_entries(text):
    lines = text.splitlines()
    heads = []
    in_fence = False
    for i, line in enumerate(lines):
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
            continue
        if not in_fence and line.startswith("### "):
            heads.append(i)
    entries = []
    for k, i in enumerate(heads):
        j = heads[k + 1] if k + 1 < len(heads) else len(lines)
        m = HEAD_RE.match(lines[i])
        entries.append((int(m.group(2)) if m else None, lines[i], "\n".join(lines[i:j]).rstrip()))
    return entries


def next_number(entries):
    nums = [n for n, _, _ in entries if n is not None]
    for n, head, _ in entries:
        if n is None:
            print("[WARN] หัวรายการรูปแบบไม่ตรงแม่แบบ: %s" % head)
    if not nums:
        return 1
    if len(set(nums)) != len(nums):
        print("[WARN] มีเลขรายการซ้ำใน LOG ตรวจไฟล์")
    full = list(range(min(nums), max(nums) + 1))
    if sorted(set(nums)) != full:
        print("[WARN] เลขรายการไม่ต่อเนื่อง (ข้ามเลข)")
    return max(nums) + 1


def report_summary():
    if not REPORT.is_file():
        return None
    try:
        lines = REPORT.read_text(encoding="utf-8-sig").splitlines()
    except (OSError, UnicodeDecodeError):
        return None
    for i in range(len(lines) - 1, -1, -1):
        if lines[i].strip() == "## สรุป":
            for nxt in lines[i + 1:]:
                if nxt.strip():
                    return nxt.strip(), datetime.fromtimestamp(REPORT.stat().st_mtime)
            break
    return None


def kind_of(code):
    if "?" in code or "A" in code:
        return "ใหม่"
    if "D" in code:
        return "ลบ"
    return "แก้"


def changed_files(skip):
    out = git(["status", "--porcelain", "-uall"])
    if out is None:
        return None, []
    items = []
    for line in out.splitlines():
        if len(line) < 4:
            continue
        xy, path = line[:2], line[3:]
        if " -> " in path:
            path = path.split(" -> ")[-1]
        path = path.strip().strip('"')
        if path == skip:
            continue
        items.append((path, kind_of(xy)))
    return True, items


def head_files():
    out = git(["show", "--name-status", "--format=", "HEAD"])
    if out is None:
        return []
    items = []
    for line in out.splitlines():
        parts = line.split("\t")
        if len(parts) >= 2:
            items.append((parts[-1], kind_of(parts[0])))
    return items


def commit_line(dirty):
    head = (git(["rev-parse", "--short", "HEAD"]) or "").strip() or "unknown"
    if dirty:
        return "ฐาน %s (ชุดนี้ยังไม่ Commit รายการนี้จะอยู่ใน Commit ถัดไป)" % head
    ahead = git(["rev-list", "--count", "@{u}..HEAD"])
    if ahead is None:
        return "%s (ตรวจสถานะ Push ไม่ได้)" % head
    if ahead.strip() != "0":
        return "%s (Commit แล้ว ยังไม่ Push %s Commit)" % (head, ahead.strip())
    return "%s (Push แล้ว)" % head


def suggest_title(items):
    if not items:
        return None
    kinds = [k for _, k in items]
    main = max(set(kinds), key=kinds.count)
    first = next(p for p, k in items if k == main)
    verb = {"แก้": "แก้", "ใหม่": "เพิ่ม", "ลบ": "ลบ"}[main]
    title = "%s %s" % (verb, Path(first).name)
    if len(items) > 1:
        title += " และอีก %d ไฟล์" % (len(items) - 1)
    return title


def numstat(args):
    res = {}
    out = git(args)
    if not out:
        return res
    for line in out.splitlines():
        p = line.split("\t")
        if len(p) == 3:
            res[p[2]] = (int(p[0]) if p[0].isdigit() else 0, int(p[1]) if p[1].isdigit() else 0)
    return res


def suggest_what(items, dirty, skip):
    if not items:
        return None
    spec = ["--", ".", ":(exclude)" + skip]
    if dirty:
        stat = numstat(["diff", "HEAD", "--numstat"] + spec)
        hunks = git(["diff", "HEAD", "-U0"] + spec) or ""
    else:
        stat = numstat(["show", "--numstat", "--format=", "HEAD"] + spec)
        hunks = git(["show", "-U0", "--format=", "HEAD"] + spec) or ""
    add = sum(a for a, _ in stat.values())
    dele = sum(d for _, d in stat.values())
    for p, k in items:
        f = ROOT / p
        if dirty and k == "ใหม่" and p not in stat and f.is_file():
            try:
                if f.stat().st_size < 1000000:
                    add += len(f.read_text(encoding="utf-8", errors="ignore").splitlines())
            except OSError:
                pass
    counts = {}
    for _, k in items:
        counts[k] = counts.get(k, 0) + 1
    parts = ["%s %d ไฟล์" % (k, counts[k]) for k in ("แก้", "ใหม่", "ลบ") if k in counts]
    text = "%s (บรรทัด +%d -%d)" % (", ".join(parts), add, dele)
    funcs = []
    for m in re.finditer(r"^@@ [^@]* @@ (.+)$", hunks, re.M):
        names = re.findall(r"([A-Za-z_]\w*)\s*\(", m.group(1))
        if names and names[-1] not in funcs:
            funcs.append(names[-1])
    if funcs:
        text += "; ฟังก์ชันที่ถูกแตะ: " + ", ".join(funcs[:8])
    return text + " (สรุปจาก git diff ไม่ใช่เจตนา) " + REVIEW


def print_state_context():
    f = WORK / "CURRENT_STATE.md"
    if not f.is_file():
        return
    lines = f.read_text(encoding="utf-8-sig").splitlines()
    shown = False
    for key in ("ขั้นถัดไป", "ยังไม่ทำ"):
        for i, line in enumerate(lines):
            if not (line.lstrip().startswith("#") and key in line):
                continue
            body = []
            for nxt in lines[i + 1:]:
                s = nxt.strip()
                if s.startswith("#"):
                    break
                if s:
                    body.append(s)
            if body:
                if not shown:
                    print("ข้อมูลช่วยคิด 'ขั้นถัดไป' (จาก CURRENT_STATE.md ซึ่งยังเป็นของก่อนชุดนี้ ไม่ได้เติมให้):")
                    shown = True
                print("  [%s]" % line.lstrip("# ").strip())
                for b in body[:5]:
                    print("    " + b)
            break


def build_draft(args, log_path, entries):
    n = next_number(entries)
    ok, items = changed_files(rel(log_path))
    dirty = bool(items)
    source = ""
    if ok and not items:
        items = head_files()
        source = " (จาก Commit ล่าสุด เพราะไม่มีไฟล์ค้าง)"
    if ok is None:
        file_line = BLANK + " (ไม่พบ git)"
    elif not items:
        file_line = "ไม่มี"
    else:
        shown = ["%s (%s)" % (p, k) for p, k in items[:MAX_FILES]]
        if len(items) > MAX_FILES:
            shown.append("และอีก %d ไฟล์" % (len(items) - MAX_FILES))
        file_line = ", ".join(shown) + source

    check = report_summary()
    if check:
        summary, mtime = check
        check_line = "run_checks %s: %s" % (mtime.strftime("%H:%M"), summary)
        mtimes = []
        for p, k in items:
            f = ROOT / p
            if k != "ลบ" and f.is_file() and dirty:
                mtimes.append(f.stat().st_mtime)
        if mtimes and max(mtimes) > mtime.timestamp():
            check_line += " (รายงานเก่ากว่าไฟล์ที่แก้ ให้รัน run_checks ซ้ำ)"
    else:
        check_line = BLANK + " (ไม่พบ tools/out/RUN_REPORT.txt)"
    if any(p.lower().endswith((".mq5", ".mqh")) for p, _ in items):
        check_line += " | คอมไพล์: " + BLANK

    title = args.title if args.title else BLANK
    what = BLANK
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    if items and not args.no_suggest:
        if not args.title:
            title = suggest_title(items) + " " + REVIEW
        w = suggest_what(items, dirty, rel(log_path))
        if w:
            what = w
            now = datetime.now().strftime("%Y-%m-%d %H:%M")
    return "\n".join([
        "### %s | #%03d | [%s] %s" % (now, n, args.type, title),
        "- ทำอะไร: " + what,
        "- ไฟล์: " + file_line,
        "- ตรวจ: " + check_line,
        "- ผู้ใช้ตัดสินใจ: ไม่มี",
        "- ข้อเสนอของ AI (รอยืนยัน): ไม่มี",
        "- ปัญหา/สิ่งที่เรียนรู้: ไม่มี",
        "- Commit: " + commit_line(dirty),
        "- ขั้นถัดไป: " + BLANK,
    ]) + "\n"


def validate(text, expected_number):
    problems = []
    lines = [ln for ln in text.splitlines() if ln.strip()]
    if not lines:
        return ["ร่างว่างเปล่า"]
    m = HEAD_RE.match(lines[0])
    if not m:
        return ["บรรทัดแรกไม่ตรงรูปแบบ '### <วันที่ เวลา> | #<เลข> | [<ประเภท>] <หัวข้อ>'"]
    if int(m.group(2)) != expected_number:
        problems.append("เลขรายการต้องเป็น #%03d (ร่างเป็น #%s)" % (expected_number, m.group(2)))
    if m.group(3) not in TYPES:
        problems.append("ประเภท [%s] ไม่อยู่ในรายการ %s" % (m.group(3), ", ".join(TYPES)))
    if "[[" in text:
        problems.append("ยังมีช่องที่ไม่ได้กรอกหรือยังไม่ได้ตรวจ (%s หรือ %s)" % (BLANK, REVIEW))
    for label in FIELDS:
        mm = re.search(r"^- %s:[ \t]*(\S.*)$" % re.escape(label), text, re.M)
        if not mm:
            problems.append("ขาดหรือว่างช่อง '- %s:'" % label)
    extra = [ln for ln in lines[1:] if ln.startswith("### ")]
    if extra:
        problems.append("ร่างมีหัวรายการมากกว่า 1 รายการ ต่อทีละรายการ")
    return problems


def cmd_append(args, log_path, entries):
    src = Path(args.append)
    src = src if src.is_absolute() else ROOT / args.append
    if not src.is_file():
        print("[ERROR] ไม่พบไฟล์ร่าง: %s" % args.append)
        return 2
    draft = src.read_text(encoding="utf-8-sig")
    problems = validate(draft, next_number(entries))
    if problems:
        print("[ERROR] ร่างยังต่อท้ายไม่ได้:")
        for p in problems:
            print("  - " + p)
        return 1
    current = log_path.read_text(encoding="utf-8-sig")
    sep = "" if current.endswith("\n") else "\n"
    with open(log_path, "a", encoding="utf-8", newline="\n") as f:
        f.write(sep + "\n" + draft.strip() + "\n")
    print("ต่อท้ายแล้วที่ %s" % rel(log_path))
    print("ขั้นต่อไป: อ่านทวนอีกครั้ง > อัปเดต docs/work/CURRENT_STATE.md > tools\\run_checks.bat > Commit และ Push")
    return 0


def cmd_tail(args, entries):
    chosen = [e for e in entries if e[0] is not None][-args.tail:]
    if not chosen:
        print("(ยังไม่มีรายการ)")
        return 0
    print("\n\n".join(e[2] for e in chosen))
    return 0


def main():
    setup_stdout()
    ap = argparse.ArgumentParser(description="ช่วยเขียนรายการใน LOG ของ docs/work")
    ap.add_argument("--log", default="", help="path ของไฟล์ LOG (ค่าเริ่มต้น: ไฟล์ LOG_*.md ที่แก้ล่าสุด)")
    ap.add_argument("--type", default="งาน", choices=TYPES, help="ประเภทรายการ")
    ap.add_argument("--title", default="", help="หัวข้อสั้นๆ ของรายการ")
    ap.add_argument("--append", nargs="?", const=str(DRAFT), default=None,
                    help="ต่อท้ายร่างที่กรอกครบแล้ว (ค่าเริ่มต้น tools/out/LOG_DRAFT.txt)")
    ap.add_argument("--tail", type=int, default=0, help="แสดง N รายการล่าสุด")
    ap.add_argument("--no-suggest", action="store_true", help="ไม่เติมหัวข้อและ 'ทำอะไร' ให้จาก git diff")
    args = ap.parse_args()

    log_path = find_log(args.log)
    if log_path is None:
        return 2
    entries = parse_entries(log_path.read_text(encoding="utf-8-sig"))

    if args.tail > 0:
        return cmd_tail(args, entries)
    if args.append is not None:
        return cmd_append(args, log_path, entries)

    draft = build_draft(args, log_path, entries)
    OUT.mkdir(parents=True, exist_ok=True)
    DRAFT.write_text(draft, encoding="utf-8", newline="\n")
    print(draft)
    print("-" * 60)
    print("บันทึกร่างที่: %s" % rel(DRAFT))
    if not args.no_suggest:
        print_state_context()
    print("ขั้นต่อไป:")
    print("  1. เปิดไฟล์ร่าง แทนที่ %s ด้วยข้อความจริง และตรวจค่าที่เติมให้ แล้วลบ %s ออก" % (BLANK, REVIEW))
    print("  2. ตรวจว่ามีเฉพาะสิ่งที่มีหลักฐาน แยก 'ผู้ใช้ตัดสินใจ' ออกจาก 'ข้อเสนอของ AI'")
    print("  3. python tools\\log_entry.py --append")
    return 0


if __name__ == "__main__":
    sys.exit(main())
