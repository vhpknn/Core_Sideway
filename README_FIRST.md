# New_Strategies: แม่แบบเริ่มกลยุทธ์ใหม่ (EA Platform Core)

แม่แบบคงที่สำหรับเริ่มกลยุทธ์ใหม่หนึ่งตัวต่อหนึ่ง Repo ส่งทั้งโฟลเดอร์ให้ AI แล้วทำงานได้เลย โดย AI เห็นเฉพาะกลยุทธ์นี้ ไม่ปนกับกลยุทธ์อื่น

ฐาน Core ที่ปักไว้ดูที่ `TEMPLATE_VERSION` และ `Core/` (ห้ามแก้ไฟล์ใน `Core/` และสำเนาใต้กลยุทธ์ ให้ใช้ `tools/update_core.py` เมื่อต้องการ Core ใหม่)

## 4 เฟส

### เฟส 1: ปรึกษาและสรุปสเปก (ยังไม่มี Repo)
1. unzip `New_Strategies.zip` แล้วส่งข้อมูลให้ AI: ถ้า AI เข้า GitHub ไม่ได้ ให้รัน `python tools/make_ai_bundle.py --job consult` แล้วแนบไฟล์ผลลัพธ์ในโฟลเดอร์ `ai_bundle/`
2. ใช้ข้อความเริ่มต้นแบบ "ปรึกษา" ใน `docs/AI_START_PROMPT.md`
3. ปรึกษาจนกรอก `docs/SPEC_FORM.md` ครบ แล้วให้ AI สรุปลง `docs/BLUEPRINT.md` บันทึกทุกรอบ (ถ้ากลัวไฟล์หาย รัน `git init` ในโฟลเดอร์นี้ได้เลย ยังไม่ต้องมี remote)

### เฟส 2: ตั้งชื่อและสร้าง Repo
4. รัน `python tools/init_strategy.py` ใส่ชื่อกลยุทธ์ TAG 3 ตัวอักษร และลำดับ EA (Magic ฐาน = ลำดับ x 10000) สคริปต์สแกนโฟลเดอร์ข้างเคียงและเตือนทันทีถ้า TAG หรือ Magic ซ้ำ
5. เปลี่ยนชื่อโฟลเดอร์เป็น `EA_<ชื่อ>` (เช่น `EA_SMC`) `git init` Commit แรก สร้าง Repo Private บน GitHub แล้ว push

### เฟส 3: สร้างและทดสอบ
6. ใช้ข้อความเริ่มต้นแบบ "สร้าง/แก้กลยุทธ์" ใน `docs/AI_START_PROMPT.md` AI ส่งแผน (Folder Tree) ก่อน รอคำว่า "เริ่มงาน" แล้วจึงเขียนโค้ด (ไฟล์ใหม่ Full Code ไฟล์เดิม FIND/REPLACE)
7. คอมไพล์ EA 3 ตัว (ต้อง 0 errors 0 warnings) รัน `tools\run_checks.bat` ทดสอบ Demo บันทึกผลใน `docs/work/TEST_MATRIX.md` และ `docs/work/LOG.md`
8. ผู้ใช้ Commit / push / ติด tag เอง (AI ไม่แตะ GitHub)

### เฟส 4: อัปเดต Core เมื่อ Core หลักเปลี่ยน
9. `python tools/update_core.py --platform <โฟลเดอร์ EA_Platform_Core ที่ checkout ตาม tag> --version v1.0.2` (ดูผลก่อน ใส่ `--apply` เมื่อพร้อม) ได้โฟลเดอร์กลยุทธ์รุ่นใหม่ข้างของเดิม พร้อมเอกสารตรวจสอบ API ที่ `docs/work/`
10. ทำตามรายการใน `docs/work/CORE_UPDATE_<เดิม>_to_<ใหม่>.md` คอมไพล์ ทดสอบ แล้วจึง Commit และติด tag

## ไฟล์สำคัญ
| ไฟล์ | หน้าที่ |
|---|---|
| `docs/START_HERE.md` | ลำดับอ่านและแผนที่โฟลเดอร์ |
| `docs/RULES.md` | กติกากลาง (Core, Magic, เลขรุ่น/tag, วิธีทำงานกับ AI) |
| `docs/AI_READ_SCOPE.md` | ขอบเขตไฟล์ที่ AI อ่านได้ในแต่ละเฟส |
| `docs/AI_START_PROMPT.md` | ข้อความเริ่มต้นสำหรับแชต AI |
| `docs/SPEC_FORM.md` และ `docs/BLUEPRINT.md` | ฟอร์มสเปกและผลสรุปการปรึกษา |
| `tools/` | init_strategy, update_core, sync_core, verify_core, check_docs, run_checks, make_ai_bundle |
