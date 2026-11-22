# D-29 — โครงโฟลเดอร์ของกลยุทธ์ (เอกสารและเครื่องมือเฉพาะกลยุทธ์อยู่ในโฟลเดอร์ของกลยุทธ์)

วันที่: 17 พ.ย. 2026 | สถานะ: ใช้อยู่ (นำร่องที่ TradeDesk) | ตัดสินโดยผู้ใช้

## 1. มติ
1. ไฟล์ที่ใช้กับกลยุทธ์เดียวเท่านั้น อยู่ใน `Strategies/<ชื่อ>/` ตามโครงนี้:

```text
Strategies/<ชื่อ>/
  README.md     ภาพรวมกลยุทธ์ + สารบัญว่าไฟล์ไหนอยู่ตรงไหน (เปิดไฟล์นี้ก่อน)
  doc/          Blueprint, CURRENT_STATE, SPEC, TEST_MATRIX, LOG, คู่มือผู้ใช้
  tools/        เครื่องมือเฉพาะกลยุทธ์นี้ (เช่น เซิร์ฟเวอร์จำลองของ TradeDesk)
  v*/           โค้ดจริงของแต่ละรุ่น (EA, include, สำเนา Core, Set)
```

2. ของส่วนกลางอยู่ที่รากเหมือนเดิม: `Core/`, `tools/` (sync_core, verify_core, next_magic, check_docs, make_ai_bundle, run_checks), `docs/decisions/` (รวม MAGIC_REGISTRY), `docs/handoff/`, `docs/START_HERE.md`, `docs/AI_READ_SCOPE.md`
3. ชื่อโฟลเดอร์ `doc` และ `tools` ในกลยุทธ์ต้องไม่ขึ้นต้นด้วยตัว v เพราะเครื่องมือสแกนเฉพาะ `Strategies/*/v*`
4. ตั้งชื่อเอกสารขึ้นต้นด้วย BLUEPRINT_, CURRENT_STATE_, SPEC_ หรือ TEST_MATRIX_ เพื่อให้ make_ai_bundle รวมเข้าชุดไฟล์ของกลยุทธ์ให้อัตโนมัติ
5. ไฟล์ที่ชื่อมีคำว่า Secrets (กุญแจและ URL ตรวจสิทธิ์) ไม่เข้า Git และ make_ai_bundle ข้ามเสมอ
6. Hedge ย้ายเข้าโครงนี้แล้ว (18 พ.ย. 2026) ส่วน Pending ยังใช้ `docs/work/` ตามเดิม make_ai_bundle ถอยไปหา `docs/work/CURRENT_STATE_<ชื่อ>.md` ถ้าไม่มีในโฟลเดอร์ doc ย้ายเมื่อต้องการเป็นงานแยก
7. กลยุทธ์ใหม่ใช้โครงนี้ตั้งแต่ต้น

## 2. เหตุผล
- `docs/work/` และ `tools/` เคยปนไฟล์ของทุกกลยุทธ์ ทำให้ไม่รู้ว่ากลยุทธ์ไหนต้องดูไฟล์ไหน
- เครื่องมือกลางต้องคงที่ราก เพราะ sync_core คัดลอก Core ไปทุกสำเนา และ verify_core ตรวจ Magic ไม่ซ้ำข้ามกลยุทธ์จากทะเบียนเดียว การแยกเป็นหลายชุดทำให้สำเนาเพี้ยนและไม่มีใครเห็นภาพรวม

## 3. สิ่งที่เปลี่ยนในเครื่องมือ
- `tools/check_docs.py`: ตรวจเอกสารใน `Strategies/*/doc/*.md` เหมือนไฟล์ใน `docs/work/` และรู้จักหัวข้อ "งาน TradeDesk" ใน AI_READ_SCOPE.md
- `tools/make_ai_bundle.py`: อ่านเอกสารกลยุทธ์จาก doc/ (ถอยไป docs/work/ ถ้าไม่มี) และข้ามไฟล์ที่ชื่อมี Secrets
- `.gitignore`: ไฟล์สถานะของเซิร์ฟเวอร์จำลองย้ายไปตามโฟลเดอร์ tools ของ TradeDesk

## 4. ที่ยังไม่ทำ
- ย้าย Pending เข้าโครงนี้ (Hedge ย้ายแล้ว 18 พ.ย. 2026)
- ปรับหัวข้อโครงสร้างในแม่แบบ HANDOFF_NEW_STRATEGY_TEMPLATE_v2 ให้ตรงกับมตินี้
