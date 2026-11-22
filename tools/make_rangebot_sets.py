# -*- coding: utf-8 -*-
"""make_rangebot_sets: สร้างไฟล์ .set ชุด Ablation ของ RangeBot (Blueprint A8)
- ค่าทั้งหมดอยู่ในสคริปต์นี้ที่เดียว ไฟล์ .set ทุกไฟล์มีครบทุก Input (MT5 ไม่รีเซ็ตค่าที่ไม่อยู่ในไฟล์)
- Magic = ฐาน + 1 + เลขชุด (00 -> ฐาน+1) | Comment = <TAG><Magic> <TF> <NN>_<ชื่อ> (ไม่เกิน 25 ตัวอักษร)
- รันตรงๆ = ดูแผนอย่างเดียว | --apply = เขียนไฟล์ | --force = เขียนทับไฟล์ที่ต่างจากที่สร้าง
รหัสออก: 0 ปกติ, 1 มีไฟล์ต่าง/ผิดกติกา, 2 เครื่องมือผิดพลาด"""
import argparse
import sys

from _common import STRATEGIES, check_comment, parse_ea_defines, read_set, write_text

CORE_INPUTS = [
    ("InpPointDigits", "2"), ("InpInitialCapital", "50.0"), ("InpRefillAmount", "10.0"),
    ("InpBaseLot", "0.01"), ("InpAutoLot", "true"), ("InpLotStepMoney", "50.0"),
    ("InpLotIncrement", "0.01"), ("InpLockProfit", "false"), ("InpMaxLotStep", "4"),
    ("InpUseTimeout", "true"), ("InpTimeoutSeconds", "300"), ("InpUseSpreadCheck", "true"),
    ("InpMaxSpreadPoints", "45"), ("InpDeviationPoints", "10"),
    ("InpCutLossPoints", "3000"), ("InpBreakEvenMode", "0"), ("InpBreakEvenPct", "20.0"),
    ("InpBreakEvenTrigger", "1000"), ("InpBreakEvenStep", "100"), ("InpRRPercent", "0.0"),
    ("InpUseTrailingTP", "false"), ("InpTrailingPullback", "500"),
    ("InpSession1Block", "false"), ("InpSession1Start", "01:00"), ("InpSession1End", "04:00"),
    ("InpSession2Block", "false"), ("InpSession2Start", "07:00"), ("InpSession2End", "12:00"),
    ("InpSession3Block", "false"), ("InpSession3Start", "21:00"), ("InpSession3End", "24:00"),
    ("InpMagicNumber", "0"), ("InpTradeComment", ""), ("InpIdentityCheck", "false"),
    ("InpEnableReport", "true"), ("InpReportDays", "5"),
]

RB_INPUTS = [
    ("InpRbAccountMode", "0"),
    ("InpRbEntryTF", "16385"), ("InpRbAtrPeriod", "14"), ("InpRbLogBar", "true"), ("InpRbDrawRange", "true"),
    ("InpRbAdxPeriod", "14"), ("InpRbAdxRangeMax", "20.0"), ("InpRbAdxTrendMin", "25.0"),
    ("InpRbAdxRisingBars", "3"), ("InpRbBbPeriod", "20"), ("InpRbBbDev", "2.0"),
    ("InpRbBbwAvgPeriod", "50"), ("InpRbSqueezeFactor", "1.0"), ("InpRbEmaFast", "20"),
    ("InpRbEmaMid", "50"), ("InpRbEmaSlow", "200"), ("InpRbRegimeConfirmBars", "2"),
    ("InpRbRangeLookback", "30"), ("InpRbRangeExcludeBars", "1"), ("InpRbRangeMinHeightAtr", "2.0"),
    ("InpRbRangeMaxHeightAtr", "6.0"), ("InpRbRangeMinTouches", "2"), ("InpRbRangeTouchTolAtr", "0.25"),
    ("InpRbUseRangeLock", "true"),
    ("InpRbRangeDirection", "0"), ("InpRbHigherTF", "16388"), ("InpRbHtfEma", "200"), ("InpRbHtfBufferAtr", "0.25"),
    ("InpRbEntryType", "2"), ("InpRbZoneEntryPct", "25.0"), ("InpRbSweepMinAtr", "0.1"),
    ("InpRbSweepMaxAtr", "1.0"), ("InpRbSweepMinWickRatio", "1.5"), ("InpRbSweepRequireTrigger", "false"),
    ("InpRbTriggerType", "0"), ("InpRbRsiPeriod", "14"), ("InpRbRsiBuy", "35.0"), ("InpRbRsiSell", "65.0"),
    ("InpRbStochK", "14"), ("InpRbStochD", "3"), ("InpRbStochSlow", "3"), ("InpRbStochLow", "20.0"),
    ("InpRbStochHigh", "80.0"), ("InpRbCandlePinWickRatio", "2.0"), ("InpRbCandleUseEngulfing", "true"),
    ("InpRbUseAdxSlope", "true"), ("InpRbAdxSlopeBars", "3"), ("InpRbUsePercentB", "false"),
    ("InpRbPercentBBuy", "0.1"), ("InpRbPercentBSell", "0.9"), ("InpRbUseAtrVolFilter", "true"),
    ("InpRbAtrVolAvgPeriod", "100"), ("InpRbAtrVolMin", "0.5"), ("InpRbAtrVolMax", "2.5"),
    ("InpRbZoneSlAtr", "1.0"), ("InpRbSweepSlAtr", "0.3"), ("InpRbTp1BufferAtr", "0.1"),
    ("InpRbUseTp2", "true"), ("InpRbMinRrTp1", "1.2"),
    ("InpRbSignalWaitMinutes", "15"), ("InpRbBeBufferAtr", "0.1"), ("InpRbUseMidRangeBe", "false"),
    ("InpRbUseHandOff", "true"), ("InpRbHandOffBreakAtr", "0.2"), ("InpRbHandOffRequireTrend", "false"),
    ("InpRbChandelierPeriod", "22"), ("InpRbChandelierMult", "3.0"), ("InpRbTrailStepAtr", "0.1"),
    ("InpRbUseRangeTimeout", "true"), ("InpRbRangeTimeoutBars", "24"), ("InpRbOnTrendShiftPreTp1", "0"),
    ("InpRbUseMaxHold", "false"), ("InpRbMaxHoldBars", "48"),
]

# Baseline ตาม Blueprint A8: ZONE + RSI + FOLLOW_HTF และปิดตัวเลือกเสริมทั้งหมด
BASELINE = {
    "InpRbEntryType": "0", "InpRbTriggerType": "0", "InpRbRangeDirection": "0",
    "InpRbUseAdxSlope": "false", "InpRbUsePercentB": "false", "InpRbUseMidRangeBe": "false",
    "InpRbUseAtrVolFilter": "false", "InpRbUseMaxHold": "false", "InpRbUseHandOff": "false",
}

# (เลขชุด, ชื่อสั้น, ค่าที่ต่างจาก baseline)  20_combined / 99_final รอผลทดสอบ
VARIANTS = [
    (0, "baseline", {}),
    (1, "sweep", {"InpRbEntryType": "1"}),
    (2, "both", {"InpRbEntryType": "2"}),
    (3, "adxslope", {"InpRbUseAdxSlope": "true"}),
    (4, "trigstoch", {"InpRbTriggerType": "1"}),
    (5, "trigcandle", {"InpRbTriggerType": "2"}),
    (6, "percentb", {"InpRbUsePercentB": "true"}),
    (7, "midbe", {"InpRbUseMidRangeBe": "true"}),
    (8, "atrvol", {"InpRbUseAtrVolFilter": "true"}),
    (9, "handoff", {"InpRbUseHandOff": "true"}),
    (10, "bothedges", {"InpRbRangeDirection": "1"}),
]


def build(idx, slug, extra, tag, base, tf):
    vals = dict(CORE_INPUTS + RB_INPUTS)
    vals.update(BASELINE)
    vals.update(extra)
    magic = base + 1 + idx
    vals["InpMagicNumber"] = str(magic)
    vals["InpTradeComment"] = "%s%d %s %02d_%s" % (tag, magic, tf, idx, slug)
    return magic, vals


def render(name, vals):
    lines = ["; RangeBot set: " + name,
             "; generated by tools/make_rangebot_sets.py - edit the script, not this file"]
    lines += ["%s=%s" % (k, v) for k, v in vals.items()]
    return "\r\n".join(lines) + "\r\n"


def main():
    ap = argparse.ArgumentParser(description="สร้างไฟล์ .set ชุด Ablation ของ RangeBot")
    ap.add_argument("--strategy", default="RangeBot")
    ap.add_argument("--core-version", default="v1.1")
    ap.add_argument("--symbol", default="XAUUSD")
    ap.add_argument("--tf", default="H1")
    ap.add_argument("--set-version", default="1.0.0")
    ap.add_argument("--apply", action="store_true", help="เขียนไฟล์จริง")
    ap.add_argument("--force", action="store_true", help="เขียนทับไฟล์ที่ต่างจากที่สร้าง")
    args = ap.parse_args()

    vdir = STRATEGIES / args.strategy / args.core_version
    ea = vdir / (args.strategy + "_EA.mq5")
    if not ea.exists():
        print("[ERROR] ไม่พบ %s" % ea)
        return 2
    d = parse_ea_defines(ea)
    if not d["TAG"] or d["BASE"] is None or d["ORDINAL"] is None:
        print("[ERROR] อ่าน STRATEGY_TAG / MAGIC_BASE / ORDINAL จาก EA ไม่ได้")
        return 2

    setdir = vdir / "Set"
    _, base_vals = build(0, "baseline", {}, d["TAG"], d["BASE"], args.tf)
    problems, magics = 0, []
    print("%s %s | TAG=%s Magic ฐาน=%d | %s" % (args.strategy, args.core_version, d["TAG"], d["BASE"],
                                              "เขียนไฟล์" if args.apply else "ดูแผนอย่างเดียว (ใส่ --apply เพื่อเขียน)"))
    for idx, slug, extra in VARIANTS:
        magic, vals = build(idx, slug, extra, d["TAG"], d["BASE"], args.tf)
        magics.append(magic)
        name = "%s_%s_%s_v%s_%02d_%s.set" % (d["TAG"], args.symbol, args.tf, args.set_version, idx, slug)
        path = setdir / name
        issue = check_comment(vals["InpTradeComment"], d["TAG"], magic, d["ORDINAL"])
        if issue:
            print("  [ERROR] %s: %s" % (name, issue))
            problems += 1
            continue
        changed = [k for k in vals if vals[k] != base_vals[k] and k not in ("InpMagicNumber", "InpTradeComment")]
        state = "NEW"
        if path.exists():
            old, _ = read_set(path)
            state = "SAME" if old == vals else "DIFF"
        if state == "DIFF" and not args.force:
            problems += 1
        elif args.apply and state != "SAME":
            setdir.mkdir(parents=True, exist_ok=True)
            write_text(path, render(name, vals), "utf-16")
            state += " -> เขียนแล้ว"
        print("  %-5s Magic %d | %s | ต่างจาก baseline: %s" % (state, magic, name, ", ".join(changed) or "-"))

    if d["NEXT"] is not None and d["NEXT"] <= max(magics):
        print("  [WARN] STRATEGY_MAGIC_NEXT=%d ต้องมากกว่า %d (แก้ #define ใน EA)" % (d["NEXT"], max(magics)))
    if problems:
        print("พบ %d รายการที่ต้องตรวจ (DIFF ต้องใช้ --force เพื่อเขียนทับ)" % problems)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())