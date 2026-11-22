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

//--- ตรวจค่า Input ของชุด 2 (Regime + Range)
bool RbValidateInputs()
  {
   bool ok = true;

   if(InpRbAtrPeriod < 1 || InpRbAdxPeriod < 1 || InpRbBbPeriod < 2 || InpRbBbwAvgPeriod < 1)
     {
      Alert(CORE_LOG_PREFIX, " ช่วง ATR/ADX/BB/BBW ต้องมากกว่า 0 (BB ตั้งแต่ 2)");
      ok = false;
     }

   if(InpRbBbDev <= 0.0 || InpRbSqueezeFactor <= 0.0)
     {
      Alert(CORE_LOG_PREFIX, " BbDev และ SqueezeFactor ต้องมากกว่า 0");
      ok = false;
     }

   if(InpRbAdxRisingBars < 0 || InpRbRegimeConfirmBars < 1)
     {
      Alert(CORE_LOG_PREFIX, " AdxRisingBars ต้องไม่ติดลบ และ RegimeConfirmBars ต้องอย่างน้อย 1");
      ok = false;
     }

   if(InpRbAdxRangeMax <= 0.0 || InpRbAdxRangeMax >= InpRbAdxTrendMin)
     {
      Alert(CORE_LOG_PREFIX, " ต้องมี 0 < AdxRangeMax < AdxTrendMin");
      ok = false;
     }

   if(InpRbEmaFast < 1 || InpRbEmaFast >= InpRbEmaMid || InpRbEmaMid >= InpRbEmaSlow)
     {
      Alert(CORE_LOG_PREFIX, " ต้องมี EmaFast < EmaMid < EmaSlow และ EmaFast >= 1");
      ok = false;
     }

   if(InpRbRangeLookback < 5 || InpRbRangeExcludeBars < 0)
     {
      Alert(CORE_LOG_PREFIX, " RangeLookback ต้องอย่างน้อย 5 และ ExcludeBars ต้องไม่ติดลบ");
      ok = false;
     }

   if(InpRbRangeMinHeightAtr <= 0.0 || InpRbRangeMinHeightAtr >= InpRbRangeMaxHeightAtr)
     {
      Alert(CORE_LOG_PREFIX, " ต้องมี 0 < RangeMinHeightAtr < RangeMaxHeightAtr");
      ok = false;
     }

   if(InpRbRangeMinTouches < 1 || InpRbRangeMinTouches > InpRbRangeLookback
      || InpRbRangeTouchTolAtr < 0.0)
     {
      Alert(CORE_LOG_PREFIX, " RangeMinTouches ต้องอยู่ระหว่าง 1 ถึง Lookback และ TouchTolAtr ต้องไม่ติดลบ");
      ok = false;
     }

   return(ok);
  }

datetime g_rbLastBar = 0;   // เวลาเปิดของแท่ง EntryTF ที่ประมวลผลล่าสุด

void RbOnDeinit()
  {
   RbRegimeDeinit();
   RbRangeDeinit();
  }

//--- Log สรุปหนึ่งบรรทัดต่อแท่งใหม่
void RbLogBar()
  {
   if(!InpRbLogBar)
      return;

   string box = "NOBOX(" + g_rbRange.reason + ")";

   if(g_rbRange.valid && g_rbRange.atr > 0.0)
      box = "BOX " + DoubleToString(g_rbRange.low, _Digits)
            + "-" + DoubleToString(g_rbRange.high, _Digits)
            + " H/ATR=" + DoubleToString(g_rbRange.height / g_rbRange.atr, 2)
            + " T=" + IntegerToString(g_rbRange.touchHigh)
            + "/" + IntegerToString(g_rbRange.touchLow)
            + (g_rbRange.locked ? " LOCKED" : "");

   Print(CORE_LOG_PREFIX, " BAR ", TimeToString(g_rbLastBar, TIME_DATE | TIME_MINUTES),
         " | ", RbRegimeText(g_rbRegime), " (raw ", RbRegimeText(g_rbRegimeRaw), ")",
         " | ADX=", DoubleToString(g_rbAdx, 1),
         " BBWr=", DoubleToString(g_rbBbwRatio, 2),
         " | ATR=", DoubleToString(g_rbRange.atr, _Digits),
         " | ", box);
  }

//--- ชุด 2: อัปเดต Regime + Range เมื่อเกิดแท่งใหม่ ยังไม่มีการเปิดไม้
void RbOnTick()
  {
   datetime bar = iTime(_Symbol, InpRbEntryTF, 0);

   if(bar > 0 && (bar != g_rbLastBar || g_rbForceUpdate))
     {
      if(RbRegimeUpdate() && RbRangeUpdate(g_rbRegime))
        {
         g_rbLastBar     = bar;
         g_rbForceUpdate = false;
         RbDrawRange();
         RbLogBar();
        }
      else
        {
         static datetime lastWarn = 0;

         if(TimeLocal() - lastWarn >= 30)
           {
            lastWarn = TimeLocal();
            Print(CORE_LOG_PREFIX, " รอข้อมูล Indicator/ราคา (จะลองใหม่ทุก Tick)");
           }
        }
     }

   g_gateReason = RbRegimeText(g_rbRegime) + (g_rbRange.valid ? " BOX" : " NOBOX");
  }

bool Strategy_Init()
  {
   if(!RbProtectNeutralized())
      return(false);

   if(!RbValidateInputs())
      return(false);

   if(!RbRegimeInit() || !RbRangeInit())
      return(false);

   g_rbLastBar     = 0;
   g_rbForceUpdate = false;

   Print(CORE_LOG_PREFIX, " Protect ของ Core ถูกปิดตามที่ RangeBot ต้องการ",
         " | CutLoss=", InpCutLossPoints, " pts",
         " | AccountMode=", EnumToString(InpRbAccountMode),
         " | EntryTF=", EnumToString(InpRbEntryTF));

   return(true);
  }

//--- เรียกทุก Tick (หลัง Protect ทำงานเสร็จ) ใส่ตรรกะเข้าออเดอร์ที่นี่
//--- ทุกทางเปิดใหม่ต้องเคารพ CoreIsPaused() และเรียก BeginBasketCycle() ก่อนเปิดรอบ
void Strategy_OnTick()
  {
   RbOnTick();
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
      RbRangeResetRequest();
   else if(id == "BE_NOW")
      Print(CORE_LOG_PREFIX, " ปุ่ม BE NOW ถูกกด (ยังไม่ทำงานจริงในชุด 1)");
  }

string Strategy_GateText()
  {
   return(GetEngineGateText());
  }

#endif // RANGEBOT_STRATEGY_MQH