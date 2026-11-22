# -*- coding: utf-8 -*-
"""ตัวช่วยกลางของเครื่องมือ EA Platform Core (ใช้ไลบรารีมาตรฐานของ Python เท่านั้น)"""
import hashlib
import re
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
except Exception:
    pass

TOOLS_DIR = Path(__file__).resolve().parent
ROOT = TOOLS_DIR.parent
STRATEGIES = ROOT / "Strategies"
REGISTRY = ROOT / "docs" / "decisions" / "MAGIC_REGISTRY.md"
THEME_REF = ROOT / "docs" / "reference" / "HedgeUI_Theme.mqh"


def sha256_file(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def read_text(path):
    """อ่านไฟล์ข้อความ คืน (ข้อความ, ชื่อการเข้ารหัส) รองรับ UTF-16 / UTF-8 / UTF-8 BOM"""
    data = Path(path).read_bytes()
    if data.startswith(b"\xff\xfe") or data.startswith(b"\xfe\xff"):
        return data.decode("utf-16"), "utf-16"
    if data.startswith(b"\xef\xbb\xbf"):
        return data.decode("utf-8-sig"), "utf-8-sig"
    try:
        return data.decode("utf-8"), "utf-8"
    except UnicodeDecodeError:
        return data.decode("cp874", errors="replace"), "cp874"


def write_text(path, text, encoding):
    """เขียนไฟล์ด้วยการเข้ารหัสเดิม (UTF-16 เขียนพร้อม BOM)"""
    Path(path).write_bytes(text.encode(encoding))


def version_key(name):
    nums = re.findall(r"\d+", name)
    return tuple(int(n) for n in nums)


def latest_core_include():
    """โฟลเดอร์ include ของ Core ต้นฉบับเวอร์ชันล่าสุด เช่น Core/v1.0.0/include"""
    dirs = [p for p in (ROOT / "Core").glob("v*/include") if p.is_dir()]
    if not dirs:
        return None
    return sorted(dirs, key=lambda p: version_key(p.parent.name))[-1]


def find_core_copies():
    """สำเนา Core ของทุกกลยุทธ์: Strategies/<ชื่อ>/v*/Core/include"""
    return sorted(p for p in STRATEGIES.glob("*/v*/Core/include") if p.is_dir())


def all_core_includes():
    """โฟลเดอร์ include ของ Core ต้นฉบับทุกรุ่น เรียงตามเลขรุ่น"""
    dirs = [p for p in (ROOT / "Core").glob("v*/include") if p.is_dir()]
    return sorted(dirs, key=lambda p: version_key(p.parent.name))


def copy_version(copy_include):
    """รุ่นของสำเนา Core จากโฟลเดอร์กลยุทธ์ Strategies/<ชื่อ>/<รุ่น>/Core/include (D-28.1)
    คืนชื่อรุ่น เช่น v1.0.1 หรือ None ถ้าโครงโฟลเดอร์ไม่ตรงรูปแบบ"""
    p = Path(copy_include).resolve()
    if (p.name == "include" and p.parent.name == "Core"
            and p.parent.parent.parent.parent == STRATEGIES.resolve()
            and p.parent.parent.name.startswith("v")):
        return p.parent.parent.name
    return None


def core_source_for_copy(copy_include):
    """ต้นฉบับ Core รุ่นเดียวกับโฟลเดอร์กลยุทธ์ คืน (รุ่น, โฟลเดอร์ หรือ None ถ้าไม่มีรุ่นนั้น)"""
    ver = copy_version(copy_include)
    if ver is None:
        return None, None
    src = ROOT / "Core" / ver / "include"
    return ver, (src if src.is_dir() else None)


def find_strategy_dirs():
    """โฟลเดอร์กลยุทธ์ที่มีไฟล์ <ชื่อ>_EA.mq5"""
    out = []
    for vdir in sorted(STRATEGIES.glob("*/v*")):
        ea = vdir / (vdir.parent.name + "_EA.mq5")
        if ea.exists():
            out.append((vdir, ea))
    return out


def parse_ea_defines(ea_path):
    """อ่าน #define ของกลยุทธ์จากไฟล์ EA"""
    text, _ = read_text(ea_path)
    out = {}
    m = re.search(r'#define\s+STRATEGY_TAG\s+"([A-Z0-9]+)"', text)
    out["TAG"] = m.group(1) if m else None
    for key, name in (("ORDINAL", "STRATEGY_EA_ORDINAL"),
                      ("BASE", "STRATEGY_MAGIC_BASE"),
                      ("NEXT", "STRATEGY_MAGIC_NEXT")):
        m = re.search(r"#define\s+" + name + r"\s+(\d+)", text)
        out[key] = int(m.group(1)) if m else None
    return out


def read_set(path):
    """อ่านไฟล์ .set คืน (dict ชื่อ->ค่า, การเข้ารหัส)"""
    text, enc = read_text(path)
    values = {}
    for line in text.splitlines():
        s = line.strip()
        if not s or s.startswith(";") or "=" not in s:
            continue
        k, v = s.split("=", 1)
        values[k.strip()] = v.strip()
    return values, enc


def parse_registry():
    """อ่าน MAGIC_REGISTRY.md คืน (ตาราง TAG, Magic ที่ใช้แล้วต่อ TAG)
    tags: TAG -> (ลำดับ, ชื่อ, ต่ำสุด, สูงสุด) | used: TAG -> [(เริ่ม, จบ)]"""
    tags, used = {}, {}
    if not REGISTRY.exists():
        return tags, used
    text, _ = read_text(REGISTRY)
    row_tag = re.compile(r"^\|\s*(\d+)\s*\|\s*([^|]+?)\s*\|\s*([A-Z]{3})\s*\|\s*(\d+)\s*-\s*(\d+)\s*\|")
    row_used = re.compile(r"^\|\s*(\d+)(?:\s*-\s*(\d+))?\s*\|")
    current = None
    for line in text.splitlines():
        if line.startswith("#"):
            m = re.search(r"\(([A-Z]{3})\)", line)
            current = m.group(1) if m else None
            continue
        m = row_tag.match(line)
        if m:
            tags[m.group(3)] = (int(m.group(1)), m.group(2), int(m.group(4)), int(m.group(5)))
            continue
        if current:
            m = row_used.match(line)
            if m:
                lo = int(m.group(1))
                hi = int(m.group(2)) if m.group(2) else lo
                used.setdefault(current, []).append((lo, hi))
    return tags, used


def check_comment(comment, tag, magic, ordinal, max_len=25):
    """ตรวจ InpTradeComment ตามกติกา Identity (ตรงกับ Core_Identity.mqh) คืนข้อความปัญหา หรือ None"""
    comment = comment.strip()
    if not comment:
        return "COMMENT_EMPTY"
    token = comment.split(" ", 1)[0]
    ctag, digits = token[:3], token[3:]
    if len(token) < 4 or not digits.isdigit():
        return "COMMENT_FORMAT(expect <TAG><Magic>)"
    if ctag != tag:
        return "TAG_MISMATCH(comment=%s expected=%s)" % (ctag, tag)
    if int(digits) != magic:
        return "MAGIC_MISMATCH(comment=%s input=%d)" % (digits, magic)
    lo = ordinal * 10000
    if magic < lo or magic > lo + 9999:
        return "MAGIC_OUT_OF_RANGE(magic=%d range=%d-%d)" % (magic, lo, lo + 9999)
    if len(comment) > max_len:
        return "COMMENT_TOO_LONG(%d>%d)" % (len(comment), max_len)
    return None