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
   return("1.0.0");
  }

ENUM_ACCT_SUPPORT Strategy_AccountSupport()
  {
   if(InpRbAccountMode == RB_ACCT_HEDGING)
      return(ACCT_HEDGING_ONLY);

   if(InpRbAccountMode == RB_ACCT_NETTING)
      return(ACCT_NETTING_ONLY);

   return(ACCT_ANY);
  }

//--- RangeBot จัดการ SL/TP/BE เอง: Protect ของ Core ต้องถูกปิด (ข้อ 2.2 ใน BLUEPRINT)
//--- Cut Loss ปิดไม่ได้ ต้องตั้ง InpCutLossPoints ให้กว้างกว่า SL ตาม ATR (ตรวจในชุดหลัง)
bool RbProtectNeutralized()
  {
   bool ok = true;

   if(InpRRPercent > 0.0)
     {
      Alert(CORE_LOG_PREFIX, " ต้องตั้ง InpRRPercent = 0 (ปิด RR ของ Core)");
      ok = false;
     }

   if(InpUseTrailingTP)
     {
      Alert(CORE_LOG_PREFIX, " ต้องตั้ง InpUseTrailingTP = false (ปิด Trailing TP ของ Core)");
      ok = false;
     }

   if(InpBreakEvenMode != BE_OFF)
     {
      Alert(CORE_LOG_PREFIX, " ต้องตั้ง InpBreakEvenMode = BE_OFF (ปิด Break-even ของ Core)");
      ok = false;
     }

   return(ok);
  }

bool Strategy_Init()
  {
   if(!RbProtectNeutralized())
      return(false);

   Print(CORE_LOG_PREFIX, " Protect ของ Core ถูกปิดตามที่ RangeBot ต้องการ",
         " | CutLoss=", InpCutLossPoints, " pts",
         " | AccountMode=", EnumToString(InpRbAccountMode));

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

//--- ปุ่มของกลยุทธ์ 2 ปุ่ม: RESET RANGE และ BE NOW (ชุด 1 ยังเป็นโครง ยังไม่ทำงานจริง)
int Strategy_ButtonCount()
  {
   return(2);
  }

bool Strategy_ButtonDef(int index, SStrategyButton &def)
  {
   if(index == 0)
     {
      def.id        = "RANGE_RESET";
      def.text      = "RESET RANGE";
      def.bg        = CUI_BTN_REFILL;
      def.border    = CUI_BORDER;
      def.tooltip   = "Unlock the saved range and detect a new one. Does not close trades and does not touch capital (different from the Core RESET button).";
      def.textColor = CLR_NONE;
      return(true);
     }

   if(index == 1)
     {
      def.id        = "BE_NOW";
      def.text      = "BE NOW";
      def.bg        = CUI_BTN_HEDGE;
      def.border    = CUI_FRAME_HEDGE;
      def.tooltip   = "Move SL of the open trade to break-even (only if it improves the current SL).";
      def.textColor = CLR_NONE;
      return(true);
     }

   return(false);
  }

//--- ชุด 1: แค่บันทึก Log ว่ากดแล้ว ตรรกะจริงทำในชุด 4
void Strategy_OnButton(string id)
  {
   if(id == "RANGE_RESET")
      Print(CORE_LOG_PREFIX, " ปุ่ม RESET RANGE ถูกกด (ยังไม่ทำงานจริงในชุด 1)");
   else if(id == "BE_NOW")
      Print(CORE_LOG_PREFIX, " ปุ่ม BE NOW ถูกกด (ยังไม่ทำงานจริงในชุด 1)");
  }

string Strategy_GateText()
  {
   return(GetEngineGateText());
  }

#endif // RANGEBOT_STRATEGY_MQH