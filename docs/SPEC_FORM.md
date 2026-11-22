# SPEC FORM: ฟอร์มสเปกกลยุทธ์ (ผู้ใช้เติม แล้วให้ AI สรุปลง BLUEPRINT.md)

เงื่อนไข: Core ฐานต้องระบุรุ่นและ Commit ชัด (ดู `Core/v<รุ่น>/PINNED_FROM.txt`) สเปกต้องมาจากผู้ใช้ AI ห้ามเดา ข้อไหนยังไม่ตัดสินให้เขียนใน "เรื่องที่ยังไม่ตัดสิน"

- ชื่อกลยุทธ์ / เวอร์ชัน: ____
- TAG (3 ตัวอักษร) / ลำดับ EA (Magic ฐาน = ลำดับ x 10000): ____
- Core รุ่นและ Commit ฐาน: ____
- ชนิดบัญชี Hedging / Netting / ใช้ได้ทั้งคู่: ____
- เงื่อนไขเข้า (ทีละข้อ): ____
- ชนิด Market / Pending และวิธีคำนวณราคา: ____
- Lot / ทุน / Auto-Lot / ค่าเริ่มต้น Lock Profit: ____
- SL / TP และความเสี่ยงต่อไม้: ____
- นิยาม Basket และเงื่อนไขเปิดรอบใหม่: ____
- ปุ่ม OFF หยุดเข้าใหม่ และทำอย่างไรกับออเดอร์ค้างที่รออยู่: ____
- ปุ่มของกลยุทธ์ (ไม่เกิน 3 ปุ่ม): ____
- Inputs: ชื่อ ชนิด ค่าเริ่มต้น ป้ายไทย ป้ายอังกฤษ: ____
- Preset และเงื่อนไขทดสอบ: ____
- เรื่องที่ยังไม่ตัดสิน: ____

## สัญญากับ Core (AI ต้องรู้ก่อนวางแผน)
- API กลยุทธ์ใน Core v1.0 มี 10 ฟังก์ชัน: `Strategy_Title`, `Strategy_Version`, `Strategy_AccountSupport`, `Strategy_Init`, `Strategy_OnTick`, `Strategy_CloseAll`, `Strategy_ButtonCount`, `Strategy_ButtonDef`, `Strategy_OnButton`, `Strategy_GateText` (ตรวจจากไฟล์ `Core_StrategyAPI.mqh` ของรุ่นที่ใช้จริง API ที่เพิ่มในรุ่นหลังต้องอ่านจากรุ่นนั้น)
- EA หลักต้อง `#define` `STRATEGY_TAG`, `STRATEGY_EA_ORDINAL`, `STRATEGY_MAGIC_BASE`, `STRATEGY_MAGIC_NEXT`, `STRATEGY_DEFAULT_COMMENT` ก่อน include Core
- ทุกทางเปิดออเดอร์ใหม่ต้องเคารพ `CoreIsPaused`, อ่านทุนด้วย `TryGetVirtualEquity` (ไม่คำนวณเอง), เรียก `BeginBasketCycle` ก่อนเปิดรอบ
- ไม่แก้ธีมและชื่อ Object ที่ใช้ร่วม Panel ต้องไม่ล้นทั้ง 4 ระดับ Comment รูปแบบ `<TAG><Magic> ...` ไม่เกิน 25 ตัวอักษร
- Inputs และ enum สองภาษาต้องมีชื่อ ชนิด ลำดับ ค่าเริ่มต้นเหมือนกัน (ต่างเฉพาะป้าย) ไฟล์ `.set` ใช้ร่วมกันได้
