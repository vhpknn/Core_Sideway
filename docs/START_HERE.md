# START HERE (แม่แบบ New_Strategies)

อ่านตามลำดับ:
1. `README_FIRST.md` ภาพรวม 4 เฟส
2. `docs/RULES.md` กติกากลาง
3. `docs/AI_READ_SCOPE.md` ขอบเขตการอ่านของ AI
4. `docs/work/CURRENT_STATE.md` สถานะงานปัจจุบัน
5. `docs/BLUEPRINT.md` สเปกที่ตกลงกัน (ถ้ามี)

## แผนที่โฟลเดอร์
```text
README_FIRST.md, TEMPLATE_VERSION, STRATEGY_IDENTITY.txt (หลัง init)
docs/            เอกสาร (START_HERE, RULES, AI_READ_SCOPE, SPEC_FORM, BLUEPRINT)
docs/handoff/    แม่แบบส่งต่องานและกติกา Jigsaw Patch
docs/decisions/  มติแพลตฟอร์มที่คัดลอกมา (อ่านอย่างเดียว) และ STRATEGY_DECISIONS.md ของกลยุทธ์นี้
docs/work/       CURRENT_STATE, LOG, TEST_MATRIX และเอกสารอัปเดต Core
docs/reference/  ธีม Panel ต้นฉบับ และตัวอย่างรูปแบบเอกสาร
Core/v<รุ่น>/    สำเนา Core ฐานที่ปักไว้ (อ่านอย่างเดียว) พร้อม PINNED_FROM.txt
Strategies/<ชื่อ>/v<รุ่น>/  โค้ดกลยุทธ์ (EA 3 ไฟล์, include/, Set/, Core/ สำเนา)
reference/Hedge_example/    ตัวอย่างโค้ดกลยุทธ์จริง อ่านอย่างเดียว ไม่ใช่ให้คัดลอก Logic
tools/           เครื่องมือ (ดู tools/README_tools.md)
```
ก่อนรัน `tools/init_strategy.py` โฟลเดอร์กลยุทธ์ชื่อ `Strategies/Template/` เป็นโครงเปล่าที่คอมไพล์ได้ ไม่มีตรรกะเทรด
