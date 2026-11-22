# -*- coding: utf-8 -*-
# run_checks.py : รัน sync_core (ดูอย่างเดียว) + verify_core + next_magic (+ คอมไพล์ถ้าระบุ)
# แล้วรวมผลเป็นไฟล์เดียว tools/out/RUN_REPORT.txt เพื่อวางให้ AI
# ไม่แก้ไฟล์โค้ดใดๆ ไม่คัดลอก Core (sync_core ถูกตอบ N เสมอ) ไม่แตะ GitHub
#   python tools/run_checks.py
#   python tools/run_checks.py --compile Strategies/Demo/v1.0.0/Demo_EA_TH.mq5 --compile Strategies/Demo/v1.0.0/Demo_EA_EN.mq5 --metaeditor "W:/MT5/MetaEditor64.exe" --portable
import argparse
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOOLS = ROOT / "tools"
OUT = TOOLS / "out"
FLAG = re.compile(r"(ERROR|WARN|DIFF|MISSING|EXTRA|CHANGED|ล้าสมัย|ซ้ำ)", re.I)


def run(cmd, stdin_text=None, timeout=180):
    env = dict(os.environ)
    env["PYTHONIOENCODING"] = "utf-8"
    try:
        p = subprocess.run(cmd, cwd=str(ROOT), input=stdin_text, capture_output=True, text=True,
                           encoding="utf-8", errors="replace", timeout=timeout, env=env)
        return p.returncode, (p.stdout or "") + (p.stderr or "")
    except subprocess.TimeoutExpired:
        return 124, "TIMEOUT (เกิน %d วินาที)" % timeout
    except FileNotFoundError as e:
        return 127, "ไม่พบโปรแกรม: %s" % e


def read_log(path):
    if not path.is_file():
        return ""
    raw = path.read_bytes()
    for enc in ("utf-16", "utf-8-sig", "cp874", "latin-1"):
        try:
            return raw.decode(enc)
        except UnicodeError:
            continue
    return ""


def section(title, code, text, lines):
    lines.append("")
    lines.append("## " + title + "  (exit code " + str(code) + ")")
    flagged = [ln for ln in text.splitlines() if FLAG.search(ln)]
    if flagged:
        lines.append("--- บรรทัดสำคัญ ---")
        lines.extend(flagged[:80])
    lines.append("--- ผลเต็ม ---")
    lines.append(text.strip() or "(ไม่มีข้อความ)")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--compile", action="append", default=[], help="ไฟล์ .mq5 ที่จะคอมไพล์ (path ใน Repo)")
    ap.add_argument("--metaeditor", default="", help="path ของ MetaEditor64.exe")
    ap.add_argument("--portable", action="store_true", help="MT5 แบบ Portable")
    ap.add_argument("--sync-target", default="", help="ส่งต่อให้ sync_core --target")
    args = ap.parse_args()

    OUT.mkdir(parents=True, exist_ok=True)
    py = sys.executable
    lines = ["RUN REPORT", "เวลา: " + datetime.now().strftime("%Y-%m-%d %H:%M:%S"), "โฟลเดอร์: " + str(ROOT)]

    c1, h = run(["git", "rev-parse", "--short", "HEAD"], timeout=20)
    c2, s = run(["git", "status", "--short"], timeout=20)
    lines.append("Commit: " + (h.strip() if c1 == 0 else "ตรวจไม่ได้"))
    if c2 == 0:
        lines.append("ไฟล์ที่ยังไม่ Commit: " + ("ไม่มี" if not s.strip() else "\n" + s.strip()))

    summary = []

    sync_cmd = [py, str(TOOLS / "sync_core.py")]
    if args.sync_target:
        sync_cmd += ["--target", args.sync_target]
    code, text = run(sync_cmd, stdin_text="N\n")
    section("sync_core (ดูอย่างเดียว ตอบ N)", code, text, lines)
    summary.append("sync_core=" + ("ตรงกันหมด" if code == 0 else "พบความต่าง/ผิดพลาด"))

    code, text = run([py, str(TOOLS / "verify_core.py")])
    section("verify_core", code, text, lines)
    last = [ln for ln in text.splitlines() if "สรุป" in ln]
    summary.append("verify_core=" + (last[-1].strip() if last else "exit " + str(code)))

    # next_magic ถูกตัดออกจากแม่แบบ (ไม่มีทะเบียน Magic กลาง)

    code, text = run([py, str(TOOLS / "check_docs.py")])
    section("check_docs (ตรวจเอกสาร)", code, text, lines)
    last = [ln for ln in text.splitlines() if "สรุป" in ln]
    summary.append("check_docs=" + (last[-1].strip() if last else "exit " + str(code)))

    for src in args.compile:
        if not args.metaeditor:
            lines += ["", "## คอมไพล์ " + src, "ข้าม: ไม่ได้ระบุ --metaeditor ให้กด F7 ใน MetaEditor แล้วคัดลอกผลมาเอง"]
            summary.append("compile " + Path(src).name + "=ข้าม (ทำเอง)")
            continue
        target = (ROOT / src).resolve()
        log = OUT / (Path(src).stem + ".compile.log")
        if log.exists():
            log.unlink()
        cmd = [args.metaeditor, "/compile:" + str(target), "/log:" + str(log)]
        if args.portable:
            cmd.append("/portable")
        code, text = run(cmd, timeout=240)
        body = read_log(log)
        m = re.findall(r"(\d+)\s+errors?,\s*(\d+)\s+warnings?", body)
        result = ("errors=%s warnings=%s" % m[-1]) if m else "อ่านผลไม่ได้ (ตรวจ log ด้านล่าง)"
        section("คอมไพล์ " + src + " : " + result, code, body or text, lines)
        summary.append("compile " + Path(src).name + "=" + result)

    lines += ["", "## สรุป", " | ".join(summary)]
    report = OUT / "RUN_REPORT.txt"
    report.write_text("\n".join(lines), encoding="utf-8")
    print("\n".join(summary))
    print("บันทึกรายงานที่:", report)
    print("เปิดไฟล์นี้ คัดลอกทั้งหมดไปวางให้ AI")
    return 0


if __name__ == "__main__":
    sys.exit(main())
