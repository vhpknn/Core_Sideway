//+------------------------------------------------------------------+
//|                                            RangeBot_Strategy.mqh |
//|  โครงเปล่าของกลยุทธ์: ฟังก์ชัน Strategy_* ตามสัญญา Core_StrategyAPI |
//|  ไม่มีตรรกะเทรด Strategy_OnTick แค่แสดงสถานะ NO_STRATEGY           |
//|  ต้อง include หลัง Core ทั้งหมด และ CoreUI_Theme.mqh               |
//|  ตัวอย่างตรรกะจริงดู reference/Hedge_example/include/Hedge_Strategy.mqh |
//+------------------------------------------------------------------+
#ifndef RANGEBOT_STRATEGY_MQH
#define RANGEBOT_STRATEGY_MQH

string Strategy_Title()
  {
   return("RangeBot 1.0");
  }

string Strategy_Version()
  {
   return("0.0.0");
  }

ENUM_ACCT_SUPPORT Strategy_AccountSupport()
  {
   return(ACCT_ANY);
  }

bool Strategy_Init()
  {
   return(true);
  }

//--- เรียกทุก Tick (หลัง Protect ทำงานเสร็จ) ใส่ตรรกะเข้าออเดอร์ที่นี่
//--- ทุกทางเปิดใหม่ต้องเคารพ CoreIsPaused() และเรียก BeginBasketCycle() ก่อนเปิดรอบ
void Strategy_OnTick()
  {
   g_gateReason = "NO_STRATEGY";
  }

void Strategy_CloseAll(string tag)
  {
   CloseOneSide(POSITION_TYPE_BUY,  tag);
   CloseOneSide(POSITION_TYPE_SELL, tag);
  }

//--- ปุ่มของกลยุทธ์ไม่เกิน 3 ปุ่ม (ตอนนี้ไม่มี)
int Strategy_ButtonCount()
  {
   return(0);
  }

bool Strategy_ButtonDef(int index, SStrategyButton &def)
  {
   return(false);
  }

void Strategy_OnButton(string id)
  {
  }

string Strategy_GateText()
  {
   return(GetEngineGateText());
  }

#endif // RANGEBOT_STRATEGY_MQH