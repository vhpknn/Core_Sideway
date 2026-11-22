# ข้อความเริ่มต้นสำหรับแชต AI

เลือกข้อความตามเฟส แล้วแนบไฟล์ตาม `docs/AI_READ_SCOPE.md` (หรือไฟล์จาก `tools/make_ai_bundle.py --job ...` ถ้า AI เข้า GitHub ไม่ได้) ข้อความใน Repo ที่ push แล้วใช้ชื่อ Repo ได้เลย

## 1. ปรึกษาและสรุปสเปก (เฟส 1)
```text
อ่าน docs/START_HERE.md, docs/RULES.md และ docs/AI_READ_SCOPE.md ก่อน ทำ "งาน A: ปรึกษา" กลยุทธ์ใหม่ อ่านเฉพาะไฟล์ในรายการของงาน A ห้ามเดาสเปก ถามเฉพาะจุดที่ขาดตาม docs/SPEC_FORM.md สรุปผลลง docs/BLUEPRINT.md ห้ามเริ่มโค้ดและห้ามแก้ Core ก่อนผมพิมพ์คำว่า "เริ่มงาน" ก่อนตอบสรุป ให้แจ้งรายชื่อไฟล์ที่คุณเปิดอ่านจริงทั้งหมด
```

## 2. สร้างและแก้กลยุทธ์ (เฟส 3)
```text
อ่าน docs/START_HERE.md, docs/RULES.md, docs/AI_READ_SCOPE.md, docs/work/CURRENT_STATE.md และ docs/BLUEPRINT.md ทำ "งาน B: สร้างและแก้กลยุทธ์" ตรวจ Commit และไฟล์ที่ระบุว่าแก้แล้วกับ Repo จริงก่อน แจ้งถ้าไม่ตรง สรุปความเข้าใจและส่ง Folder Tree พร้อมหน้าที่ต่อไฟล์ รอคำว่า "เริ่มงาน" ไฟล์ใหม่ส่ง Full Code ไฟล์เดิมส่ง Jigsaw Patch ห้ามแก้ Core และสำเนา Core ห้าม Commit เอง ก่อนตอบสรุป ให้แจ้งรายชื่อไฟล์ที่คุณเปิดอ่านจริงทั้งหมด
```

## 3. อัปเดต Core เข้ากลยุทธ์ (เฟส 4)
```text
อ่าน docs/START_HERE.md, docs/RULES.md, docs/AI_READ_SCOPE.md และไฟล์ docs/work/CORE_UPDATE_*.md ล่าสุด ทำ "งาน C: อัปเดต Core" ตรวจผลต่าง API ที่ update_core.py สร้างไว้ ระบุผลกระทบต่อโค้ดกลยุทธ์ในโฟลเดอร์รุ่นใหม่ ส่งแผนแก้ก่อน รอคำว่า "เริ่มงาน" ห้ามแก้สำเนา Core ถ้าต้องแก้ Core ให้หยุดและแจ้งว่าเป็นงาน Core ที่ Repo EA_Platform_Core
```
