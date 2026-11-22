# -*- coding: utf-8 -*-
"""
init_strategy.py - ตั้งชื่อกลยุทธ์จากแม่แบบ New_Strategies (ไม่มีทะเบียน Magic กลาง)
ใช้: python tools/init_strategy.py                       (ถามชื่อ TAG ลำดับ แสดงแผน แล้วถามยืนยัน Y/N)
     python tools/init_strategy.py --name SMC --tag SMC --ordinal 3
     เพิ่ม --apply เพื่อเขียนจริงทันที | --scan <โฟลเดอร์ที่เก็บ Repo ข้างเคียง> (ค่าเริ่มต้น: โฟลเดอร์แม่ของ Repo นี้)
ทำอะไร: เปลี่ยน Strategies/Template -> Strategies/<ชื่อ> (ชื่อไฟล์และข้อความ Template/TPL), ตั้ง TAG/ลำดับ/Magic ฐาน
         (Magic ฐาน = ลำดับ x 10000), เขียน STRATEGY_IDENTITY.txt, เติมค่าแทน {{NAME}} {{TAG}} {{ORDINAL}} {{MAGIC_BASE}} {{DATE}} ใน .md
         สแกน Repo ข้างเคียงและเตือนถ้า TAG/ลำดับ/Magic ฐานซ้ำ ไม่ Commit ไม่ git init ไม่เปลี่ยนชื่อโฟลเดอร์ Repo
"""
import argparse, datetime, glob, os, re, shutil, sys

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

KNOWN = {"HDG": (1, 10000), "PND": (2, 20000), "TDK": (7, 70000)}
TEXT_EXT = (".mq5", ".mqh", ".txt", ".md")


def read_text(path):
    raw = open(path, "rb").read()
    bom = raw.startswith(b"\xef\xbb\xbf")
    txt = raw.decode("utf-8-sig")
    crlf = "\r\n" in txt
    return txt.replace("\r\n", "\n"), bom, crlf


def write_text(path, txt, bom, crlf):
    if crlf:
        txt = txt.replace("\n", "\r\n")
    data = txt.encode("utf-8")
    if bom:
        data = b"\xef\xbb\xbf" + data
    open(path, "wb").write(data)


def find_root():
    d = os.path.abspath(os.path.dirname(__file__))
    for _ in range(4):
        if os.path.isfile(os.path.join(d, "TEMPLATE_VERSION")) or os.path.isdir(os.path.join(d, "Strategies")):
            return d
        d = os.path.dirname(d)
    return None


def kv(path):
    out = {}
    if os.path.isfile(path):
        for line in read_text(path)[0].splitlines():
            if "=" in line:
                k, v = line.split("=", 1)
                out[k.strip()] = v.strip()
    return out


def scan_others(root, parent):
    found = []
    for sib in sorted(glob.glob(os.path.join(parent, "*"))):
        if not os.path.isdir(sib) or os.path.abspath(sib) == os.path.abspath(root):
            continue
        for f in glob.glob(os.path.join(sib, "Strategies", "*", "v*", "*_EA.mq5")):
            try:
                t = read_text(f)[0]
            except Exception:
                continue
            tag = re.search(r'#define\s+STRATEGY_TAG\s+"([A-Za-z0-9]+)"', t)
            od = re.search(r'#define\s+STRATEGY_EA_ORDINAL\s+(\d+)', t)
            base = re.search(r'#define\s+STRATEGY_MAGIC_BASE\s+(\d+)', t)
            if tag and base and tag.group(1) != "TPL":
                found.append((tag.group(1), int(od.group(1)) if od else None, int(base.group(1)), f))
    return found


def ask(prompt, given):
    if given not in (None, ""):
        return str(given)
    if not sys.stdin.isatty():
        return ""
    return input(prompt).strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--name")
    ap.add_argument("--tag")
    ap.add_argument("--ordinal")
    ap.add_argument("--scan")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--ignore-collision", action="store_true")
    a = ap.parse_args()

    root = find_root()
    if not root:
        print("[ERROR] หาโฟลเดอร์ Repo ไม่เจอ")
        return 2
    ident = os.path.join(root, "STRATEGY_IDENTITY.txt")
    if os.path.isfile(ident):
        print("[ERROR] ตั้งชื่อไปแล้ว (มี STRATEGY_IDENTITY.txt) ถ้าต้องการเริ่มใหม่ให้ unzip แม่แบบใหม่")
        return 2
    old = os.path.join(root, "Strategies", "Template")
    if not os.path.isdir(old):
        print("[ERROR] ไม่พบ Strategies/Template")
        return 2

    name = ask("ชื่อกลยุทธ์ (ภาษาอังกฤษ ไม่มีเว้นวรรค เช่น SMC): ", a.name)
    tag = ask("TAG 3 ตัวอักษร A-Z (เช่น SMC): ", a.tag).upper()
    ordn = ask("ลำดับ EA (เลขจำนวนเต็ม 1-99 ไม่ซ้ำกับกลยุทธ์อื่น): ", a.ordinal)

    if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]{1,24}", name or "") or name.lower() == "template":
        print("[ERROR] ชื่อไม่ถูกต้อง (ขึ้นต้นด้วยตัวอักษร ใช้ตัวอักษร ตัวเลข _ ได้ 2-25 ตัว และห้ามใช้ Template)")
        return 2
    if not re.fullmatch(r"[A-Z]{3}", tag or "") or tag == "TPL":
        print("[ERROR] TAG ต้องเป็นตัวอักษร A-Z 3 ตัว และห้ามใช้ TPL")
        return 2
    if not re.fullmatch(r"\d{1,2}", ordn or "") or int(ordn) < 1:
        print("[ERROR] ลำดับ EA ต้องเป็นเลข 1-99")
        return 2
    ordn = int(ordn)
    base = ordn * 10000
    new = os.path.join(root, "Strategies", name)
    if os.path.exists(new):
        print("[ERROR] มีโฟลเดอร์ Strategies/%s อยู่แล้ว" % name)
        return 2

    parent = os.path.abspath(a.scan) if a.scan else os.path.dirname(root)
    others = [(t, o, b, "ค่าที่ทราบจากแพลตฟอร์ม") for t, (o, b) in KNOWN.items()] + scan_others(root, parent)
    collisions = []
    for t, o, b, src in others:
        if t == tag:
            collisions.append("TAG %s ซ้ำกับ %s" % (tag, src))
        if o == ordn:
            collisions.append("ลำดับ EA %d ซ้ำกับ TAG %s (%s)" % (ordn, t, src))
        if b == base:
            collisions.append("Magic ฐาน %d ซ้ำกับ TAG %s (%s)" % (base, t, src))
    print("สแกน Repo ข้างเคียงใน:", parent, "| พบกลยุทธ์อื่น %d รายการ" % len([x for x in others if x[3] != "ค่าที่ทราบจากแพลตฟอร์ม"]))
    for c in collisions:
        print("  [WARN] " + c)

    ver = kv(os.path.join(root, "TEMPLATE_VERSION"))
    comment = "%s%d H1 base" % (tag, base)
    print("\nแผน: Strategies/Template -> Strategies/%s" % name)
    print("  TAG=%s ลำดับ=%d Magic ฐาน=%d ถึง %d ถัดไป=%d Comment=%s" % (tag, ordn, base, base + 9999, base + 1, comment))

    NAME_UP = name.upper()

    def transform(t):
        t = t.replace("TEMPLATE_", NAME_UP + "_").replace("Template", name)
        t = t.replace("TPL90000", "%s%d" % (tag, base)).replace("TPL", tag)
        t = t.replace("90001", str(base + 1)).replace("90000", str(base))
        t = re.sub(r"(#define\s+STRATEGY_EA_ORDINAL\s+)\d+", r"\g<1>%d" % ordn, t)
        t = "\n".join(l for l in t.split("\n") if "tools/init_strategy.py" not in l)
        return t

    plan = []
    for dp, dn, fns in os.walk(old):
        rel = os.path.relpath(dp, old)
        in_core = "Core" in rel.split(os.sep)
        for fn in fns:
            nfn = fn if in_core else fn.replace("Template_", name + "_", 1)
            plan.append((os.path.join(dp, fn), os.path.join(new, "" if rel == "." else rel, nfn), (not in_core) and fn.lower().endswith(TEXT_EXT)))
    for s, d, tr in plan:
        if tr:
            print("  แก้+ย้าย", os.path.relpath(d, root))

    if not a.apply and sys.stdin.isatty():
        if input("\nเขียนไฟล์จริงไหม? (Y/N): ").strip().lower() == "y":
            a.apply = True
    if collisions and a.apply and not a.ignore_collision:
        print("\n[ERROR] พบ TAG/ลำดับ/Magic ซ้ำ ไม่เขียนไฟล์ แก้ค่าหรือใช้ --ignore-collision ถ้าแน่ใจ")
        return 1
    if not a.apply:
        print("\nดูอย่างเดียว ยังไม่เขียนไฟล์ ใส่ --apply เพื่อเขียนจริง")
        return 0

    for s, d, tr in plan:
        os.makedirs(os.path.dirname(d), exist_ok=True)
        if tr:
            t, bom, crlf = read_text(s)
            write_text(d, transform(t), bom, crlf)
        else:
            shutil.copy2(s, d)
    shutil.rmtree(old)

    today = datetime.date.today().isoformat()
    open(ident, "w", encoding="utf-8", newline="\n").write(
        "name=%s\ntag=%s\nordinal=%d\nmagic_base=%d\nmagic_next=%d\ndefault_comment=%s\nstrategy_folder=Strategies/%s\n"
        "created=%s\ntemplate_version=%s\ncore_version=%s\n" % (name, tag, ordn, base, base + 1, comment, name, today,
                                                               ver.get("template_version", "?"), ver.get("core_version", "?")))

    tokens = {"{{NAME}}": name, "{{TAG}}": tag, "{{ORDINAL}}": str(ordn), "{{MAGIC_BASE}}": str(base), "{{DATE}}": today}
    cnt = 0
    cands = glob.glob(os.path.join(root, "*.md")) + glob.glob(os.path.join(root, "docs", "**", "*.md"), recursive=True)
    for f in cands:
        t, bom, crlf = read_text(f)
        n = t
        for k, v in tokens.items():
            n = n.replace(k, v)
        if n != t:
            write_text(f, n, bom, crlf)
            cnt += 1
    print("\nเสร็จแล้ว: สร้าง Strategies/%s, STRATEGY_IDENTITY.txt, เติมค่าในเอกสาร %d ไฟล์" % (name, cnt))
    print("ขั้นต่อไป:")
    print("  1. คอมไพล์ Strategies\\%s\\v*\\%s_EA_TH.mq5 ต้อง 0 errors 0 warnings" % (name, name))
    print("  2. เปลี่ยนชื่อโฟลเดอร์ Repo เป็น EA_%s  แล้ว git init / Commit แรก / สร้าง Repo Private / push" % name)
    print("  3. ติด tag ฐาน %s-v<รุ่น>-r0 เมื่อทดสอบผ่านครั้งแรก (ดู R-4 ใน docs/RULES.md)" % name.lower())
    return 0


if __name__ == "__main__":
    sys.exit(main())