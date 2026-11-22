# TEST MATRIX: RangeBot

สถานะ: PASS (มี Log/ภาพ) | PASS* (รายงานข้อความ) | BLOCKED | ยังไม่ทดสอบ

| ข้อ | สิ่งที่ทดสอบ | Magic / ชุดค่า | เวลา | ผล | หลักฐาน |
|---|---|---|---|---|---|
| T-01 | คอมไพล์ EA 3 ตัว (0 errors 0 warnings) | - | 2026-11-22 | PASS* | ผลคอมไพล์ใหม่หลังแก้ STRATEGY_MAGIC_NEXT (ก่อน Commit ชุด 5) |
| T-02 | แนบ EA บน Demo เริ่มระบบสำเร็จ | | | ยังไม่ทดสอบ | ทดสอบเฉพาะ Strategy Tester (บัญชี FBS-Demo) |
| T-03 | Regime + Range: หากรอบ ล็อก ปลดล็อก | 40000 / ชุด C | 2026-11-22 | PASS | Journal D1.txt |
| T-04 | สัญญาณ ZONE BUY และ SELL เปิดไม้ ตั้ง SL/TP ตามสูตร ATR | 40000 / ชุด C | 2026-11-22 | PASS | Journal D1.txt (ไม้ #2 #4 #6 #8) |
| T-05 | เกต SL_TOO_FAR / RR_LOW ชะลอสัญญาณ | 40000 / ชุด C | 2026-11-22 | PASS | Journal D1.txt |
| T-06 | สัญญาณหมดอายุ 15 นาที (SIGNAL EXPIRED) | 40000 / ชุด C | 2026-11-22 | PASS | Journal D1.txt (10.06 04:15) |
| T-07 | Protect ของ Core ถูกปิด ไม่แทรก SL | 40000 / ชุด C | 2026-11-22 | PASS | Journal D1.txt (ไม่มี CUTLOSS / BREAK-EVEN) |
| T-08 | กรอง FOLLOW_HTF / ADX_RISING | 40000 | 2026-11-22 | PASS* | รายงานข้อความรอบ 10.05 ถึง 10.12 |
| T-09 | TP1 แล้วเลื่อน SL ไปทุน (+0.1 ATR) | 40000 / ชุด C | 2026-11-22 | PASS | Journal D1.txt |
| T-10 | Hand-off ถอด TP + Chandelier Trail | 40000 / ชุด C | 2026-11-22 | PASS | Journal D1.txt |
| T-11 | MaxHold รวมการลองปิดซ้ำเมื่อตลาดปิด | 40000 / ชุด C | 2026-11-22 | PASS | Journal D2.txt (10.27 01:00 ถึง 02:00) |
| T-12 | Timeout หลัง TP1 | 40000 / ชุด C | 2026-11-22 | PASS* | ข้อความ Journal รอบ D4 ใหม่ |
| T-13 | Mid-range BE (BUY และ SELL) | 40000 / ชุด C | 2026-11-22 | PASS* | ข้อความ Journal 3 เหตุการณ์ |
| T-14 | TREND SHIFT แบบ KEEP | 40000 / ชุด C | 2026-11-22 | PASS | Journal D1.txt |
| T-15 | TREND SHIFT TIGHTEN / CLOSE เฉพาะสวนทิศ | 40000 / ชุด C | 2026-11-22 | PASS* | ข้อความ Journal D3-A, D3-B (ฝั่งเทรนด์ทิศเดียวกับไม้ ยังไม่เห็นเหตุการณ์) |
| T-16 | ปุ่ม BE NOW (ไม่มีไม้ / สำเร็จ / กดซ้ำ / Invalid stops) | 40000 / ชุด C | 2026-11-22 | PASS* | Journal D1.txt + ข้อความ Journal รอบ TRY |
| T-17 | ปุ่ม RESET RANGE | 40000 | 2026-11-22 | PASS | Journal note.txt |
| T-18 | Cooldown 1 แท่งหลังปิดด้วยตัวจัดการ + Log DROPPED | 40000 / ชุด C | 2026-11-22 | PASS* | ข้อความ Journal 10.16 19:00 |
| T-19 | เก็บ/กู้สถานะ GV หลังรีสตาร์ท | | | ยังไม่ทดสอบ | ปิดใน Tester ต้องทดสอบบน Demo |
| T-20 | สัญญาณ SWEEP | | | ยังไม่ทดสอบ | |
| T-21 | Trigger RSI ผ่านท่อเปิดไม้ (SELL ZONE + FOLLOW_HTF) | 40001 / 00_baseline | 2026-11-22 | PASS* | ข้อความ Journal 10.16 13:00 ถึง 10.21 03:00 (1 ไม้ #2 +63.12 USD) |
| T-21b | Trigger STOCH / CANDLE | 40005, 40006 | | ยังไม่ทดสอบ | |
| T-22 | ชุด Ablation 00 ถึง 10 ช่วง 2025.01.02 ถึง 2026.10.29 Every tick (จำลอง) | 40001 ถึง 40011 | | ยังไม่ทดสอบ | ผลใน docs/work/ABLATION_RESULTS.md |
| T-23 | ช่วงยาว 100 ไม้ขึ้นไป | | | ยังไม่ทดสอบ | |
| T-24 | MT5 โหลด .set (UTF-16, ชื่อ=ค่า) ตรงทุก Input และเริ่มระบบสำเร็จ | 40001 / 00_baseline | 2026-11-22 | PASS* | ข้อความ Journal (Magic 40001, Protect ของ Core ถูกปิด, เริ่มระบบสำเร็จ) |
