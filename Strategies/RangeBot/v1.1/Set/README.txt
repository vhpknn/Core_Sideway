โฟลเดอร์ Set: เก็บไฟล์ชุดค่า .set ของกลยุทธ์นี้ ชุด 00 ถึง 10 (Ablation) สร้างด้วย tools\make_rangebot_sets.py (Magic 40001 ถึง 40011) แก้ที่สคริปต์แล้วสร้างใหม่ ไม่แก้ไฟล์ด้วยมือ

กติกา (ตรวจโดย tools/verify_core.py)
- InpTradeComment ขึ้นต้นด้วย <TAG><Magic> เช่น SMC30001 ... ไม่เกิน 25 ตัวอักษร
- InpMagicNumber อยู่ในช่วง Magic ฐาน ถึง ฐาน+9999 (ค่าฐานอยู่ใน STRATEGY_IDENTITY.txt)
- Magic ในแต่ละไฟล์ไม่ซ้ำกัน และ Magic ที่ใช้แล้วห้ามนำกลับมาใช้
- ค่าที่ใช้ทดสอบ (Magic ทดลอง, Timeout สั้น) ห้ามเก็บเป็นไฟล์ .set ใน Repo