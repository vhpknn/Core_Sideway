# RangeBot คู่มือผู้ใช้ (กลยุทธ์ 1.0.0 บน Core v1.1)

## 1. ภาพรวม
RangeBot เทรดกลับตัวที่ขอบกรอบราคา (Range) ของ XAUUSD บน H1 ลำดับงาน: ตรวจสภาพตลาด (Regime) > หากรอบและล็อก > ประเมินสัญญาณที่ขอบกรอบเมื่อเกิดแท่งใหม่ > เปิดไม้ + ตั้ง SL/TP ตาม ATR > จัดการไม้จนปิด ทดสอบแล้วเฉพาะ Strategy Tester บัญชี Demo ยังไม่ผ่านการทดสอบบน Demo จริงหรือ Live

## 2. ข้อกำหนดก่อนใช้
- ปิด Protect ของ Core: `InpRRPercent=0`, `InpUseTrailingTP=false`, `InpBreakEvenMode=BE_OFF` (ไม่ตรง EA ไม่เริ่มทำงาน)
- `InpCutLossPoints=3000` (ต้องกว้างกว่า SL ของกลยุทธ์ มิฉะนั้นสัญญาณถูกตัดด้วย SL_TOO_FAR) และ `InpMaxSpreadPoints=45` สำหรับ XAUUSD ของ FBS Demo
- ขนาดล็อตมาจาก Virtual Capital Auto-Lot ของ Core ไม่ใช่เปอร์เซ็นต์ความเสี่ยง
- ใช้ `.set` ในโฟลเดอร์ `Strategies\RangeBot\v1.1\Set\` (ชุด 00 ถึง 10) ที่สร้างจาก `tools\make_rangebot_sets.py`

## 3. เริ่มใช้งาน
1. คอมไพล์ `RangeBot_EA_TH.mq5` (ป้ายไทย) หรือ `RangeBot_EA_EN.mq5` (ป้ายอังกฤษ)
2. แนบ EA ที่กราฟ XAUUSD H1 โหลด `.set` ที่ต้องการ (เริ่มที่ `00_baseline`)
3. ตรวจ Journal: ต้องเห็น `Protect ของ Core ถูกปิด...` และ `เริ่มระบบสำเร็จ`

## 4. การทำงานทีละขั้น
| ขั้น | เกิดอะไรขึ้น |
|---|---|
| Regime | ADX, Bollinger width, EMA แยก RANGE / NEUTRAL / TREND_UP / TREND_DOWN (ต้องยืนยัน 2 แท่ง) |
| Range | ใช้ 30 แท่ง (ไม่นับแท่งล่าสุด) สูง 2 ถึง 6 ATR แตะแต่ละขอบอย่างน้อย 2 ครั้ง แล้วล็อกจนเบรก (ปิดนอกกรอบเกิน 0.5 ATR) หรือครบ 30 แท่ง |
| สัญญาณ | ZONE (ราคาเข้าโซน 25% ของขอบ + แท่งกลับตัว) หรือ SWEEP (ไส้แทงออกแล้วปิดกลับ) + Trigger (RSI/STOCH/CANDLE/NONE) + ตัวกรอง |
| เข้าไม้ | ต้องผ่านเพดานความเสี่ยง (`InpCutLossPoints`) และ RR ถึง TP1 ไม่ต่ำกว่า 1.2 สัญญาณรอได้ไม่เกิน 15 นาที |
| จัดการไม้ | ถึง TP1 > SL ไปทุน+0.1 ATR > Hand-off เมื่อปิดนอกกรอบ (Trail Chandelier) หรือ Timeout หลัง TP1 24 แท่ง > MaxHold ก่อน TP1 (ปิดเป็นค่าเริ่มต้น) |
| TREND SHIFT | ก่อน TP1 ถ้าเทรนด์สวนทิศไม้: KEEP (ค่าเริ่มต้น) / TIGHTEN / CLOSE |
| Cooldown | หลังตัวจัดการปิดไม้ ไม่เปิดไม้ใหม่จนจบแท่งนั้น |

## 5. Inputs ที่ปรับบ่อย
| กลุ่ม | Input | ค่าเริ่มต้น | ความหมาย |
|---|---|---|---|
| R2 | InpRbAdxRangeMax / TrendMin | 20 / 25 | ADX ต่ำสุดที่ยังเป็น RANGE / สูงสุดที่เป็น TREND |
| R3 | InpRbRangeLookback, MinTouches | 30, 2 | จำนวนแท่งสร้างกรอบ, ครั้งที่แตะขอบ |
| R4 | InpRbRangeDirection | FOLLOW_HTF | ตามทิศ H4 (EMA200) หรือ BOTH_EDGES |
| R5 | InpRbEntryType, ZoneEntryPct | BOTH, 25 | ZONE / SWEEP / BOTH, ความลึกโซน |
| R6 | InpRbTriggerType | RSI | RSI / STOCH / CANDLE / NONE |
| R7 | InpRbUseAdxSlope, UseAtrVolFilter, UsePercentB | true, true, false | ตัวกรองเสริม |
| R8 | InpRbZoneSlAtr, MinRrTp1, UseTp2 | 1.0, 1.2, true | SL นอกขอบ, RR ขั้นต่ำ, TP ของโบรก = TP2 |
| R9 | InpRbSignalWaitMinutes, BeBufferAtr, UseMidRangeBe | 15, 0.1, false | อายุสัญญาณ, ระยะทุน, ย้าย SL ที่กลางกรอบ |
| R9 | InpRbUseHandOff, ChandelierPeriod/Mult | true, 22/3.0 | Hand-off และ Trail |
| R9 | InpRbUseRangeTimeout, RangeTimeoutBars | true, 24 | ปิดไม้หลัง TP1 ถ้ากรอบไม่เบรก |
| R9 | InpRbOnTrendShiftPreTp1 | KEEP | ทำอะไรเมื่อเทรนด์สวนทิศก่อน TP1 |
| R9 | InpRbUseMaxHold, MaxHoldBars | false, 48 | ปิดไม้ที่ถือเกินกำหนดโดยยังไม่ถึง TP1 |

## 6. ปุ่มบน Panel
- RESET RANGE: ปลดล็อกกรอบและหากรอบใหม่ ไม่ปิดไม้ ไม่แตะทุน
- BE NOW: ย้าย SL ของไม้ที่เปิดอยู่ไปทุน (เฉพาะเมื่อดีกว่า SL เดิม และห่างราคาตาม Stop Level)

## 7. อ่าน Journal
| บรรทัด | แปลว่า |
|---|---|
| `SIGNAL BUY/SELL ZONE/SWEEP` | เกิดสัญญาณ รอเงื่อนไขเปิดไม้ |
| `SIGNAL WAIT | <เหตุผล>` | รอ (SL_TOO_FAR, RR_LOW, WAIT_SPREAD ...) |
| `SIGNAL EXPIRED` / `SIGNAL DROPPED | COOLDOWN` | สัญญาณหมดอายุ / ถูกทิ้งเพราะพักหลังปิดไม้ |
| `ENTRY` / `SL/TP SET` | เปิดไม้ / ตั้ง SL/TP สำเร็จ |
| `TP1 HIT`, `MID-BE`, `HAND-OFF`, `TRAIL` | เหตุการณ์จัดการไม้ |
| `TIMEOUT`, `MAXHOLD`, `TREND SHIFT` | เงื่อนไขปิด/ปรับไม้ก่อนกำหนด |
| `TRADE CLOSED` | ไม้ปิด พร้อมสถานะและจำนวนแท่งที่ถือ |

## 8. ข้อจำกัด
- ไม่มี Partial Close (Core ปิดได้เต็มไม้) ถึง TP1 เลื่อน SL ไปทุนเท่านั้น
- เก็บ/กู้สถานะด้วย Global Variable ใช้ไม่ได้ใน Strategy Tester และยังไม่ผ่านการทดสอบบน Demo
- Tester จำลองดีเลย์การส่งคำสั่งสุ่มหลายวินาที คำสั่งแก้ SL อาจล้มเหลวด้วย Invalid stops ซึ่ง EA จัดการต่อได้
- ผลทดสอบปัจจุบันมีไม้น้อย (ช่วง Tick จริงสั้น) ยังสรุปกำไรขาดทุนของกลยุทธ์ไม่ได้ ดู `docs/work/TEST_MATRIX.md`