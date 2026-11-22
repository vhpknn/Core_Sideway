# -*- coding: utf-8 -*-
"""sync_core: คัดลอก Core ต้นฉบับไปทับสำเนาของ EA (ตรวจก่อน สำรองไฟล์เดิม ถามยืนยัน)
รันตรง ๆ = ตรวจอย่างเดียว | --apply = คัดลอกจริง (ถามยืนยัน) | --yes = ข้ามคำถาม
รหัสออก: 0 = ตรงกันทั้งหมด, 1 = มีไฟล์ต่างกัน, 2 = ผิดพลาด"""
import argparse
import datetime
import shutil
import sys
from pathlib import Path

from _common import (ROOT, all_core_includes, core_source_for_copy, find_core_copies,
                     latest_core_include, sha256_file)

# ต้นฉบับ Core ของแต่ละสำเนา (D-28.1) main() เป็นผู้กรอก เพื่อให้ write_manifest บันทึกรุ่นที่ถูกต้อง
SRC_FOR = {}

def _rel(p):
    try:
        return Path(p).resolve().relative_to(ROOT).as_posix()
    except ValueError:
        return str(p)


def compare(src_dir, dst_dir):
    src = {p.name: p for p in Path(src_dir).glob("*.mqh")}
    dst = {p.name: p for p in Path(dst_dir).glob("*.mqh")} if Path(dst_dir).exists() else {}
    rows = []
    for name in sorted(src):
        if name not in dst:
            rows.append((name, "MISSING"))
        elif sha256_file(src[name]) == sha256_file(dst[name]):
            rows.append((name, "SAME"))
        else:
            rows.append((name, "DIFF"))
    for name in sorted(set(dst) - set(src)):
        rows.append((name, "EXTRA"))
    return rows


def write_manifest(src_dir, dst_dir):
    global SRC_FOR
    dst_dir = Path(dst_dir)
    src_dir = SRC_FOR.get(dst_dir.resolve(), src_dir)
    version = Path(src_dir).parent.name
    lines = ["CORE_MANIFEST",
             "core_version=%s" % version,
             "source=%s" % Path(src_dir).relative_to(ROOT).as_posix(),
             "synced_at=%s" % datetime.datetime.now().isoformat(timespec="seconds")]
    files = sorted(Path(src_dir).glob("*.mqh"))
    lines.append("files=%d" % len(files))
    for p in files:
        lines.append("%s  %s" % (sha256_file(dst_dir / p.name), p.name))
    manifest = dst_dir.parent / "CORE_MANIFEST.txt"
    manifest.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return manifest


def main():
    ap = argparse.ArgumentParser(description="ซิงก์ Core ต้นฉบับไปสำเนาของ EA")
    ap.add_argument("--src", help="โฟลเดอร์ include ของ Core ต้นฉบับ (ค่าเริ่มต้น = เวอร์ชันล่าสุดใน Core/)")
    ap.add_argument("--target", action="append", help="โฟลเดอร์ Core/include ของ EA (ระบุซ้ำได้ ค่าเริ่มต้น = ทุกกลยุทธ์)")
    ap.add_argument("--apply", action="store_true", help="คัดลอกจริง")
    ap.add_argument("--yes", action="store_true", help="ไม่ถามยืนยัน")
    args = ap.parse_args()

    src = Path(args.src).resolve() if args.src else latest_core_include()
    if not src or not src.is_dir():
        print("[ERROR] ไม่พบโฟลเดอร์ Core ต้นฉบับ (Core/v*/include)")
        return 2
    targets = [Path(t).resolve() for t in args.target] if args.target else find_core_copies()

    # D-28.1: สำเนาแต่ละตัวใช้ต้นฉบับรุ่นเดียวกับโฟลเดอร์กลยุทธ์ของมัน (--src ระบุเองได้)
    multi = len(all_core_includes()) > 1
    if multi and args.apply and not args.target:
        print("[ERROR] มี Core มากกว่าหนึ่งรุ่น ห้ามใช้ --apply โดยไม่ระบุ --target (D-28.1)")
        return 2

    def src_of(t):
        if args.src:
            return src
        ver, found = core_source_for_copy(t)
        if ver is None:
            return src
        return found

    for t in targets:
        s = src_of(t)
        if s is None:
            print("[ERROR] ไม่พบ Core ต้นฉบับรุ่นเดียวกับสำเนา %s (D-28.1)" % _rel(t))
            return 2
        SRC_FOR[Path(t).resolve()] = s
    if not targets:
        print("[ERROR] ไม่พบสำเนา Core ของกลยุทธ์ใด (Strategies/<ชื่อ>/v*/Core/include)")
        return 2

    print("ต้นฉบับ: %s" % ("ตามรุ่นของแต่ละสำเนา (D-28.1)" if (multi and not args.src) else _rel(src)))
    any_diff = False
    plans = []
    for t in targets:
        rows = compare(src_of(t), t)
        label = t.relative_to(ROOT).as_posix() if str(t).startswith(str(ROOT)) else str(t)
        print("\n== %s  <-  %s ==" % (label, _rel(src_of(t))))
        for name, status in rows:
            print("  %-8s %s" % (status, name))
            if status != "SAME":
                any_diff = True
        plans.append((t, rows))

    if not any_diff:
        print("\nทุกสำเนาตรงกับต้นฉบับ (CLEAN)")
        for t, _ in plans:
            if args.apply or not (t.parent / "CORE_MANIFEST.txt").exists():
                print("เขียน manifest: %s" % write_manifest(src, t))
        return 0

    if not args.apply:
        print("\nพบไฟล์ที่ต่างกัน (ยังไม่คัดลอก) ใช้ --apply เพื่อคัดลอกทับ (ไฟล์เดิมจะถูกสำรอง)")
        return 1

    if not args.yes:
        ans = input("\nพิมพ์ YES เพื่อคัดลอกทับ (ไฟล์เดิมจะถูกสำรองไว้): ").strip()
        if ans != "YES":
            print("ยกเลิก ไม่ได้คัดลอกอะไร")
            return 1

    stamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    for t, rows in plans:
        backup = t.parent / "Core_backup" / stamp
        for name, status in rows:
            if status in ("DIFF", "MISSING"):
                if status == "DIFF":
                    backup.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(t / name, backup / name)
                t.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src_of(t) / name, t / name)
                print("คัดลอก %s -> %s" % (name, t.relative_to(ROOT).as_posix()))
            elif status == "EXTRA":
                print("[เตือน] มีไฟล์เกินในสำเนา (ไม่ลบให้): %s" % name)
        print("เขียน manifest: %s" % write_manifest(src, t))
    return 0


if __name__ == "__main__":
    sys.exit(main())