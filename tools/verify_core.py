# -*- coding: utf-8 -*-
"""verify_core: ตรวจความถูกต้องของ Core และไฟล์ของแต่ละกลยุทธ์
 1) สำเนา Core ตรงกับต้นฉบับ (CLEAN) และตรงกับ CORE_MANIFEST
 2) ค่าทุกตัวใน CoreUI_Theme.mqh เท่ากับธีมต้นฉบับ (หลังแปลง HUI_ -> CUI_)
 3) ไฟล์ .set: Comment / Magic / ช่วงของ TAG / ความยาว / ไม่ซ้ำ
 4) STRATEGY_* ใน EA ตรงทะเบียน Magic และ STRATEGY_MAGIC_NEXT ไม่ล้าสมัย
รหัสออก: 0 = ไม่มี ERROR, 1 = มี ERROR, 2 = ผิดพลาดของเครื่องมือ"""
import argparse
import re
import sys
from pathlib import Path

from _common import (ROOT, THEME_REF, all_core_includes, check_comment,
                     core_source_for_copy, find_core_copies,
                     find_strategy_dirs, latest_core_include, parse_ea_defines,
                     parse_registry, read_set, read_text, sha256_file)
# (next_magic ถูกตัดออกจากแม่แบบ: ไม่มีทะเบียน Magic กลาง)
from sync_core import compare

errors, warns = [], []


def err(msg):
    errors.append(msg)
    print("  [ERROR] " + msg)


def warn(msg):
    warns.append(msg)
    print("  [WARN]  " + msg)


def theme_defs(text):
    defs, in_block = {}, False
    rx = re.compile(r"^\s*#define\s+(\w+)\s+(.*?)\s*(?://.*)?$")
    for line in text.splitlines():
        s = line.strip()
        if s.startswith("/*"):
            in_block = True
        if in_block:
            if "*/" in s:
                in_block = False
            continue
        m = rx.match(line)
        if m and m.group(2).strip():
            defs[m.group(1)] = m.group(2).strip()
    return defs


def check_core_copies(src):
    print("\n[1] สำเนา Core เทียบต้นฉบับรุ่นเดียวกัน (D-28.1) ล่าสุด: %s" % src.relative_to(ROOT).as_posix())
    copies = find_core_copies()
    if not copies:
        warn("ไม่พบสำเนา Core ของกลยุทธ์ใด")
    for t in copies:
        ver, tsrc = core_source_for_copy(t)
        if ver is not None and tsrc is None:
            print(" - %s" % t.relative_to(ROOT).as_posix())
            err("ไม่พบ Core/%s/include ที่เป็นรุ่นเดียวกับสำเนานี้ (D-28.1)" % ver)
            continue
        if tsrc is None:
            tsrc = src
        print(" - %s  <-  %s" % (t.relative_to(ROOT).as_posix(), tsrc.relative_to(ROOT).as_posix()))
        for name, status in compare(tsrc, t):
            if status in ("DIFF", "MISSING"):
                err("%s: %s (ใช้ sync_core เพื่อซิงก์ ห้ามแก้ในสำเนา)" % (name, status))
            elif status == "EXTRA":
                warn("%s: ไฟล์เกินในสำเนา" % name)
        manifest = t.parent / "CORE_MANIFEST.txt"
        if not manifest.exists():
            warn("ไม่มี CORE_MANIFEST.txt (ยังไม่เคยรัน sync_core --apply)")
            continue
        text, _ = read_text(manifest)
        mv = re.search(r"^core_version=(\S+)", text, re.M)
        if not mv:
            warn("manifest ไม่มีบรรทัด core_version (ตรวจรุ่นไม่ได้)")
        elif ver is not None and mv.group(1) != ver:
            err("manifest ระบุ core_version=%s แต่โฟลเดอร์กลยุทธ์เป็นรุ่น %s (D-28.1)" % (mv.group(1), ver))
        for line in text.splitlines():
            m = re.match(r"^([0-9a-f]{64})\s+(\S+\.mqh)$", line)
            if m:
                f = t / m.group(2)
                if not f.exists():
                    err("manifest อ้างถึงไฟล์ที่ไม่มี: %s" % m.group(2))
                elif sha256_file(f) != m.group(1):
                    err("%s ถูกแก้หลัง sync (ไม่ตรง manifest)" % m.group(2))


def check_theme(src, ref):
    print("\n[2] ค่าธีม CoreUI_Theme.mqh (%s) เทียบ %s" % (src.parent.name, ref))
    new_file = src / "CoreUI_Theme.mqh"
    if not ref.exists():
        warn("ไม่พบไฟล์ธีมต้นฉบับ %s (ข้ามการตรวจ)" % ref)
        return
    if not new_file.exists():
        err("ไม่พบ CoreUI_Theme.mqh ใน Core ต้นฉบับ")
        return
    ref_defs = theme_defs(read_text(ref)[0])
    new_defs = theme_defs(read_text(new_file)[0])
    mapped = {("CUI_" + k[4:] if k.startswith("HUI_") else k): v for k, v in ref_defs.items()}
    for k, v in mapped.items():
        if k not in new_defs:
            err("ธีมขาด %s" % k)
        elif new_defs[k] != v:
            err("ธีม %s ค่าไม่ตรง: ต้นฉบับ=%s ใหม่=%s" % (k, v, new_defs[k]))
    for k in new_defs:
        if k not in mapped:
            warn("ธีมมีค่าที่ต้นฉบับไม่มี: %s" % k)
    print("  ตรวจแล้ว %d ค่า" % len(mapped))


def check_strategies():
    print("\n[3] กลยุทธ์: ทะเบียน Magic + EA + ไฟล์ .set")
    tags, _ = parse_registry()   # แม่แบบนี้ไม่มีทะเบียนกลาง (tags ว่าง = ข้ามการเทียบทะเบียน)
    strategies = find_strategy_dirs()
    if not strategies:
        warn("ไม่พบกลยุทธ์ (Strategies/<ชื่อ>/v*/<ชื่อ>_EA.mq5)")
    global_magics = {}
    for vdir, ea in strategies:
        name = vdir.parent.name
        print(" - %s (%s)" % (name, vdir.name))
        d = parse_ea_defines(ea)
        if not d["TAG"] or d["ORDINAL"] is None or d["BASE"] is None or d["NEXT"] is None:
            err("%s: ไม่พบ STRATEGY_TAG / ORDINAL / MAGIC_BASE / MAGIC_NEXT ครบใน EA" % name)
            continue
        reg = tags.get(d["TAG"])
        if tags and (not reg or reg[0] != d["ORDINAL"]):
            err("%s: TAG %s / ลำดับ %d ไม่ตรงทะเบียน" % (name, d["TAG"], d["ORDINAL"]))
        if d["BASE"] != d["ORDINAL"] * 10000:
            err("%s: STRATEGY_MAGIC_BASE %d != ลำดับ x 10000" % (name, d["BASE"]))
        ident = ROOT / "STRATEGY_IDENTITY.txt"
        if ident.exists():
            iv = dict(l.split("=", 1) for l in read_text(ident)[0].splitlines() if "=" in l)
            if iv.get("tag") != d["TAG"] or iv.get("magic_base") != str(d["BASE"]):
                err("%s: STRATEGY_IDENTITY.txt ไม่ตรงกับ #define ใน EA (tag หรือ magic_base)" % name)
        setdir = vdir / "Set"
        sets = sorted(setdir.glob("*.set")) if setdir.is_dir() else []
        if not sets:
            warn("%s: ไม่มีไฟล์ .set" % name)
        seen = {}
        for s in sets:
            vals, _ = read_set(s)
            raw = vals.get("InpMagicNumber", "").split("||")[0]
            comment = vals.get("InpTradeComment", "").split("||")[0]
            if not raw.isdigit():
                err("%s: ไม่มี InpMagicNumber ที่อ่านได้" % s.name)
                continue
            magic = int(raw)
            problem = check_comment(comment, d["TAG"], magic, d["ORDINAL"])
            if problem:
                err("%s: %s | Comment='%s'" % (s.name, problem, comment))
            if magic in seen:
                err("%s: Magic %d ซ้ำกับ %s" % (s.name, magic, seen[magic]))
            seen[magic] = s.name
            if magic in global_magics and global_magics[magic][0] != name:
                err("%s: Magic %d ซ้ำข้ามกลยุทธ์ กับ %s" % (s.name, magic, global_magics[magic][1]))
            global_magics[magic] = (name, s.name)
        used = list(seen.keys())
        if used and d["NEXT"] <= max(used):
            warn("%s: STRATEGY_MAGIC_NEXT=%d ล้าสมัย (ใช้แล้วถึง %d) แก้ #define ใน EA ให้มากกว่านี้"
                 % (name, d["NEXT"], max(used)))
        print("   ตรวจ .set แล้ว %d ไฟล์" % len(sets))


def main():
    ap = argparse.ArgumentParser(description="ตรวจ Core และไฟล์ของกลยุทธ์")
    ap.add_argument("--theme-ref", default=str(THEME_REF), help="ไฟล์ธีมต้นฉบับ HedgeUI_Theme.mqh")
    args = ap.parse_args()

    src = latest_core_include()
    if not src:
        print("[ERROR] ไม่พบ Core ต้นฉบับ (Core/v*/include)")
        return 2
    check_core_copies(src)
    for core_src in all_core_includes():
        check_theme(core_src, Path(args.theme_ref))
    check_strategies()

    print("\nสรุป: ERROR %d | WARN %d" % (len(errors), len(warns)))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())