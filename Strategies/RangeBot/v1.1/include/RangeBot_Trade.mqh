//+------------------------------------------------------------------+
//|                                                RangeBot_Trade.mqh |
//|  จัดการไม้: TP1->BE, Mid-range BE, Hand-off + Chandelier, Timeout, |
//|  MaxHold, TrendShift, ปุ่ม BE NOW + เก็บ/กู้สถานะด้วย GV          |
//|  ต้อง include หลัง RangeBot_Manager.mqh                           |
//+------------------------------------------------------------------+
#ifndef RANGEBOT_TRADE_MQH
#define RANGEBOT_TRADE_MQH

#define RB_ST_PRE_TP1    1
#define RB_ST_POST_TP1   2
#define RB_ST_HANDED_OFF 3
#define RB_GV_COUNT      16

int g_rbChAtrH = INVALID_HANDLE;   // ATR(ChandelierPeriod) สำหรับ Trailing

//--- ลำดับเดียวกับ RbPlanPersist / RbManagerRestore
string g_rbGvNames[RB_GV_COUNT] =
  {
   "RBTK", "RBDR", "RBST", "RBEN", "RBAT", "RBRH", "RBRL", "RBT1",
   "RBT2", "RBTP", "RBSL", "RBAP", "RBBH", "RBBT", "RBMD", "RBTD"
  };

bool RbValidateTradeInputs()
  {
   bool ok = true;

   if(InpRbSignalWaitMinutes < 0)
     { Alert(CORE_LOG_PREFIX, " SignalWaitMinutes ต้องไม่ติดลบ (0 = รอจนจบแท่ง)"); ok = false; }

   if(InpRbBeBufferAtr < 0.0 || InpRbHandOffBreakAtr < 0.0 || InpRbTrailStepAtr < 0.0)
     { Alert(CORE_LOG_PREFIX, " BeBufferAtr/HandOffBreakAtr/TrailStepAtr ต้องไม่ติดลบ"); ok = false; }

   if(InpRbChandelierPeriod < 2 || InpRbChandelierMult <= 0.0)
     { Alert(CORE_LOG_PREFIX, " ChandelierPeriod ต้อง >= 2 และ ChandelierMult ต้อง > 0"); ok = false; }

   if(InpRbRangeTimeoutBars < 1 || InpRbMaxHoldBars < 1)
     { Alert(CORE_LOG_PREFIX, " RangeTimeoutBars และ MaxHoldBars ต้อง >= 1"); ok = false; }

   if(InpRbUseHandOff && !InpRbUseTp2)
      Print(CORE_LOG_PREFIX, " หมายเหตุ: Hand-off ใช้ไม่ได้เมื่อปิด InpRbUseTp2 (โบรกปิดไม้ที่ TP1)");

   return(ok);
  }

bool RbTradeInit()
  {
   g_rbChAtrH = iATR(_Symbol, InpRbEntryTF, InpRbChandelierPeriod);

   if(g_rbChAtrH == INVALID_HANDLE)
     {
      Alert(CORE_LOG_PREFIX, " สร้าง ATR ของ Chandelier ไม่สำเร็จ | error=", GetLastError());
      return(false);
     }

   return(true);
  }

void RbTradeDeinit()
  {
   RbReleaseHandle(g_rbChAtrH);
  }

//+------------------------------------------------------------------+
//| เก็บ / กู้ / ล้างสถานะ (Global Variable) ไม่ทำงานใน Strategy Tester |
//+------------------------------------------------------------------+
void RbGvClear()
  {
   if((bool)MQLInfoInteger(MQL_TESTER))
      return;

   for(int i = 0; i < RB_GV_COUNT; i++)
     {
      string name = CoreStateGVName(g_rbGvNames[i]);

      if(GlobalVariableCheck(name))
         GlobalVariableDel(name);
     }

   GlobalVariablesFlush();
  }

void RbPlanPersist()
  {
   if((bool)MQLInfoInteger(MQL_TESTER) || !g_rbPlan.active)
      return;

   double v[RB_GV_COUNT];
   v[0]  = (double)g_rbPlan.ticket;
   v[1]  = (g_rbPlan.dir == POSITION_TYPE_BUY) ? 1.0 : -1.0;
   v[2]  = (double)g_rbPlan.state;
   v[3]  = g_rbPlan.entry;
   v[4]  = g_rbPlan.atr;
   v[5]  = g_rbPlan.rHigh;
   v[6]  = g_rbPlan.rLow;
   v[7]  = g_rbPlan.tp1;
   v[8]  = g_rbPlan.tp2;
   v[9]  = g_rbPlan.tpBroker;
   v[10] = g_rbPlan.sl;
   v[11] = g_rbPlan.applied ? 1.0 : 0.0;
   v[12] = (double)g_rbPlan.barsHeld;
   v[13] = (double)g_rbPlan.barsSinceTp1;
   v[14] = g_rbPlan.midDone ? 1.0 : 0.0;
   v[15] = g_rbPlan.trendDone ? 1.0 : 0.0;

   for(int i = 0; i < RB_GV_COUNT; i++)
     {
      string name = CoreStateGVName(g_rbGvNames[i]);

      if(StringLen(name) > 63)
        {
         Print(CORE_LOG_PREFIX, " STATE บันทึกไม่ได้ | Key ยาวเกิน 63 ตัวอักษร");
         return;
        }

      ResetLastError();

      if(GlobalVariableSet(name, v[i]) == 0)
        {
         Print(CORE_LOG_PREFIX, " STATE บันทึกไม่สำเร็จ | ", g_rbGvNames[i],
               " | error=", GetLastError());
         return;
        }
     }

   GlobalVariablesFlush();
  }

//--- กู้สถานะตอนเริ่มระบบ (เรียกหลัง RbManagerReset)
void RbManagerRestore()
  {
   if((bool)MQLInfoInteger(MQL_TESTER))
      return;

   if(!GlobalVariableCheck(CoreStateGVName("RBTK")))
     {
      if(CoreBasketPositions() > 0)
         Print(CORE_LOG_PREFIX, " WARN | พบไม้ของ Magic นี้แต่ไม่มีสถานะที่บันทึกไว้",
               " -> RangeBot จะไม่จัดการไม้นี้ (SL/TP ของโบรกยังทำงาน)");
      return;
     }

   double v[RB_GV_COUNT];

   for(int i = 0; i < RB_GV_COUNT; i++)
     {
      string name = CoreStateGVName(g_rbGvNames[i]);

      if(!GlobalVariableCheck(name)
         || !GlobalVariableGet(name, v[i])
         || !MathIsValidNumber(v[i]))
        {
         Print(CORE_LOG_PREFIX, " STATE เสียหายหรือไม่ครบ (", g_rbGvNames[i], ") -> ไม่กู้ และล้างสถานะ");
         RbGvClear();
         return;
        }
     }

   ulong ticket = (ulong)v[0];

   if(!PositionSelectByTicket(ticket)
      || PositionGetString(POSITION_SYMBOL) != _Symbol
      || PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
     {
      Print(CORE_LOG_PREFIX, " STATE เก่า: ไม่พบไม้ #", ticket, " -> ล้างสถานะ");
      RbGvClear();
      return;
     }

   int st = (int)v[2];

   if(st < RB_ST_PRE_TP1 || st > RB_ST_HANDED_OFF)
      st = RB_ST_PRE_TP1;

   g_rbPlan.active       = true;
   g_rbPlan.ticket       = ticket;
   g_rbPlan.dir          = (v[1] > 0.0) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   g_rbPlan.state        = st;
   g_rbPlan.entry        = v[3];
   g_rbPlan.atr          = v[4];
   g_rbPlan.rHigh        = v[5];
   g_rbPlan.rLow         = v[6];
   g_rbPlan.tp1          = v[7];
   g_rbPlan.tp2          = v[8];
   g_rbPlan.tpBroker     = v[9];
   g_rbPlan.sl           = v[10];
   g_rbPlan.applied      = (v[11] > 0.5);
   g_rbPlan.barsHeld     = (int)v[12];
   g_rbPlan.barsSinceTp1 = (int)v[13];
   g_rbPlan.midDone      = (v[14] > 0.5);
   g_rbPlan.trendDone    = (v[15] > 0.5);
   g_rbPlan.tries        = 0;

   Print(CORE_LOG_PREFIX, " STATE RESTORED #", ticket,
         " | ", (g_rbPlan.dir == POSITION_TYPE_BUY ? "BUY" : "SELL"),
         " | State=", st,
         " | BarsHeld=", g_rbPlan.barsHeld,
         " BarsSinceTP1=", g_rbPlan.barsSinceTp1,
         " | SL=", DoubleToString(g_rbPlan.sl, _Digits),
         " TP=", DoubleToString(g_rbPlan.tpBroker, _Digits));
  }

//--- เรียกจาก Manager ตอนเปิดไม้สำเร็จ
void RbPlanOnOpened()
  {
   g_rbPlan.state        = RB_ST_PRE_TP1;
   g_rbPlan.barsHeld     = 0;
   g_rbPlan.barsSinceTp1 = 0;
   g_rbPlan.midDone      = false;
   g_rbPlan.trendDone    = false;
   RbPlanPersist();
  }

//--- เรียกจาก Manager เมื่อพบว่าไม้ปิดไปแล้ว
void RbPlanOnClosed()
  {
   Print(CORE_LOG_PREFIX, " TRADE CLOSED #", g_rbPlan.ticket,
         " | State=", g_rbPlan.state,
         " | BarsHeld=", g_rbPlan.barsHeld,
         " BarsSinceTP1=", g_rbPlan.barsSinceTp1);

   g_rbPlan.active = false;
   RbGvClear();
  }

string RbStateTag()
  {
   if(!g_rbPlan.active)
      return("");

   if(g_rbPlan.state == RB_ST_HANDED_OFF)
      return(" HANDOFF");

   if(g_rbPlan.state == RB_ST_POST_TP1)
      return(" TP1_HIT");

   return(" PRE_TP1");
  }

//+------------------------------------------------------------------+
//| ตัวช่วยแก้ SL                                                     |
//+------------------------------------------------------------------+
//--- SL ใหม่ห่างราคาปัจจุบันอย่างน้อย Stop Level ของโบรก
bool RbSlDistOk(const bool buy, const double sl)
  {
   double minD = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL)
                 * SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   if(buy)
      return(SymbolInfoDouble(_Symbol, SYMBOL_BID) - sl >= minD);

   return(sl - SymbolInfoDouble(_Symbol, SYMBOL_ASK) >= minD);
  }

//--- แก้ SL/TP ผ่าน Core (ต้องเลือก Position ไว้แล้ว) แล้วบันทึกสถานะ
bool RbSetSl(const double newSl, const double tp, const string tag)
  {
   double sl = NormalizeDouble(newSl, _Digits);

   if(!ModifySL(g_rbPlan.ticket, sl, tp, tag))
      return(false);

   g_rbPlan.sl = sl;
   RbPlanPersist();
   return(true);
  }

//--- เลื่อน SL ไปที่ทุน (+BeBufferAtr x ATR ตอนเข้า) true = SL อยู่ที่หรือดีกว่าทุนแล้ว
bool RbMoveSlToBe(const string tag)
  {
   bool   buy    = (g_rbPlan.dir == POSITION_TYPE_BUY);
   double target = NormalizeDouble(buy ? g_rbPlan.entry + InpRbBeBufferAtr * g_rbPlan.atr
                                       : g_rbPlan.entry - InpRbBeBufferAtr * g_rbPlan.atr, _Digits);
   double curSl  = PositionGetDouble(POSITION_SL);
   bool   better = (curSl == 0.0) || (buy ? target > curSl : target < curSl);

   if(!better)
      return(true);

   if(!RbSlDistOk(buy, target))
     {
      Print(CORE_LOG_PREFIX, " ", tag, " SKIP | SL ใหม่ใกล้ราคาเกิน Stop Level",
            " | Bid=", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits),
            " Ask=", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits),
            " NewSL=", DoubleToString(target, _Digits),
            " | StopsLevel=", (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL), " pts");
      return(false);
     }

   Print(CORE_LOG_PREFIX, " ", tag, " TRY",
         " | Bid=", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits),
         " Ask=", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits),
         " | CurSL=", DoubleToString(curSl, _Digits),
         " NewSL=", DoubleToString(target, _Digits),
         " | StopsLevel=", (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL), " pts",
         " FreezeLevel=", (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL), " pts");

   if(RbSetSl(target, PositionGetDouble(POSITION_TP), tag))
     {
      Print(CORE_LOG_PREFIX, " ", tag, " | SL -> ", DoubleToString(target, _Digits));
      return(true);
     }

   return(false);
  }

void RbClosePlan(const string tag)
  {
   if(RawPositionClose(g_rbPlan.ticket, tag))
      Print(CORE_LOG_PREFIX, " CLOSE ", tag, " #", g_rbPlan.ticket);
   else
      Print(CORE_LOG_PREFIX, " CLOSE ", tag, " ล้มเหลว #", g_rbPlan.ticket, " (จะลองใหม่แท่งถัดไป)");
  }

//--- ปุ่ม BE NOW
void RbBeNow()
  {
   if(!g_rbPlan.active || !g_rbPlan.applied || !PositionSelectByTicket(g_rbPlan.ticket))
     {
      Print(CORE_LOG_PREFIX, " BE NOW | ไม่มีไม้ที่ RangeBot จัดการอยู่");
      return;
     }

   if(RbMoveSlToBe("BE-NOW"))
      Print(CORE_LOG_PREFIX, " BE NOW | เสร็จ (SL อยู่ที่หรือดีกว่าทุน)");
   else
      Print(CORE_LOG_PREFIX, " BE NOW | ทำไม่สำเร็จ ดู Log บรรทัดก่อนหน้า");
  }

//+------------------------------------------------------------------+
//| ตรวจทุก Tick: Mid-range BE และ TP1 (ยังไม่ Hand-off)               |
//+------------------------------------------------------------------+
void RbManageTick()
  {
   if(!g_rbPlan.active || !g_rbPlan.applied)
      return;

   if(g_rbPlan.state != RB_ST_PRE_TP1)
      return;

   if(!PositionSelectByTicket(g_rbPlan.ticket))
      return;

   bool   buy   = (g_rbPlan.dir == POSITION_TYPE_BUY);
   double price = SymbolInfoDouble(_Symbol, buy ? SYMBOL_BID : SYMBOL_ASK);

   if(InpRbUseMidRangeBe && !g_rbPlan.midDone)
     {
      double mid = (g_rbPlan.rHigh + g_rbPlan.rLow) / 2.0;

      if((buy && price >= mid) || (!buy && price <= mid))
        {
         if(RbMoveSlToBe("MID-BE"))
           {
            g_rbPlan.midDone = true;
            RbPlanPersist();
           }
        }
     }

   if((buy && price >= g_rbPlan.tp1) || (!buy && price <= g_rbPlan.tp1))
     {
      if(RbMoveSlToBe("TP1-BE"))
        {
         g_rbPlan.state        = RB_ST_POST_TP1;
         g_rbPlan.barsSinceTp1 = 0;
         RbPlanPersist();

         Print(CORE_LOG_PREFIX, " TP1 HIT #", g_rbPlan.ticket,
               " | Price=", DoubleToString(price, _Digits),
               " | SL=", DoubleToString(g_rbPlan.sl, _Digits));
        }
     }
  }

//+------------------------------------------------------------------+
//| ตรวจเมื่อเกิดแท่งใหม่                                              |
//+------------------------------------------------------------------+
//--- TrendShift แบบ TIGHTEN: SL -> Low/High ล่าสุด -/+ 0.3 ATR ถ้าดีกว่า SL เดิม
void RbTightenSl()
  {
   bool   buy    = (g_rbPlan.dir == POSITION_TYPE_BUY);
   double curSl  = PositionGetDouble(POSITION_SL);
   double newSl  = buy ? iLow(_Symbol, InpRbEntryTF, 1) - 0.3 * g_rbPlan.atr
                       : iHigh(_Symbol, InpRbEntryTF, 1) + 0.3 * g_rbPlan.atr;

   newSl = NormalizeDouble(newSl, _Digits);

   bool better = (curSl == 0.0) || (buy ? newSl > curSl : newSl < curSl);

   if(!better)
     {
      Print(CORE_LOG_PREFIX, " TIGHTEN SKIP | SL เดิมดีกว่าอยู่แล้ว");
      return;
     }

   if(!RbSlDistOk(buy, newSl))
     {
      Print(CORE_LOG_PREFIX, " TIGHTEN SKIP | SL ใหม่ใกล้ราคาเกิน Stop Level");
      return;
     }

   if(RbSetSl(newSl, PositionGetDouble(POSITION_TP), "RB-TIGHTEN"))
      Print(CORE_LOG_PREFIX, " TIGHTEN | SL -> ", DoubleToString(newSl, _Digits));
  }

//--- ปิดแท่งนอกกรอบตามเงื่อนไข Hand-off หรือไม่
bool RbHandOffReady()
  {
   double c = iClose(_Symbol, InpRbEntryTF, 1);

   if(c <= 0.0)
      return(false);

   double brk = InpRbHandOffBreakAtr * g_rbPlan.atr;

   if(g_rbPlan.dir == POSITION_TYPE_BUY)
     {
      if(!(c > g_rbPlan.rHigh + brk))
         return(false);

      if(InpRbHandOffRequireTrend && g_rbRegime != RB_REGIME_TREND_UP)
         return(false);

      return(true);
     }

   if(!(c < g_rbPlan.rLow - brk))
      return(false);

   if(InpRbHandOffRequireTrend && g_rbRegime != RB_REGIME_TREND_DOWN)
      return(false);

   return(true);
  }

//--- เข้าสู่ HANDED_OFF: ถอด TP ของโบรก (SL คงเดิม)
bool RbEnterHandOff()
  {
   double curSl = PositionGetDouble(POSITION_SL);

   if(!RbSetSl(curSl, 0.0, "RB-HANDOFF"))
     {
      Print(CORE_LOG_PREFIX, " HAND-OFF ล้มเหลว | ถอด TP ไม่สำเร็จ (จะลองใหม่แท่งถัดไป)");
      return(false);
     }

   g_rbPlan.state    = RB_ST_HANDED_OFF;
   g_rbPlan.tpBroker = 0.0;
   RbPlanPersist();

   Print(CORE_LOG_PREFIX, " HAND-OFF #", g_rbPlan.ticket,
         " | ถอด TP แล้ว เริ่ม Chandelier ", InpRbChandelierPeriod, "/",
         DoubleToString(InpRbChandelierMult, 1));
   return(true);
  }

//--- Chandelier Trailing: SL = HighestHigh(n) - Mult x ATR(n) (Sell กลับด้าน) เลื่อนเฉพาะทิศที่ได้เปรียบ
void RbChandelierTrail()
  {
   double chAtr = 0.0;

   if(!RbBufAt(g_rbChAtrH, 0, 1, chAtr) || chAtr <= 0.0)
      return;

   bool   buy   = (g_rbPlan.dir == POSITION_TYPE_BUY);
   int    n     = InpRbChandelierPeriod;
   double curSl = PositionGetDouble(POSITION_SL);
   double step  = InpRbTrailStepAtr * chAtr;
   double newSl = 0.0;

   if(buy)
     {
      int idx = iHighest(_Symbol, InpRbEntryTF, MODE_HIGH, n, 1);

      if(idx < 0)
         return;

      newSl = iHigh(_Symbol, InpRbEntryTF, idx) - InpRbChandelierMult * chAtr;
      newSl = NormalizeDouble(newSl, _Digits);

      if(!(newSl > curSl && newSl - curSl >= step))
         return;
     }
   else
     {
      int idx = iLowest(_Symbol, InpRbEntryTF, MODE_LOW, n, 1);

      if(idx < 0)
         return;

      newSl = iLow(_Symbol, InpRbEntryTF, idx) + InpRbChandelierMult * chAtr;
      newSl = NormalizeDouble(newSl, _Digits);

      if(!(newSl < curSl && curSl - newSl >= step))
         return;
     }

   if(!RbSlDistOk(buy, newSl))
      return;

   if(RbSetSl(newSl, PositionGetDouble(POSITION_TP), "RB-TRAIL"))
      Print(CORE_LOG_PREFIX, " TRAIL #", g_rbPlan.ticket,
            " | SL ", DoubleToString(curSl, _Digits), " -> ", DoubleToString(newSl, _Digits));
  }

//--- เรียกเมื่อเกิดแท่งใหม่ (หลังอัปเดต Regime + Range) ลำดับ: นับแท่ง -> ก่อน TP1 -> หลัง TP1 -> Trail
void RbManageOnNewBar()
  {
   if(!g_rbPlan.active || !g_rbPlan.applied)
      return;

   if(!PositionSelectByTicket(g_rbPlan.ticket))
      return;

   g_rbPlan.barsHeld++;

   if(g_rbPlan.state == RB_ST_POST_TP1)
      g_rbPlan.barsSinceTp1++;

   RbPlanPersist();

   //--- ก่อน TP1: MaxHold และ OnTrendShift_PreTP1
   if(g_rbPlan.state == RB_ST_PRE_TP1)
     {
      if(InpRbUseMaxHold && g_rbPlan.barsHeld >= InpRbMaxHoldBars)
        {
         Print(CORE_LOG_PREFIX, " MAXHOLD | ถือครบ ", g_rbPlan.barsHeld, " แท่งแล้วยังไม่ถึง TP1");
         RbClosePlan("RB-MAXHOLD");
         return;
        }

      //--- ทำงานเฉพาะเมื่อเทรนด์สวนทิศไม้ (BUY เจอ TREND_DOWN / SELL เจอ TREND_UP)
      //--- เทรนด์ทิศเดียวกับไม้ = ไม่ทำอะไรและไม่ตั้ง trendDone (ถ้าภายหลังกลับมาสวนทิศ ยังทำงานได้)
      bool trend = (g_rbPlan.dir == POSITION_TYPE_BUY) ? (g_rbRegime == RB_REGIME_TREND_DOWN)
                                                       : (g_rbRegime == RB_REGIME_TREND_UP);

      if(trend && !g_rbPlan.trendDone)
        {
         g_rbPlan.trendDone = true;
         RbPlanPersist();

         Print(CORE_LOG_PREFIX, " TREND SHIFT | Regime=", RbRegimeText(g_rbRegime),
               " | Action=", EnumToString(InpRbOnTrendShiftPreTp1));

         if(InpRbOnTrendShiftPreTp1 == RB_TS_CLOSE)
           {
            RbClosePlan("RB-TREND-CLOSE");
            return;
           }

         if(InpRbOnTrendShiftPreTp1 == RB_TS_TIGHTEN)
            RbTightenSl();
        }

      return;
     }

   //--- หลัง TP1 (ยังไม่ Hand-off): ตรวจ Hand-off แล้วค่อย Timeout
   if(g_rbPlan.state == RB_ST_POST_TP1)
     {
      if(InpRbUseHandOff && InpRbUseTp2 && RbHandOffReady())
        {
         if(!RbEnterHandOff())
            return;
        }
      else
        {
         if(InpRbUseRangeTimeout && g_rbPlan.barsSinceTp1 >= InpRbRangeTimeoutBars)
           {
            Print(CORE_LOG_PREFIX, " TIMEOUT | ผ่าน TP1 มา ", g_rbPlan.barsSinceTp1,
                  " แท่งแล้วไม่เบรกกรอบ -> ปิดส่วนที่เหลือ");
            RbClosePlan("RB-TIMEOUT");
         }

         return;
        }
     }

   if(g_rbPlan.state == RB_ST_HANDED_OFF)
      RbChandelierTrail();
  }

#endif // RANGEBOT_TRADE_MQH