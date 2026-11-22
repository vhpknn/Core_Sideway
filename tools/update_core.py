# -*- coding: utf-8 -*-
"""
update_core.py - นำ Core รุ่นใหม่จาก EA_Platform_Core เข้ากลยุทธ์ เป็นโฟลเดอร์รุ่นใหม่ข้างของเดิม (รุ่นเก่าแช่แข็ง)
ใช้: python tools/update_core.py --platform <โฟลเดอร์ EA_Platform_Core ที่ checkout ตาม tag> --version v1.0.2
     ตัวเลือก: --strategy <ชื่อ> (ถ้ามีหลายโฟลเดอร์) | --from-version v1.1 | --apply (เขียนจริงทันที ไม่งั้นแสดงแผนแล้วถาม Y/N)
ทำอะไร: 1) ตรวจ platform (tag/commit/ความสะอาด) 2) เทียบ Core เดิมกับใหม่ + เทียบ Core_StrategyAPI.mqh
         3) สร้าง Core/<รุ่นใหม่>/include + PINNED_FROM.txt 4) สร้าง Strategies/<ชื่อ>/<รุ่นใหม่> จากรุ่นเดิม แล้วเปลี่ยน Core เป็นรุ่นใหม่ + CORE_MANIFEST.txt
         5) เขียน docs/work/CORE_UPDATE_<เดิม>_to_<ใหม่>.md  ไม่แตะรุ่นเดิม ไม่ Commit ไม่ติด tag
"""
import argparse, datetime, difflib, hashlib, os, re, shutil, subprocess, sys

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass


def sha(path):
    return hashlib.sha256(open(path, "rb").read()).hexdigest()


def files_of(d):
    return {f: sha(os.path.join(d, f)) for f in sorted(os.listdir(d)) if os.path.isfile(os.path.join(d, f)) and f.endswith(".mqh")}


def vkey(v):
    return tuple(int(x) for x in re.findall(r"\d+", v))


def git(args, cwd):
    try:
        r = subprocess.run(["git"] + args, cwd=cwd, capture_output=True, text=True)
        return r.returncode, r.stdout.strip()
    except Exception:
        return 127, ""


def find_root():
    d = os.path.abspath(os.path.dirname(__file__))
    for _ in range(4):
        if os.path.isdir(os.path.join(d, "Strategies")) and os.path.isdir(os.path.join(d, "Core")):
            return d
        d = os.path.dirname(d)
    return None


def write_manifest(core_dir, path, version):
    files = files_of(core_dir)
    lines = ["CORE_MANIFEST", "core_version=%s" % version, "source=Core/%s/include" % version,
             "synced_at=%s" % datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S"), "files=%d" % len(files)]
    for n in sorted(files, key=lambda x: x.lower()):
        lines.append("%s  %s" % (files[n], n))
    open(path, "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--platform", required=True)
    ap.add_argument("--version", required=True)
    ap.add_argument("--strategy")
    ap.add_argument("--from-version")
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()

    root = find_root()
    if not root:
        print("[ERROR] หาโฟลเดอร์ Repo ไม่เจอ")
        return 2
    plat = os.path.abspath(a.platform)
    newv = a.version
    src = os.path.join(plat, "Core", newv, "include")
    if not os.path.isdir(src):
        print("[ERROR] ไม่พบ %s (ตรวจว่า checkout ตาม tag ถูกต้อง และชื่อรุ่นตรง)" % src)
        return 2

    sroot = os.path.join(root, "Strategies")
    names = [d for d in os.listdir(sroot) if os.path.isdir(os.path.join(sroot, d))]
    if a.strategy:
        names = [a.strategy]
    if len(names) != 1:
        print("[ERROR] ระบุ --strategy ให้ชัด พบโฟลเดอร์: %s" % ", ".join(names))
        return 2
    name = names[0]
    vers = sorted([d for d in os.listdir(os.path.join(sroot, name)) if re.fullmatch(r"v\d+(\.\d+)*", d)], key=vkey)
    oldv = a.from_version or (vers[-1] if vers else None)
    if not oldv or oldv not in vers:
        print("[ERROR] ไม่พบรุ่นเดิมของ %s (มี: %s)" % (name, ", ".join(vers)))
        return 2
    if oldv == newv:
        print("[ERROR] รุ่นใหม่เท่ากับรุ่นเดิม ใช้ sync_core สำหรับซ่อมสำเนาเดิม")
        return 2
    new_core = os.path.join(root, "Core", newv)
    new_strat = os.path.join(sroot, name, newv)
    if os.path.exists(new_core) or os.path.exists(new_strat):
        print("[ERROR] มี Core/%s หรือ Strategies/%s/%s อยู่แล้ว ไม่เขียนทับ" % (newv, name, newv))
        return 2

    rc, tag = git(["describe", "--tags", "--exact-match"], plat)
    rc2, commit = git(["rev-parse", "HEAD"], plat)
    rc3, dirty = git(["status", "--porcelain"], plat)
    tag = tag if rc == 0 else ""
    commit = commit if rc2 == 0 else "unknown"
    print("Platform:", plat)
    print("  tag=%s commit=%s" % (tag or "(ไม่มี tag ตรงกับ commit นี้)", commit))
    warn = []
    if not tag:
        warn.append("platform ไม่ได้ checkout ตรงกับ tag ใดๆ")
    if rc3 == 0 and dirty:
        warn.append("platform มีไฟล์ที่ยังไม่ Commit")
    for w in warn:
        print("  [WARN] " + w)

    old_src = os.path.join(root, "Core", oldv, "include")
    if not os.path.isdir(old_src):
        old_src = os.path.join(sroot, name, oldv, "Core", "include")
    of, nf = files_of(old_src), files_of(src)
    added = sorted(set(nf) - set(of))
    removed = sorted(set(of) - set(nf))
    changed = sorted(n for n in nf if n in of and nf[n] != of[n])
    api = "Core_StrategyAPI.mqh"
    api_changed = (api in changed) or (api in removed) or (api in added)
    if api_changed or removed:
        level = "สูง (API เปลี่ยนหรือมีไฟล์ถูกลบ: คอมไพล์อาจล้ม ต้องแก้กลยุทธ์และทดสอบเต็ม)"
    elif added or any(n in changed for n in ("Core_Inputs.mqh", "Core_InputsEN.mqh", "Core_Runtime.mqh", "Core_Engine.mqh")):
        level = "ปานกลาง (มี Input/ไฟล์เพิ่มหรือแก้ลำดับทำงาน: ทดสอบส่วนที่เพิ่ม + ผู้เรียกทั้งหมด)"
    elif changed:
        level = "ต่ำ (แก้ภายใน ไม่เปลี่ยน API: คอมไพล์ + smoke ชุดมาตรฐาน)"
    else:
        level = "ไม่มีความต่าง"
    print("\nเทียบ Core %s -> %s: เพิ่ม %d ลบ %d แก้ %d" % (oldv, newv, len(added), len(removed), len(changed)))
    for n in added:
        print("  + " + n)
    for n in removed:
        print("  - " + n)
    for n in changed:
        print("  ~ " + n)
    print("ระดับความเสี่ยง (ประเมินจากไฟล์ที่เปลี่ยน เป็นการประมาณ): " + level)
    print("แผน: สร้าง Core/%s/include, Strategies/%s/%s (คัดลอกจาก %s แล้วเปลี่ยน Core), docs/work/CORE_UPDATE_%s_to_%s.md" % (newv, name, newv, oldv, oldv, newv))

    if not a.apply and sys.stdin.isatty():
        if input("\nเขียนไฟล์จริงไหม? (Y/N): ").strip().lower() == "y":
            a.apply = True
    if not a.apply:
        print("\nดูอย่างเดียว ยังไม่เขียนไฟล์ ใส่ --apply เพื่อเขียนจริง")
        return 0

    tmp_core = new_core + "_tmp"
    tmp_strat = new_strat + "_tmp"
    try:
        os.makedirs(os.path.join(tmp_core, "include"))
        for n in nf:
            shutil.copy2(os.path.join(src, n), os.path.join(tmp_core, "include", n))
        open(os.path.join(tmp_core, "PINNED_FROM.txt"), "w", encoding="utf-8", newline="\n").write(
            "PINNED_FROM\ncore_version=%s\nsnapshot_of=Core/%s/include\nsource_repo=%s\nsource_commit=%s\nsource_tag=%s\npinned_date=%s\nfiles=%d\n"
            "rule=อ่านอย่างเดียว ห้ามแก้ ถ้าต้องการ Core ใหม่ให้ใช้ tools/update_core.py\n"
            % (newv, newv, os.path.basename(plat), commit, tag, datetime.date.today().isoformat(), len(nf)))
        shutil.copytree(os.path.join(sroot, name, oldv), tmp_strat, ignore=shutil.ignore_patterns("Core_backup"))
        shutil.rmtree(os.path.join(tmp_strat, "Core"), ignore_errors=True)
        os.makedirs(os.path.join(tmp_strat, "Core", "include"))
        for n in nf:
            shutil.copy2(os.path.join(src, n), os.path.join(tmp_strat, "Core", "include", n))
        write_manifest(os.path.join(tmp_strat, "Core", "include"), os.path.join(tmp_strat, "Core", "CORE_MANIFEST.txt"), newv)
        os.replace(tmp_core, new_core)
        os.replace(tmp_strat, new_strat)
    except Exception as e:
        shutil.rmtree(tmp_core, ignore_errors=True)
        shutil.rmtree(tmp_strat, ignore_errors=True)
        print("[ERROR] ล้มเหลว ไม่ได้สร้างโฟลเดอร์ใหม่: %s" % e)
        return 1

    diff = ""
    if api in of and api in nf:
        d = list(difflib.unified_diff(open(os.path.join(old_src, api), encoding="utf-8-sig", errors="replace").read().splitlines(),
                                      open(os.path.join(src, api), encoding="utf-8-sig", errors="replace").read().splitlines(),
                                      "เดิม " + oldv, "ใหม่ " + newv, lineterm="", n=2))
        diff = "\n".join(d[:200]) if d else "(ไม่มีความต่าง)"
    os.makedirs(os.path.join(root, "docs", "work"), exist_ok=True)
    doc = os.path.join(root, "docs", "work", "CORE_UPDATE_%s_to_%s.md" % (oldv, newv))
    L = ["# CORE UPDATE: %s -> %s (%s)" % (oldv, newv, name), "",
         "วันที่: %s | Core ต้นทาง: %s commit %s tag %s" % (datetime.date.today().isoformat(), os.path.basename(plat), commit, tag or "(ไม่มี)"), "",
         "ระดับความเสี่ยง (ประเมินจากไฟล์ที่เปลี่ยน เป็นการประมาณ): " + level, "",
         "## ไฟล์ที่เปลี่ยน", "| สถานะ | ไฟล์ |", "|---|---|"]
    L += ["| เพิ่ม | `%s` |" % n for n in added] + ["| ลบ | `%s` |" % n for n in removed] + ["| แก้ | `%s` |" % n for n in changed]
    L += ["", "## เทียบ Core_StrategyAPI.mqh", "```text", diff or "(ไฟล์ไม่มีในรุ่นใดรุ่นหนึ่ง)", "```", "",
          "## รายการที่ต้องทำ (ติ๊กทีละข้อ)",
          "- [ ] อ่านความต่างด้านบน และ CHANGELOG ของ Core ฝั่ง platform",
          "- [ ] คอมไพล์ EA 3 ตัวของ Strategies/%s/%s ต้อง 0 errors 0 warnings (ถ้าล้ม แก้ที่กลยุทธ์ ห้ามแก้ Core)" % (name, newv),
          "- [ ] รัน tools\\run_checks.bat ต้อง sync_core ตรงกันหมด verify_core ERROR 0 check_docs ERROR 0",
          "- [ ] ตรวจไฟล์ .set ในโฟลเดอร์ Set ของรุ่นใหม่ (คัดลอกมาจากรุ่นเดิม) และค่า Input ใหม่ของ Core (ถ้ามี)",
          "- [ ] ทดสอบ Demo ตามระดับความเสี่ยง บันทึกใน docs/work/TEST_MATRIX.md",
          "- [ ] อัปเดต docs/work/CURRENT_STATE.md และ docs/work/LOG.md",
          "- [ ] Commit เอกสารปิดงาน แล้วติด tag %s-%s-r0 ที่ Commit นั้น" % (name.lower(), newv), "",
          "รุ่นเดิม Strategies/%s/%s แช่แข็ง ย้อนกลับได้โดยใช้โฟลเดอร์เดิม" % (name, oldv)]
    open(doc, "w", encoding="utf-8", newline="\n").write("\n".join(L) + "\n")
    print("\nเสร็จแล้ว: Core/%s, Strategies/%s/%s, %s" % (newv, name, newv, os.path.relpath(doc, root)))
    print("ต่อไป: เปิดไฟล์ CORE_UPDATE แล้วทำตามรายการ (คอมไพล์ > run_checks > ทดสอบ > Commit > tag)")
    return 0


if __name__ == "__main__":
    sys.exit(main())