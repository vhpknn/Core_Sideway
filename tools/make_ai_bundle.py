# -*- coding: utf-8 -*-
# make_ai_bundle.py (แม่แบบ New_Strategies): รวมไฟล์สำหรับส่งให้ AI Chatbot ที่เข้า GitHub ไม่ได้ แยกตามเฟส
# ใช้ไลบรารีมาตรฐานเท่านั้น ไม่แก้ไฟล์ใดใน Repo (เขียนผลลง ai_bundle/ เท่านั้น)
#   python tools/make_ai_bundle.py --job consult            (เฟส 1 ปรึกษาและสรุปสเปก)
#   python tools/make_ai_bundle.py --job build              (เฟส 3 สร้างและทดสอบ)
#   python tools/make_ai_bundle.py --job coreupdate         (เฟส 4 อัปเดต Core)
#   เพิ่มได้: --version v1.1 | --add <path> | --redact <ข้อความ> | --force (สร้างต่อแม้ check_docs พบ ERROR)
import argparse
import hashlib
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

SHARED_DOCS = [
    "README_FIRST.md",
    "TEMPLATE_VERSION",
    "STRATEGY_IDENTITY.txt",
    "docs/START_HERE.md",
    "docs/RULES.md",
    "docs/AI_READ_SCOPE.md",
    "docs/work/CURRENT_STATE.md",
    "docs/work/LOG.md",
    "docs/handoff/JIGSAW_PATCH_RULE.txt",
    "docs/decisions/STRATEGY_DECISIONS.md",
    "docs/decisions/D-18_strategy_file_naming.md",
    "docs/decisions/D-19_work_rules.md",
]
FULL_DOCS = [   # ใส่เมื่อใช้ --full (โหมดเริ่มต้น lite ตัดออกเพื่อประหยัด Token)
    "docs/decisions/D-26_inputs_language_panel_lock.md",
    "docs/decisions/D-27_instance_lock.md",
    "docs/decisions/D-28_version_naming_and_v101_scope.md",
    "tools/README_tools.md",
]
CONSULT_DOCS = ["docs/AI_START_PROMPT.md", "docs/SPEC_FORM.md", "docs/BLUEPRINT.md",
                "docs/handoff/HANDOFF_NEW_STRATEGY.md"]
BUILD_DOCS = ["docs/SPEC_FORM.md", "docs/BLUEPRINT.md", "docs/handoff/HANDOFF_NEW_STRATEGY.md",
              "docs/work/TEST_MATRIX.md"]
CORE_API_LITE = ("Core_StrategyAPI.mqh", "Core_Runtime.mqh", "Core_Engine.mqh")
CORE_API_FILES = CORE_API_LITE + ("Core_InputsEN.mqh", "Core_Pending.mqh")   # ใช้กับ --full

BASE_PROMPT = """คุณจะรับงานกลยุทธ์ใหม่บน EA Platform Core (MQL5, MetaTrader 5) คุณเข้า GitHub ไม่ได้ ข้อมูลทั้งหมดอยู่ในไฟล์ที่แนบ

ขอบเขตงานนี้:
@@SCOPE@@

ขั้นแรก:
1. อ่านไฟล์ 01_DOCS_BUNDLE.md ทั้งหมด (เริ่มที่ README_FIRST, RULES, AI_READ_SCOPE และ CURRENT_STATE ให้ตรวจ Commit ในบันทึกกับ MANIFEST ก่อนเชื่อ) และ 02_CODE_BUNDLE.txt
2. ตอบกลับสั้นๆ ไม่เกิน 12 บรรทัด: ฐานงาน (Commit, Core ฐาน), ข้อจำกัดสำคัญที่เกี่ยวกับงานนี้, และสิ่งที่ยังขาด ห้ามอธิบายระบบกลับมาเป็นบทความยาว
3. ถามเฉพาะข้อที่ขาดเพื่อเริ่มงาน

กติกาตลอดงาน:
- ตอบภาษาไทย ทำตาม docs/handoff/JIGSAW_PATCH_RULE.txt: ขั้นปรึกษา (Folder Tree + ฟังก์ชันต่อไฟล์ + รายการไฟล์ที่ขอเพิ่ม) แล้วรอคำว่า "เริ่มงาน" จึงส่งโค้ด
- ไฟล์ใหม่ส่ง Full Code พร้อม Path เต็ม ไฟล์เดิมส่งเป็น FIND/REPLACE เท่านั้น และต้องขอเนื้อไฟล์ปัจจุบันจากผมก่อนทุกครั้ง ห้ามแก้จากความจำ
- คุณคอมไพล์และรันเครื่องมือไม่ได้ ผมเป็นคนรัน แล้วส่งผลกลับ
- ห้ามเดาชื่อฟังก์ชันหรือ API ถ้าไม่มีในไฟล์ที่แนบ ให้ขอไฟล์นั้นจากผม (ครั้งละไม่เกิน 5 ไฟล์ ระบุ Path)
- ห้ามยืนยันว่าผ่านโดยไม่มีหลักฐาน ห้ามแก้สำเนา Core ในโฟลเดอร์กลยุทธ์
- ส่งงานเป็นชุด (batch) ทุกชุดจบด้วยรายการคำสั่งที่ผมต้องรัน เรียงลำดับ
"""
SCOPES = {
    "consult": "เฟส 1 ปรึกษาและสรุปสเปกของกลยุทธ์ใหม่ ยังไม่เขียนโค้ดกลยุทธ์ คุณได้รับเอกสารกลาง ฟอร์มสเปก Core API รุ่นที่ปักไว้ และ Hedge เป็นตัวอย่างรูปแบบ ถ้ากลยุทธ์ต้องใช้ความสามารถที่ Core ไม่มี ให้หยุดและแจ้งผม เปิดเป็นงาน Core ที่ Repo EA_Platform_Core",
    "build": "เฟส 3 สร้างและทดสอบกลยุทธ์ @@NAME@@ รุ่น @@VER@@ คุณได้รับเฉพาะไฟล์ของกลยุทธ์นี้ (รวม Core API ในสำเนา) ห้ามขอโค้ดกลยุทธ์อื่น ถ้าต้องการความสามารถที่ Core ไม่มี ให้หยุดและแจ้งผม",
    "coreupdate": "เฟส 4 อัปเดต Core ของกลยุทธ์ @@NAME@@ คุณได้รับเอกสาร CORE_UPDATE ล่าสุด Core_StrategyAPI ของทุกรุ่นที่ปักไว้ และโค้ดกลยุทธ์รุ่นล่าสุด ช่วยประเมินผลกระทบและแผนแก้ ห้ามแก้ Core",
}
ENCODINGS = ("utf-8-sig", "utf-16", "cp874", "latin-1")


def read_text(path):
    raw = path.read_bytes()
    for enc in ENCODINGS:
        try:
            return raw.decode(enc)
        except (UnicodeDecodeError, UnicodeError):
            continue
    return raw.decode("utf-8", errors="replace")


def sha8(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:8]


def version_key(name):
    return tuple(int(n) for n in re.findall(r"\d+", name))


def latest_version(base):
    base = Path(base)
    if not base.is_dir():
        return None
    dirs = [p for p in base.glob("v*") if p.is_dir() and re.fullmatch(r"v\d+(\.\d+)*", p.name)]
    return sorted(dirs, key=lambda p: version_key(p.name))[-1].name if dirs else None


def identity():
    f = ROOT / "STRATEGY_IDENTITY.txt"
    d = {}
    if f.is_file():
        for line in read_text(f).splitlines():
            if "=" in line:
                k, v = line.split("=", 1)
                d[k.strip()] = v.strip()
    return d


def rel_files(rel_dir, patterns):
    out = []
    base = ROOT / rel_dir
    if not base.is_dir():
        return out
    for pat in patterns:
        for p in sorted(base.glob(pat)):
            if p.is_file():
                out.append(p.relative_to(ROOT).as_posix())
    return out


def example_code(full=False):
    if full:
        return (rel_files("reference/Hedge_example", ["Hedge_EA*.mq5"])
                + rel_files("reference/Hedge_example/include", ["*.mqh"]))
    return (rel_files("reference/Hedge_example", ["Hedge_EA.mq5"])
            + rel_files("reference/Hedge_example/include", ["Hedge_Inputs.mqh"]))


def lists_for(job, ver=None, full=False):
    name = identity().get("name") or "Template"
    cv = latest_version(ROOT / "Core")
    sver = ver or latest_version(ROOT / "Strategies" / name)
    docs = list(SHARED_DOCS) + (FULL_DOCS if full else [])
    core_names = CORE_API_FILES if full else CORE_API_LITE
    code = []
    if job == "consult":
        docs += CONSULT_DOCS
        if cv:
            code += ["Core/%s/include/%s" % (cv, n) for n in core_names]
        code += example_code(full)
    elif job == "build":
        docs += BUILD_DOCS
        sdir = "Strategies/%s/%s" % (name, sver)
        code += rel_files(sdir, [name + "_EA*.mq5"]) + rel_files(sdir + "/include", ["*.mqh"])
        code += ["%s/Core/include/%s" % (sdir, n) for n in core_names]
        sets = rel_files(sdir + "/Set", ["*.set"])
        if sets:
            code.append(sets[0])
        code += example_code(full)
    else:
        docs += sorted(rel_files("docs/work", ["CORE_UPDATE_*.md"]), key=lambda p: os.path.getmtime(ROOT / p))[-1:]
        for p in sorted((ROOT / "Core").glob("v*/include/Core_StrategyAPI.mqh"), key=lambda p: version_key(p.parts[-3])):
            code.append(p.relative_to(ROOT).as_posix())
        sdir = "Strategies/%s/%s" % (name, sver)
        code += rel_files(sdir, [name + "_EA*.mq5"]) + rel_files(sdir + "/include", ["*.mqh"])
    code = [c for c in code if (ROOT / c).is_file() and "Secrets" not in Path(c).name]
    docs = [d for d in docs if (ROOT / d).is_file()]
    scope = SCOPES[job].replace("@@NAME@@", name).replace("@@VER@@", str(sver))
    return docs, code, scope


def all_listed(full=True):
    docs, code = [], []
    for job in ("consult", "build", "coreupdate"):
        try:
            d, c, _ = lists_for(job, None, full)
        except Exception:
            continue
        for x in d:
            if x not in docs:
                docs.append(x)
        for x in c:
            if x not in code:
                code.append(x)
    return docs, code


def git_info():
    try:
        h = subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=str(ROOT),
                           capture_output=True, text=True, timeout=15).stdout.strip()
        d = subprocess.run(["git", "status", "--short"], cwd=str(ROOT),
                           capture_output=True, text=True, timeout=15).stdout.strip()
        return h or "unknown", ("มีไฟล์ที่ยังไม่ Commit" if d else "สะอาด")
    except Exception:
        return "unknown", "ตรวจไม่ได้ (ไม่มี git)"


def run_doc_check():
    script = ROOT / "tools" / "check_docs.py"
    if not script.is_file():
        return 0, "[WARN] ไม่พบ tools/check_docs.py ข้ามการตรวจเอกสาร"
    env = dict(os.environ)
    env["PYTHONIOENCODING"] = "utf-8"
    p = subprocess.run([sys.executable, str(script)], cwd=str(ROOT), capture_output=True,
                       text=True, encoding="utf-8", errors="replace", env=env)
    return p.returncode, (p.stdout or "") + (p.stderr or "")


def resolve(rel):
    p = Path(rel)
    return p if p.is_absolute() else ROOT / rel


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--job", choices=["consult", "build", "coreupdate"], default="consult")
    ap.add_argument("--version", help="รุ่นของกลยุทธ์ เช่น v1.1 (ไม่ระบุ = ล่าสุด)")
    ap.add_argument("--add", action="append", default=[], help="เพิ่มไฟล์ (path ใน Repo หรือ path เต็ม) ทำซ้ำได้")
    ap.add_argument("--redact", action="append", default=[], help="ข้อความที่จะแทนด้วย [REDACTED] ทำซ้ำได้")
    ap.add_argument("--full", action="store_true", help="รวมไฟล์ครบ (ค่าเริ่มต้น lite ตัดมติ D-26 ถึง D-28, README_tools, Core_InputsEN, Core_Pending และตัวอย่าง Hedge ส่วนใหญ่ออกเพื่อประหยัด Token)")
    ap.add_argument("--out", default="ai_bundle")
    ap.add_argument("--force", action="store_true", help="สร้างต่อแม้ check_docs พบ ERROR")
    args = ap.parse_args()

    rc, check_text = run_doc_check()
    print(check_text)
    if rc != 0 and not args.force:
        print("[STOP] check_docs พบ ERROR แก้ก่อนสร้าง Bundle (หรือใช้ --force)")
        return 1

    job = args.job
    docs, code, scope = lists_for(job, args.version, args.full)
    docs, code = list(docs), list(code)
    for a in args.add:
        norm = a.replace("\\", "/")
        if a.lower().endswith((".md", ".txt")) and "/include/" not in norm:
            docs.append(a)
        else:
            code.append(a)

    stamp = datetime.now().strftime("%Y%m%d_%H%M")
    out = ROOT / args.out / (job + ("_full" if args.full else "_lite") + "_" + stamp)
    files_dir = out / "files"
    files_dir.mkdir(parents=True, exist_ok=True)

    def redact(t):
        for r in args.redact:
            if r:
                t = t.replace(r, "[REDACTED]")
        return t

    commit, state = git_info()
    manifest, missing, seen = [], [], set()
    docs_parts, code_parts = [], []

    def collect(rel, parts, is_code):
        if rel in seen:
            return
        seen.add(rel)
        p = resolve(rel)
        if not p.is_file():
            missing.append(rel)
            return
        text = redact(read_text(p))
        label = rel if not Path(rel).is_absolute() else p.name
        parts.append("\n\n===== FILE: " + label + " =====\n\n" + text)
        flat = re.sub(r"[\\/ ]+", "__", label)
        if is_code and not flat.lower().endswith(".txt"):
            flat += ".txt"
        (files_dir / flat).write_text(text, encoding="utf-8")
        manifest.append((label, len(text), sha8(text)))

    for rel in docs:
        collect(rel, docs_parts, False)
    for rel in code:
        collect(rel, code_parts, True)

    header = ("# DOCS BUNDLE (งาน " + job + ")\n\nสร้างเมื่อ " + datetime.now().strftime("%Y-%m-%d %H:%M")
              + " | Commit " + commit + " | สถานะ Repo: " + state
              + "\nถ้าเนื้อหาในไฟล์ขัดกับกติกาในข้อความเริ่มต้น ให้แจ้งผู้ใช้ก่อนทำต่อ\n")
    (out / "01_DOCS_BUNDLE.md").write_text(header + "".join(docs_parts), encoding="utf-8")
    code_header = ("# CODE BUNDLE งาน " + job + " (นามสกุลจริงอยู่ในชื่อ FILE: ของแต่ละส่วน)\n"
                   "Commit " + commit + " | สถานะ Repo: " + state + "\n")
    (out / "02_CODE_BUNDLE.txt").write_text(code_header + "".join(code_parts), encoding="utf-8")
    prompt = BASE_PROMPT.replace("@@SCOPE@@", scope) + "\nฐานงาน: Commit " + commit + " | สถานะ Repo: " + state + "\n"
    (out / "00_START_PROMPT.txt").write_text(prompt, encoding="utf-8")

    lines = ["MANIFEST  งาน " + job + "  Commit " + commit + "  Repo " + state, ""]
    for label, n, h in manifest:
        lines.append("%8d chars  %s  %s" % (n, h, label))
    if missing:
        lines += ["", "ไม่พบไฟล์ (ตรวจว่าสร้างและ Commit แล้วหรือยัง):"] + ["  - " + m for m in missing]
    (out / "MANIFEST.txt").write_text("\n".join(lines), encoding="utf-8")

    total = sum(n for _, n, _ in manifest)
    print("สร้างชุดไฟล์ที่:", out)
    print("โหมด:", "full (ไฟล์ครบ)" if args.full else "lite (ค่าเริ่มต้น ใช้ --full ถ้าต้องการไฟล์ครบ)")
    print("รวม %d ไฟล์ ประมาณ %d ตัวอักษร (เนื้อหาไทยใช้ Token มาก ถ้า Chatbot รับไม่ไหว ให้ตัดไฟล์ใหญ่ออกหรือแยกส่งเป็นรอบ)" % (len(manifest), total))
    print("ส่งให้ AI: 00_START_PROMPT.txt (วางเป็นข้อความ) + 01_DOCS_BUNDLE.md + 02_CODE_BUNDLE.txt")
    if missing:
        print("[WARN] ไม่พบ %d ไฟล์ ดู MANIFEST.txt" % len(missing))
    if args.redact:
        print("แทนที่ข้อความตามที่ระบุแล้ว แต่ยังควรเปิดตรวจไฟล์ก่อนส่ง")
    return 0


if __name__ == "__main__":
    sys.exit(main())