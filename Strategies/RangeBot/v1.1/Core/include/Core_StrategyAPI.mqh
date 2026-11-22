//+------------------------------------------------------------------+
//|                                              Core_StrategyAPI.mqh|
//|  สัญญากลางระหว่าง Core กับกลยุทธ์ ("ช่องเสียบตลับ")               |
//|  EA หลักต้อง #define ก่อน include Core:                           |
//|    STRATEGY_TAG, STRATEGY_EA_ORDINAL, STRATEGY_MAGIC_NEXT        |
//|    (STRATEGY_MAGIC_BASE และ STRATEGY_DEFAULT_COMMENT อยู่ใน Inputs)|
//|  ไฟล์กลยุทธ์ต้องเขียนฟังก์ชัน Strategy_* ทุกตัวด้านล่าง            |
//|  ถ้าขาดตัวใดตัวหนึ่ง คอมไพล์ต้องไม่ผ่าน                           |
//|  สงวนชื่อ (ยังไม่ประกาศใน v1.0): Strategy_OnPause,               |
//|    Strategy_GetPositionRisk, Strategy_BasketCount (v1.1)         |
//+------------------------------------------------------------------+
#ifndef CORE_STRATEGYAPI_MQH
#define CORE_STRATEGYAPI_MQH

#include "Core_Inputs.mqh"

#ifndef STRATEGY_EA_ORDINAL
   #error "Core_StrategyAPI: ต้อง #define STRATEGY_EA_ORDINAL ก่อน include (ลำดับ EA ใน MAGIC_REGISTRY)"
#endif

#ifndef STRATEGY_MAGIC_NEXT
   #error "Core_StrategyAPI: ต้อง #define STRATEGY_MAGIC_NEXT ก่อน include (Magic ถัดไปที่แนะนำ)"
#endif

//--- ชนิดบัญชีที่กลยุทธ์รองรับ (มติ D-02)
enum ENUM_ACCT_SUPPORT
  {
   ACCT_HEDGING_ONLY = 0,
   ACCT_NETTING_ONLY = 1,
   ACCT_ANY          = 2
  };

//--- ข้อมูลปุ่มของกลยุทธ์บน Panel (Core วางตามช่องปุ่มของกลยุทธ์)
struct SStrategyButton
  {
   string id;        // รหัสปุ่ม (ไม่ซ้ำ ไม่ต้องมี Prefix)
   string text;      // ข้อความบนปุ่ม
   color  bg;        // สีพื้นปุ่ม
   color  border;    // สีขอบปุ่ม
   color  textColor; // สีตัวอักษร (CLR_NONE = ขาว ตามค่าเริ่มต้น)
   string tooltip;   // คำอธิบายเมื่อชี้เมาส์
  };

//--- ข้อความหัว Panel เช่น "Hedge 1.0"
string            Strategy_Title();

//--- เวอร์ชันของกลยุทธ์/EA แบบ MAJOR.MINOR.PATCH เช่น "1.0.0"
string            Strategy_Version();

//--- ชนิดบัญชีที่รองรับ
ENUM_ACCT_SUPPORT Strategy_AccountSupport();

//--- เตรียมกลยุทธ์ตอน OnInit (ตรวจ Input ของกลยุทธ์) คืน false = โหลดไม่ผ่าน
bool              Strategy_Init();

//--- ตัดสินใจเข้าออเดอร์ (Core ทำ Protect และ Report ไปก่อนแล้ว)
void              Strategy_OnTick();

//--- ปิด Position ทั้งหมดของกลยุทธ์ (และออเดอร์ค้างถ้ามี) ปุ่ม CLOSE ALL เรียกฟังก์ชันนี้
void              Strategy_CloseAll(string tag);

//--- ปุ่มของกลยุทธ์บน Panel (Core รองรับสูงสุด 3 ปุ่ม)
int               Strategy_ButtonCount();
bool              Strategy_ButtonDef(int index, SStrategyButton &def);
void              Strategy_OnButton(string id);

//--- เหตุผลที่ยังไม่เข้าออเดอร์ (แสดงบน Panel)
string            Strategy_GateText();

#endif // CORE_STRATEGYAPI_MQH