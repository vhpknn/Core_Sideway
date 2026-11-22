# BLUEPRINT: RangeBot (ร่าง v0.2 บน Core v1.1 ไม่แก้ Core)

สถานะ: ร่าง รอผู้ใช้พิมพ์ "เริ่มงาน" | อัปเดต: 2026-11-22
ที่มา: Blueprint-A-Range-Bot-MA_RangeBot.md (ตรรกะ) + Core v1.1 ที่ปักไว้ (Repo vhpknn/Core_Sideway @28e63c0)
Commit ฐานของงานหลัง init: ยังไม่มี (ยังไม่ Commit)
ป้าย: [OK] ตรวจจากไฟล์ที่เปิดอ่านจริง | [ข้อเสนอ] ข้อเสนอของ AI รอยืนยัน | [ต้องตรวจ] ยังไม่เห็นไฟล์

## 1. เป้าหมาย
เทรดเฉพาะตลาด RANGE (XAU, EntryTF H1, HTF H4) เข้าที่ขอบกรอบด้วย ZONE/SWEEP แบบ Market
หยุดเปิดไม้ใหม่เมื่อไม่ใช่ RANGE | จัดการไม้ที่เปิดอยู่ทุก Tick | ผ่าน TP1 แล้วเบรกกรอบ -> Hand-off Chandelier

## 2. สเปก (SPEC_FORM)
| หัวข้อ | ค่า |
|---|---|
| ชื่อ / เวอร์ชัน | RangeBot / 1.0.0 |
| TAG / ลำดับ / Magic ฐาน | RNG / 4 / 40000 (ช่วง 40000-49999, ถัดไป 40001) [OK จาก init_strategy] |
| Comment ตั้งต้น | RNG40000 H1 base (ไม่เกิน 25 ตัวอักษร) |
| Core ฐาน | v1.1 ไม่แก้ (source commit 30c3001e) |
| ชนิดบัญชี | เลือกใน Input: AUTO(ACCT_ANY) / HEDGING_ONLY / NETTING_ONLY ผ่าน Strategy_AccountSupport() [OK ว่าทำได้] |
| Order | Market เท่านั้น |
| Lot | Auto-Lot ของ Core: GetEffectiveLotForEquity(TryGetVirtualEquity) ไม่มี RISK_PERCENT/FIXED_LOT [OK] |
| Basket | 1 ไม้ = 1 รอบ ใช้ CoreBasketPositions()==0 + BeginBasketCycle() ก่อนเปิด |

### 2.1 เงื่อนไขเข้า / SL / TP / จัดการไม้
คงตาม Blueprint ต้นฉบับ A2, A4 (Regime, RangeDetector+Lock, ZONE/SWEEP, Trigger, ตัวกรองเสริม, SL/TP1/TP2 ตาม ATR, MinRR 1.2)
ปรับตาม Core v1.1:
- ไม่มีการปิดบางส่วน: ถึง TP1 -> เลื่อน SL ไปทุน (+BE_BufferATR) แล้วถือต่อ
- TP1 เป็นระดับเสมือน (ไม่ตั้งเป็น TP จริงของโบรก) | TP จริงของโบรก = TP2
- Hand-off: ปิดนอกกรอบ >= HandOff_BreakATR -> ถอด TP2 (tp=0) -> Chandelier ผ่าน ModifySL
- Range timeout / MaxHold / OnTrendShift_PreTP1 ตามเดิม
- ตรวจ SYMBOL_TRADE_STOPS_LEVEL ก่อนตั้ง SL/TP (Core ไม่ตรวจให้) [ข้อเสนอ]

### 2.2 วิธีใช้ Core (ไม่แก้ Core)
- เปิดไม้: OpenOneOrder(dir, lot, tag) -> หา ticket จาก Position (Symbol+Magic) -> ModifySL(ticket, SL ATR, TP2, tag) [OK]
- ถ้า ModifySL ล้มเหลว: ลองใหม่ Tick ถัดไป เกิน 3 ครั้งให้ RawPositionClose / CloseOneSide [ข้อเสนอ]
- ปิด Protect ผ่าน .set: InpRRPercent=0, InpUseTrailingTP=false, InpBreakEvenMode=BE_OFF, InpCutLossPoints กว้างกว่า SL ATR สูงสุด (Protect ขยับ SL เฉพาะทิศที่ปลอดภัยขึ้น) [OK จาก Core_Protect]
- Strategy_Init ตรวจว่า Protect ถูกปิดจริง ถ้าไม่ใช่ Alert + return false [ข้อเสนอ]
- ประตูเปิดรอบ: CoreIsPaused, CanOpenAuto(g_emptySince, reason) ตามแบบ Hedge (TryOpenNewRound) และตั้ง g_emptySince=0 หลังเปิดสำเร็จ [OK]
- State กลยุทธ์ (rHigh/rLow ที่ล็อก, TP1-hit, HANDED_OFF): GlobalVariable ใช้ CoreStateGVName(suffix) (รูป <TAG>S_<บัญชี>_<Symbol>_<Magic>_<suffix>) ความยาวรวม <= 63 และไม่เขียนใน Strategy Tester ตามแบบ Hedge [OK]
- Session/Spread/Timeout: ใช้ของ Core (Session = ช่วงหยุดเทรดตามเวลาเซิร์ฟเวอร์, Spread เป็น Points, Timeout = รอหลัง Basket ว่าง) ตัด Input ซ้ำของ Blueprint ออก

## 3. ปุ่ม
- ปุ่มพื้นฐานของ Core คงเดิม (ON/OFF, CLOSE BUY, CLOSE SELL, REFILL, CLOSE ALL, RESET ทุนเสมือน)
- ตัดปุ่มของ Hedge (BUY LOCKED, SELL LOCKED, HEDGE OPEN) ทั้งหมด
- ปุ่มของกลยุทธ์ (Strategy_ButtonCount = 2):
  1. id RANGE_RESET ข้อความ "RESET RANGE": ปลดล็อกกรอบ (RangeLock) แล้วหากรอบใหม่ ไม่ปิดไม้ ไม่ยุ่งทุน (ต่างจากปุ่ม RESET ของ Core ที่เติมทุนเสมือน ใส่ Tooltip ให้ชัด)
  2. id BE_NOW ข้อความ "BE NOW": เลื่อน SL ของไม้ที่เปิดอยู่ไปที่ทุน (+BE_BufferATR) เฉพาะเมื่อดีกว่า SL เดิม ไม่ทำถ้าไม่มีไม้
- ทั้งสองปุ่มไม่เปิดออเดอร์ใหม่ จึงใช้ได้แม้ OFF อยู่

## 4. แผนไฟล์ (หลัง init_strategy)
Strategies/RangeBot/v1.1/
  RangeBot_EA.mq5          [สร้างแล้วโดย init ต้องขอเนื้อไฟล์] define STRATEGY_* + include ไฟล์กลยุทธ์ (เพิ่ม include 4 ไฟล์ใหม่)
  RangeBot_EA_EN.mq5 / RangeBot_EA_TH.mq5   [สร้างแล้ว]
  include/RangeBot_Inputs.mqh      [แก้] Input 2 ภาษา: ชนิดบัญชี, Regime, ทิศ, กรอบ, จุดเข้า, Trigger, ตัวกรอง, SL/TP, บริหารไม้, Log
  include/RangeBot_Regime.mqh      [ใหม่] RbRegimeUpdate(), RbIsRange(), RbIsTrend()
  include/RangeBot_Range.mqh       [ใหม่] RbRangeDetect(), RbRangeLockLoad/Save/Clear()
  include/RangeBot_Signals.mqh     [ใหม่] RbCheckZone(), RbCheckSweep(), RbTriggerOK(), RbExtraFilters(), RbHtfBias()
  include/RangeBot_Manager.mqh     [ใหม่] RbOpenTrade(), RbManageTrade(), RbBreakEvenNow(), RbHandOff*(), State GV
  include/RangeBot_Strategy.mqh    [แก้] Strategy_* ครบ 10 ตัว + RbOnTick() + ปุ่ม 2 ตัว + Strategy_GateText
  Set/                             .set ตามแผน Ablation (00_baseline ... 99_final)
ชื่อไฟล์และ Include Guard ตาม D-18 (RANGEBOT_*_MQH ไม่ชน CORE_*_MQH)

## 5. แบ่งชุดงาน (ทดสอบหลังจบแต่ละชุด)
- ชุด 1: Inputs + Strategy skeleton (ชนิดบัญชี, ปุ่ม 2 ตัวยังไม่ทำงาน) -> คอมไพล์ 0/0
- ชุด 2: Regime + Range (ยังไม่เปิดไม้ แสดงผลที่ GateText/Log) -> คอมไพล์ + แนบ Demo ดู Log
- ชุด 3: Signals + RbOpenTrade (SL/TP ผ่าน ModifySL)
- ชุด 4: Manager (TP1->BE, Hand-off, Timeout, MaxHold, State, BE NOW, RESET RANGE)
- ชุด 5: .set + TEST_MATRIX + คู่มือ
ทุกชุดจบด้วยรายการคำสั่งที่ผู้ใช้ต้องรัน (คอมไพล์ EA 3 ตัว, tools\run_checks.bat)

## 6. แผนทดสอบ
Test Case 1-10 ของ Blueprint ต้นฉบับ ปรับ: #7 กลายเป็นพฤติกรรมปกติ (ไม่มีปิดบางส่วน) + ทดสอบเพิ่ม: Protect ถูกปิด, ModifySL ล้มเหลว, Netting vs Hedging, ปุ่ม 2 ตัว, เคารพ CoreIsPaused, Comment <= 25 ตัวอักษร
เกณฑ์ OOS ใน A7: ประเมินอัตราชนะ/กำไรเฉลี่ยใหม่ เพราะไม่มีปิดบางส่วน
ทดสอบ Demo เท่านั้น บันทึกใน docs/work/TEST_MATRIX.md

## 7. เรื่องที่ยังไม่ตัดสิน
1. ค่า InpCutLossPoints ที่ใช้ใน .set (ต้องกว้างกว่า SL ATR สูงสุด และเป็น SL ชั่วคราวช่วงก่อน ModifySL สำเร็จ)
2. NewsFilter / Rollover / FridayCutoff ใน v1.0 หรือไม่ (ข้อเสนอ: ตัดไว้รุ่นหลัง)
3. MFE/MAE Log ใน v1.0 หรือไม่
4. การปิดบางส่วน: รอ Core รุ่นที่มี API (นำเข้าด้วย update_core.py)
