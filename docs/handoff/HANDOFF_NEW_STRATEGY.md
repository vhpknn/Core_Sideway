# HANDOFF: ส่งต่องานสร้างกลยุทธ์ (ฉบับแม่แบบ New_Strategies)

ปรับจากแม่แบบกลยุทธ์ใหม่ฉบับ 2 ของแพลตฟอร์ม ใช้ร่วมกับ `docs/RULES.md` และ `docs/SPEC_FORM.md`

## 1. เงื่อนไข
- Core ฐานต้องผ่านและระบุรุ่น/Commit ชัด (`Core/v<รุ่น>/PINNED_FROM.txt`) สเปกต้องมาจากผู้ใช้ ไม่เดา
- ถ้าต้องเพิ่ม Core ทำเป็นงานแยกที่ Repo EA_Platform_Core ห้ามแก้ Core ฐานหรือสำเนาในกลยุทธ์

## 2. โครงสร้างโค้ดกลยุทธ์
```text
Strategies/<ชื่อ>/v<รุ่น>/
  <ชื่อ>_EA.mq5        EA หลัก กำหนด STRATEGY_* แล้ว include Core และไฟล์กลยุทธ์
  <ชื่อ>_EA_EN.mq5     define INPUT_LANG_EN ก่อน include EA หลัก (ป้ายอังกฤษ)
  <ชื่อ>_EA_TH.mq5     include EA หลักโดยไม่ define (ป้ายไทย)
  include/<ชื่อ>_Inputs.mqh
  include/<ชื่อ>_Strategy.mqh
  Core/include/        สำเนา Core ไม่แก้เอง
  Core/CORE_MANIFEST.txt
  Set/                 ไฟล์ชุดค่า .set
```
EA หลักไม่มี `INPUT_LANG_EN` EN/TH ต่างเฉพาะป้าย ไม่ใช่สิทธิ์เงินจริงหรือระบบความปลอดภัย ตัวอย่างโค้ดจริงอยู่ที่ `reference/Hedge_example/`

## 3. สัญญาและกติกาโค้ด
- กำหนด `STRATEGY_TAG`, `STRATEGY_EA_ORDINAL`, `STRATEGY_MAGIC_BASE`, `STRATEGY_MAGIC_NEXT`, `STRATEGY_DEFAULT_COMMENT` ก่อน include Core
- API ที่มี ต้องอ่านจาก `Core_StrategyAPI.mqh` ของรุ่นที่ใช้จริง ห้ามอ้างว่ามีจากแผน
- ทุกทางเปิดใหม่เคารพ `CoreIsPaused` อ่านทุนด้วย `TryGetVirtualEquity` ยอด RESET รวมถาวรตาม Magic ก่อนเปิดรอบเรียก `BeginBasketCycle`
- Protect ใน Core ใช้ระยะคงที่ ถ้าต้องใช้ความเสี่ยงต่อไม้แบบอื่นต้องกำหนดส่วนเพิ่มและทดสอบแยก

## 4. วิธีทำงาน
1. สรุปสเปก ถามเฉพาะจุดที่ขาด
2. ส่ง Folder Tree หน้าที่ต่อไฟล์ ไฟล์ API ที่ใช้ และผลกระทบ แล้วรอคำว่า "เริ่มงาน"
3. ไฟล์ใหม่ Full Code ไฟล์เดิม FIND/REPLACE (ผู้ใช้คัดลอกเอง)
4. บันทึก > คอมไพล์ EA 3 ตัว (0/0) > `tools\run_checks.bat`
5. ทำ Test Matrix และคู่มือผู้ใช้ภาษาไทยที่ใช้ชื่อ Inputs อังกฤษจริง ระบุ Set, Magic, เวลา, ปุ่ม, ผลและหลักฐาน
6. สรุปผลตามหลักฐาน แยก PASS / PASS* / BLOCKED / ยังไม่ทดสอบ ไม่ประกาศว่าไม่มีบั๊กจากการคอมไพล์ผ่าน
7. ผู้ใช้ Commit เอง AI ไม่เขียน GitHub

## 5. ข้อความเริ่มต้น
ดู `docs/AI_START_PROMPT.md`
