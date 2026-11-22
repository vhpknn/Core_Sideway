# STRATEGY DECISIONS: มติเฉพาะกลยุทธ์นี้

เลขมติของกลยุทธ์ใช้รูปแบบ S-01, S-02, ... ห้ามใช้ D-NN (ของแพลตฟอร์ม) เพิ่มหัวข้อใหม่ต่อท้ายไฟล์นี้ในคอมมิตเดียวกับงานที่เกี่ยวข้อง

## S-01 แผนกลยุทธ์และขอบเขต Core
ใช้ Blueprint-A-Range-Bot เป็นแผนกลยุทธ์ที่ปรับให้เข้ากับ Core v1.1 ไม่ยึดสถาปัตยกรรมเดิม ไม่แก้ Core (ถ้าต้องการสิ่งที่ Core ไม่มี ให้เปิดงาน Core แยก)

## S-02 ปิด Protect ของ Core
ตั้ง InpRRPercent=0, InpUseTrailingTP=false, InpBreakEvenMode=BE_OFF EA จะไม่เริ่มทำงานถ้าไม่ตรง Cut Loss ของ Core ปิดไม่ได้ จึงตั้ง InpCutLossPoints=3000 ให้กว้างกว่า SL ของกลยุทธ์เป็นตาข่ายสุดท้าย

## S-03 ขนาดล็อตและความเสี่ยง
ใช้ Virtual Capital Auto-Lot ของ Core ไม่ใช้ Risk Percent ไม่มี SharedRisk ข้ามบอท ทำ RangeBot ตัวเดียวก่อน

## S-04 ไม่มี Partial Close
Core ปิดได้เต็มไม้เท่านั้น ที่ TP1 เลื่อน SL ไปทุน (+0.1 ATR) แล้วถือต่อไป TP2 Hand-off ถอด TP แล้วใช้ Chandelier Trail ใช้ได้เมื่อเปิด InpRbUseTp2

## S-05 จังหวะตรวจของตัวจัดการไม้
TP1 และ Mid-range BE ตรวจทุก Tick ส่วน Hand-off, Trail, Timeout, MaxHold, TREND SHIFT ตรวจเมื่อเปิดแท่งใหม่

## S-06 TREND SHIFT ก่อน TP1
ทำงานเฉพาะเมื่อเทรนด์สวนทิศไม้ (BUY เจอ TREND_DOWN, SELL เจอ TREND_UP) ครั้งเดียวต่อไม้ เทรนด์ทิศเดียวกับไม้ไม่ทำอะไร ค่าเริ่มต้น KEEP

## S-07 อายุสัญญาณและ Cooldown
สัญญาณรอเปิดไม้ได้ไม่เกิน InpRbSignalWaitMinutes (15 นาที) หลังตัวจัดการปิดไม้ (MaxHold, TREND SHIFT CLOSE, Timeout) พักไม่เปิดไม้ใหม่จนจบแท่งนั้น Log SIGNAL DROPPED | COOLDOWN

## S-08 สถานะไม้
เก็บใน Global Variable 16 ตัวและกู้ตอนเริ่มระบบ ไม่ทำงานใน Strategy Tester ไม้ที่ไม่มีสถานะไม่ถูกจัดการ (SL/TP ของโบรกยังทำงาน)

## S-09 ชุดค่า .set
สร้างด้วย tools/make_rangebot_sets.py ชุด 00 ถึง 10 ตาม Ablation ของ Blueprint Magic = ฐาน + 1 + เลขชุด (40001 ถึง 40011) ไฟล์ทดสอบชั่วคราวไม่เก็บใน Repo (R-6)

## S-10 ค่าตั้งต้นสำหรับ XAUUSD (FBS Demo)
InpMaxSpreadPoints=45 และ InpCutLossPoints=3000 ตรวจใหม่ถ้าเปลี่ยนโบรกเกอร์หรือสัญลักษณ์
