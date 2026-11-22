# D-18: การตั้งชื่อไฟล์ .mqh ของกลยุทธ์ (2026-10-26, ผู้ใช้สั่ง)

ต่อจาก D-17 (ไฟล์ Core ใช้ชื่อ Core_*.mqh ใน Core/v1.0.0/include/)

## กติกา
- ไฟล์ .mqh ที่เป็นของกลยุทธ์ใช้รูปแบบ <ชื่อกลยุทธ์>_<โมดูล>.mqh อยู่ใน Strategies/<ชื่อกลยุทธ์>/v<เวอร์ชัน>/include/
- ชื่อกลยุทธ์ตรงกับชื่อโฟลเดอร์ของกลยุทธ์ (Hedge, Pending, SMC ฯลฯ) ไม่ใช้ TAG 3 ตัวอักษรเป็นชื่อไฟล์
- Include Guard ใช้ชื่อกลยุทธ์ เช่น HEDGE_PANEL_MQH, PENDING_PANEL_MQH ต้องไม่ซ้ำกับ CORE_*_MQH
- ชื่อฟังก์ชันที่ Core กำหนดใน Core_StrategyAPI (Strategy_Init, Strategy_OnTick ฯลฯ) ไม่เปลี่ยนตามชื่อกลยุทธ์ เป็นสัญญากลาง

## ตัวอย่าง
| ไฟล์ | หน้าที่ |
|---|---|
| Strategies/Hedge/v1.0.0/include/Hedge_Strategy.mqh | ตรรกะกลยุทธ์ Hedge (OpenHedgePair, EngineOnTick เดิม ฯลฯ) และฟังก์ชัน Strategy_* |
| Strategies/Hedge/v1.0.0/include/Hedge_Inputs.mqh | Input เฉพาะกลยุทธ์ Hedge |
| Strategies/Hedge/v1.0.0/include/Hedge_Panel.mqh | สำเนา Panel เฉพาะกลยุทธ์ (ใช้เมื่อ Hook ไม่พอ) |
| Strategies/Pending/v1.0.0/include/Pending_Panel.mqh | สำเนา Panel เฉพาะ Pending |
| Strategies/SMC/v1.0.0/include/SMC_Panel.mqh | สำเนา Panel เฉพาะ SMC |

## ผลต่อเอกสารเดิม
- Blueprint v4 ข้อ 9 เขียน Strategy/Strategy_Hedge.mqh ให้ถือเป็น include/Hedge_Strategy.mqh
- ไฟล์ EA หลักของแต่ละกลยุทธ์ (.mq5) ตั้งชื่อ <ชื่อกลยุทธ์>_EA.mq5 เป็นต้นฉบับโค้ด และมีไฟล์เปลือกภาษา <ชื่อกลยุทธ์>_EA_EN.mq5 (ทดสอบ) กับ <ชื่อกลยุทธ์>_EA_TH.mq5 (เทรดจริง) ดู D-26.1
- SMC ยังไม่มีในตาราง MAGIC_REGISTRY.md ลำดับ EA และ TAG กำหนดเมื่อสร้าง EA จริง
