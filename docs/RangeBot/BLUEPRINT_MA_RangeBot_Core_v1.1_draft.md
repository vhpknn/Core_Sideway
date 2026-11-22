# BLUEPRINT: MA_RangeBot (ร่าง v0.1 ปรับให้เข้ากับ Core v1.1)

สถานะ: ร่าง รอผู้ใช้ตัดสินใจ | อัปเดต: 2026-11-22
ที่มา: Blueprint-A-Range-Bot-MA_RangeBot.md (ตรรกะกลยุทธ์) + Core v1.1 (สัญญา API)
Commit ของงาน: unknown | Core ฐาน: v1.1 (source commit 30c3001e..., จาก TEMPLATE_VERSION)

ป้ายสถานะ: [OK] ตรวจจากไฟล์ที่เปิดอ่านแล้ว | [ข้อเสนอ] ข้อเสนอของ AI รอยืนยัน | [ต้องตรวจ] ยังไม่เห็นไฟล์ Core ที่เกี่ยวข้อง ห้ามถือว่ามี

## 1. เป้าหมายและแนวคิด
- เทรดเฉพาะตลาด RANGE เข้าที่ขอบกรอบด้วย ZONE หรือ SWEEP (Market Order)
- หยุดเปิดไม้ใหม่เมื่อ Regime ไม่ใช่ RANGE
- ไม้ที่ผ่าน TP1 แล้ว เบรกกรอบทางเดียวกัน -> Hand-off ไป Trailing (นโยบาย C)
- ขอบเขต: Range Bot ตัวเดียว ไม่รวม Trend Bot และ SharedRisk ข้ามบอท (R-2) [ข้อเสนอ]

## 2. สเปก (ตาม SPEC_FORM)
| หัวข้อ | ค่า |
|---|---|
| ชื่อ / เวอร์ชัน | MA_RangeBot / 1.0.0 |
| TAG / ลำดับ EA / Magic ฐาน | ยังไม่กำหนด (ผู้ใช้รัน init_strategy.py และตรวจซ้ำเอง) |
| Core ฐาน | v1.1 (Commit ฐานของงาน unknown) |
| ชนิดบัญชี | ACCT_ANY [ข้อเสนอ] (Netting ต้องมี Symbol Lock) |
| Order | Market เท่านั้น |
| Timeframe | Entry H1 / HTF H4 ตัดสินเข้าเมื่อเกิดแท่ง H1 ใหม่ จัดการไม้ทุก Tick |
| Symbol เริ่มต้น | XAU (XAG/US100/BTC ทำโปรไฟล์ทีหลัง) |

### 2.1 เงื่อนไขเข้า (คงตาม Blueprint A2, A4)
1. Regime = RANGE (ADX_RangeMax 20, BB/EMA ตามกลุ่ม 2, RegimeConfirmBars 2)
2. FOLLOW_HTF: ทิศตาม EMA200 H4 (ถ้า NONE ข้าม)
3. กรอบใช้ได้: ความสูง 2.0-6.0 ATR, แตะขอบละ >= 2 ครั้ง, ExcludeBars 1, RangeLock
4. ADXSlope ต้องไม่ชันขึ้น (ตัวกรองเสริม)
5. ZONE: Low[1] <= rLow + height*25%, Close[1] > rLow, แท่งเขียว, ผ่าน Trigger
6. SWEEP: ไส้แทง 0.1-1.0 ATR, ปิดกลับในกรอบ, ไส้ >= 1.5 x เนื้อเทียน
7. เกิดทั้งคู่ในแท่งเดียว ใช้ SWEEP
8. MinRR_TP1 >= 1.2, MaxPositions = 1
(Sell กลับด้าน)

### 2.2 SL / TP / บริหารไม้
- SL: ZONE = ขอบ - 1.0 ATR | SWEEP = ปลายไส้ - 0.3 ATR
- TP1 = ขอบตรงข้าม - 0.1 ATR | TP2 = ขอบที่เบรก + ความสูงกรอบ
- ถึง TP1: ปิด 50% + เลื่อน SL ไปทุน (Lot ขั้นต่ำ: เลื่อน SL อย่างเดียว)
- Hand-off: ปิดนอกกรอบ >= 0.2 ATR -> Chandelier 22 / 3.0
- Timeout 24 แท่งหลัง TP1 ปิดส่วนที่เหลือ | OnTrendShift_PreTP1 = KEEP/TIGHTEN/CLOSE
- ค่า Input ทั้งหมดตามตาราง A3 ของ Blueprint ต้นฉบับ (ไม่คัดซ้ำที่นี่)

### 2.3 Basket และปุ่ม
- 1 ไม้ (แบ่งปิด 2 ส่วน) = 1 รอบ Basket เรียก BeginBasketCycle ก่อนส่งออเดอร์แรก [OK ว่ามี API] [ข้อเสนอ ว่านิยามรอบ]
- ปุ่ม OFF = หยุดเข้าใหม่ แต่ยังจัดการไม้เดิมต่อ [ข้อเสนอ]
- ปุ่มของกลยุทธ์ (ไม่เกิน 3): ยังไม่กำหนด

## 3. ผลกระทบต่อ Core: ตารางการแมป
| ส่วนใน Blueprint ต้นฉบับ | แนวทางกับ Core v1.1 | สถานะ |
|---|---|---|
| OnInit/OnTick/OnDeinit | ใช้ Core_Runtime เรียก Strategy_Init / Strategy_OnTick | [OK] |
| API กลยุทธ์ | เขียน Strategy_Title, Version, AccountSupport, Init, OnTick, CloseAll, ButtonCount, ButtonDef, OnButton, GateText ครบ 10 | [OK] |
| ปุ่ม ON/OFF, Panel | ใช้ของ Core, CoreIsPaused ก่อนเปิดใหม่ทุกทาง | [OK] |
| ทุน / RiskModule | อ่านทุนด้วย TryGetVirtualEquity ไม่คำนวณเอง | [OK] |
| Session / Spread / Timeout | ใช้ประตู CanOpenAuto ของ Core แทน SafetyFilters ในส่วนที่ซ้ำ | [OK] |
| Lot แบบ RISK_PERCENT | Core มี InpBaseLot / LotIncrement / LotStepMoney ต้องเลือกระหว่างใช้ Lot ของ Core หรือคำนวณเอง | [ต้องตรวจ] Core_Inputs, Core_Capital |
| SL/TP ตาม ATR และขอบกรอบ | OpenOneOrder ของ Core ใส่ SL คงที่ InpCutLossPoints และไม่มี TP จึงใช้ตรงๆ ไม่ได้ | [OK ว่าติด] ต้องดู Core_Trade |
| ปิดบางส่วน / เลื่อน SL / Chandelier | ต้องมี API แก้ SL และปิดบางส่วนของไม้ที่เปิดอยู่ และต้องไม่ชนกับ Protect (BE/RR/Trailing TP) ของ Core | [ต้องตรวจ] Core_Protect, Core_Trade |
| StateStore (กู้ HANDED_OFF หลังปิด MT5) | ใช้ Global Variable ผ่านรูปแบบ State ของ Core ถ้ามี API | [ต้องตรวจ] |
| Symbol Lock (Netting) | Core_Lock ป้องกัน Magic ซ้ำเท่านั้น ไม่ใช่ Lock ข้ามบอท | [ข้อเสนอ] ตัดออกถ้าไม่ทำ Trend Bot |
| SharedRisk กลุ่ม MA, ขาดทุนรายวันรวมกลุ่ม | ตัดออกจากเฟสนี้ | [ข้อเสนอ] |
| NewsFilter / Rollover / FridayCutoff | Core มี Session แต่ไม่เห็นข่าว ทำเป็นเฟสหลัง หรือเลือกเฉพาะที่จำเป็น | [ต้องตรวจ] Core_Session |
| CSV Log / MFE-MAE | Core มี Report CSV ส่วน MFE/MAE ถ้าต้องการทำเพิ่มในกลยุทธ์ | [ต้องตรวจ] Core_Report |
| Input ซ้ำ (Risk, Spread, Session, Magic, Timeout) | ใช้ของ Core ตัดออกจากกลุ่ม 10-11 ของกลยุทธ์ | [ต้องตรวจ] Core_Inputs |

### 3.1 เส้นทางตัดสินใจสำหรับจุดติด
- ทาง A (ไม่แตะ Core): ถ้า Core เปิดให้กลยุทธ์ส่งออเดอร์และแก้ SL เองได้ ให้ทำในไฟล์กลยุทธ์ และปิด BE/RR/Trailing ของ Core ด้วย Input
- ทาง B (งาน Core แยก): ถ้าไม่มี API ที่ต้องใช้ ให้หยุด เปิดงาน Core ที่ Repo EA_Platform_Core แล้วนำ Core ใหม่เข้าด้วย update_core.py (ห้ามแก้สำเนา Core)
- ทาง C (ลดขอบเขต v1.0): ใช้ SL/TP ตั้งตอนเข้า + TP1 เดียว ไม่ทำ Hand-off/Chandelier ไว้ v1.1 ของกลยุทธ์

## 4. แผนไฟล์ (Folder Tree: ข้อเสนอ ยังไม่เริ่มงาน)
Strategies/MA_RangeBot/v1.1/
  MA_RangeBot_EA.mq5        define STRATEGY_*, include Core + ไฟล์กลยุทธ์
  MA_RangeBot_EA_EN.mq5     define INPUT_LANG_EN แล้ว include EA หลัก
  MA_RangeBot_EA_TH.mq5     include EA หลัก
  include/MA_RangeBot_Inputs.mqh     Input เฉพาะกลยุทธ์ (2 ภาษา)
  include/MA_RangeBot_Regime.mqh     Regime: ADX/BB/EMA + Confirm
  include/MA_RangeBot_Range.mqh      RangeDetector + RangeLock
  include/MA_RangeBot_Signals.mqh    ZONE/SWEEP + Trigger + ตัวกรองเสริม
  include/MA_RangeBot_Manager.mqh    RangeManager (TP1, BE, Hand-off, Timeout) [ขึ้นกับทาง A/B/C]
  include/MA_RangeBot_Strategy.mqh   Strategy_* ครบ 10 ตัว ต่อทุกส่วนเข้าด้วยกัน
  Core/                     สำเนา Core v1.1 (ไม่แก้)
  Set/                      00_baseline ... 99_final
(เลขโฟลเดอร์ต้องตรงรุ่น Core ตาม D-28.1 ตรวจกับ init_strategy.py)
ชื่อไฟล์ตาม D-18 และ Include Guard ไม่ชน CORE_*_MQH

## 5. แผนทดสอบ
- Test Case 1-10 ตาม A6 ของ Blueprint ต้นฉบับ เพิ่ม: เคารพ CoreIsPaused, Comment <= 25 ตัวอักษร, EN/TH Input ตรงกัน
- ทดสอบบน Demo เท่านั้น บันทึกใน TEST_MATRIX.md (PASS / PASS* / BLOCKED / ยังไม่ทดสอบ)
- Ablation และเกณฑ์ OOS (PF >= 1.3, ไม้ >= 100, DD <= 15-20%, RF >= 2, Stress PF > 1.1) ตาม A7-A8
- คอมไพล์ผ่านไม่ใช่หลักฐานว่าไม่มีบั๊ก

## 6. เรื่องที่ยังไม่ตัดสิน
1. TAG, ลำดับ EA, Magic ฐาน (ตรวจซ้ำเอง)
2. เลือกทาง A / B / C ในข้อ 3.1 (รอไฟล์ Core_Protect, Core_Trade, Core_Basket, Core_Inputs, PINNED_FROM.txt)
3. ใช้ Lot ของ Core หรือคำนวณ RISK_PERCENT เอง
4. ขอบเขต SharedRisk / Trend Bot (ข้อเสนอ: ตัดออก)
5. NewsFilter, Rollover, FridayCutoff ทำในเฟสนี้หรือไม่
6. ปุ่มของกลยุทธ์ (ไม่เกิน 3) และพฤติกรรมของปุ่ม OFF
7. ชนิดบัญชีที่ใช้จริง
8. Commit ฐานของงาน (unknown)
