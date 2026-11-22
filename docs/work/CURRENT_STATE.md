# CURRENT STATE: RangeBot
อัปเดต: 2026-11-22
Commit ที่ Push แล้ว: 39fa93a (ชุด 1 ถึง 4; ชุด 5 ยังไม่ Commit)

## ตัวตนกลยุทธ์
ชื่อ RangeBot | TAG RNG | ลำดับ EA 4 | Magic ฐาน 40000
Core ฐาน: ดู `Core/v*/PINNED_FROM.txt`

## เฟสปัจจุบัน
ชุด 5: ชุดค่า .set, TEST_MATRIX, คู่มือ (ตรรกะเทรดชุด 1 ถึง 4 ทดสอบใน Strategy Tester แล้ว ดู TEST_MATRIX)

## ทำเสร็จแล้ว
- ชุด 1 ถึง 4: Regime, Range, สัญญาณ ZONE/SWEEP, เปิดไม้ + SL/TP, ตัวจัดการไม้ (TP1-BE, Mid-BE, Hand-off, Timeout, MaxHold, TREND SHIFT, BE NOW), Cooldown, เก็บสถานะ GV
- ชุด 5: ชุด .set 00 ถึง 10 (tools/make_rangebot_sets.py), TEST_MATRIX, คู่มือไทยและอังกฤษ (docs/RangeBot/)

## ยังไม่ทำ / ขั้นถัดไป
1. คอมไพล์ 3 EA, run_checks, Commit ชุด 5 แล้วติด tag
2. รัน Ablation 00 ถึง 10 ช่วงยาว (ต้องมี Tick ย้อนหลังเพิ่ม)
3. ทดสอบกู้สถานะ GV บน Demo
4. ทดสอบ SWEEP และ Trigger RSI / STOCH / CANDLE
5. สร้าง 20_combined และ 99_final หลังได้ผล Ablation
หมายเหตุ: สเปกจริงอยู่ที่ `docs/RangeBot/` (`docs/BLUEPRINT.md` ยังเป็นแม่แบบ)
