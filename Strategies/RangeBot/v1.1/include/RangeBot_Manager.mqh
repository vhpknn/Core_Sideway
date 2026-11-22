//+------------------------------------------------------------------+
//|                                              RangeBot_Manager.mqh |
//|  เปิดไม้ (OpenOneOrder + ModifySL ตั้ง SL/TP ตาม ATR) + ประตูเข้า   |
//|  ชุด 3: ยังไม่มีการจัดการไม้ (TP1->BE, Hand-off ทำในชุด 4)          |
//|  ต้อง include หลัง RangeBot_Signals.mqh                            |
//+------------------------------------------------------------------+
#ifndef RANGEBOT_MANAGER_MQH
#define RANGEBOT_MANAGER_MQH

#define RB_FAIL_COOLDOWN   60   // วินาทีพักหลังเปิดไม้ล้มเหลว
#define RB_SLTP_MAX_TRIES  3    // จำนวนครั้งที่ลองตั้ง SL/TP ก่อนปิดไม้ทิ้ง

struct SRbPlan
  {
   bool               active;
   ulong              ticket;
   ENUM_POSITION_TYPE dir;
   double             sl;
   double             tp1;
   double             tp2;
   double             tpBroker;
   int                tries;
   bool               applied;   // ตั้ง SL/TP กับโบรกสำเร็จแล้ว
   int                state;     // RB_ST_PRE_TP1 / POST_TP1 / HANDED_OFF
   double             entry;     // ราคาเปิดจริง
   double             atr;       // ATR ตอนเข้า
   double             rHigh;     // ขอบกรอบตอนเข้า
   double             rLow;
   int                barsHeld;
   int                barsSinceTp1;
   bool               midDone;
   bool               trendDone;
  };

//--- ประกาศล่วงหน้า (นิยามอยู่ใน RangeBot_Trade.mqh)
void   RbPlanOnOpened();
void   RbPlanOnClosed();
void   RbPlanPersist();
string RbStateTag();

SRbPlan  g_rbPlan;
datetime g_rbLastOpenFail = 0;

void RbManagerReset()
  {
   g_rbPlan.active       = false;
   g_rbPlan.ticket       = 0;
   g_rbPlan.tries        = 0;
   g_rbPlan.applied      = false;
   g_rbPlan.state        = 1;
   g_rbPlan.entry        = 0.0;
   g_rbPlan.atr          = 0.0;
   g_rbPlan.rHigh        = 0.0;
   g_rbPlan.rLow         = 0.0;
   g_rbPlan.barsHeld     = 0;
   g_rbPlan.barsSinceTp1 = 0;
   g_rbPlan.midDone      = false;
   g_rbPlan.trendDone    = false;
   g_rbLastOpenFail      = 0;
  }

ulong RbFindPositionTicket(const ENUM_POSITION_TYPE dir)
  {
   ulong best = 0;
   long  bestTime = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong t = PositionGetTicket(i);

      if(t == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
         continue;
      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) != dir)
         continue;

      long tm = PositionGetInteger(POSITION_TIME_MSC);

      if(best == 0 || tm > bestTime)
        {
         best = t;
         bestTime = tm;
        }
     }

   return(best);
  }

//--- ตั้ง SL/TP ที่ยังไม่สำเร็จ (เรียกทุก Tick) ลองไม่เกิน 3 ครั้ง ถ้าไม่ได้ปิดไม้ทิ้ง
void RbEnsureSlTp()
  {
   if(!g_rbPlan.active)
      return;

   if(!PositionSelectByTicket(g_rbPlan.ticket))
     {
      RbPlanOnClosed();   // ไม้ปิดไปแล้ว: ล้างสถานะ
      return;
     }

   if(g_rbPlan.applied)
      return;

   if(g_rbPlan.tries >= RB_SLTP_MAX_TRIES)
     {
      Print(CORE_LOG_PREFIX, " CRITICAL | ตั้ง SL/TP ไม่สำเร็จ ", g_rbPlan.tries,
            " ครั้ง -> ปิดไม้ #", g_rbPlan.ticket);

      if(RawPositionClose(g_rbPlan.ticket, "RB-SLTP-FAIL"))
         g_rbPlan.active = false;

      return;
     }

   if(ModifySL(g_rbPlan.ticket, g_rbPlan.sl, g_rbPlan.tpBroker, "RB-SLTP"))
     {
      g_rbPlan.applied = true;
      RbPlanPersist();
      Print(CORE_LOG_PREFIX, " SL/TP SET #", g_rbPlan.ticket,
            " | SL=", DoubleToString(g_rbPlan.sl, _Digits),
            " TP=", DoubleToString(g_rbPlan.tpBroker, _Digits));
      return;
     }

   g_rbPlan.tries++;
  }

//--- ระยะ SL/TP ห่างราคาปัจจุบันอย่างน้อย Stop Level ของโบรก (Core ไม่ตรวจให้)
bool RbStopsOk(const ENUM_POSITION_TYPE dir, const double sl, const double tp)
  {
   double minD = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL)
                 * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   if(dir == POSITION_TYPE_BUY)
      return(bid - sl >= minD && tp - bid >= minD);

   return(sl - ask >= minD && ask - tp >= minD);
  }

void RbSigLogWhy(const string why)
  {
   static datetime lastPrint = 0;

   if(why == g_rbLastWhyLogged)
      return;

   g_rbLastWhyLogged = why;

   //--- เหตุผลสลับถี่ตามราคา: พิมพ์ไม่เกิน 1 บรรทัดต่อ 60 วินาที
   if(lastPrint > 0 && TimeCurrent() - lastPrint < 60)
      return;

   lastPrint = TimeCurrent();
   Print(CORE_LOG_PREFIX, " SIGNAL WAIT | ", why);
  }

//--- ลองเปิดไม้ตามสัญญาณที่รออยู่ (เรียกทุก Tick จนจบแท่ง)
void RbTryExecuteSignal()
  {
   if(!g_rbSig.active)
      return;

   //--- สัญญาณหมดอายุเมื่อรอเกิน InpRbSignalWaitMinutes
   if(InpRbSignalWaitMinutes > 0
      && (long)(TimeCurrent() - g_rbSig.created) > (long)InpRbSignalWaitMinutes * 60)
     {
      Print(CORE_LOG_PREFIX, " SIGNAL EXPIRED | รอเกิน ", InpRbSignalWaitMinutes,
            " นาที | เหตุผลล่าสุด=", (g_rbLastWhyLogged == "" ? "-" : g_rbLastWhyLogged));
      g_rbSig.active = false;
      return;
     }

   if(CoreBasketPositions() > 0 || g_rbPlan.active)
     {
      g_rbSig.active = false;
      return;
     }

   if(g_rbLastOpenFail > 0 && TimeCurrent() - g_rbLastOpenFail < RB_FAIL_COOLDOWN)
     {
      RbSigLogWhy("COOLDOWN");
      return;
     }

   //--- ประตูของ Core: ON/OFF, Report, ทุน, Session, Timeout, Spread
   string reason = "";

   if(!CanOpenAuto(g_emptySince, reason))
     {
      RbSigLogWhy(reason);
      return;
     }

   bool   buy   = (g_rbSig.dir == POSITION_TYPE_BUY);
   double entry = SymbolInfoDouble(_Symbol, buy ? SYMBOL_ASK : SYMBOL_BID);

   if(entry <= 0.0)
     {
      RbSigLogWhy("NO_PRICE");
      return;
     }

   double risk = buy ? entry - g_rbSig.sl : g_rbSig.sl - entry;

   if(risk <= 0.0)
     {
      RbSigLogWhy("SL_INVALID");
      return;
     }

   //--- เพดานขาดทุนต่อไม้ = InpCutLossPoints (เผื่อ Deviation ไม่ให้ Protect ของ Core ดึง SL)
   if(PriceToPoints(risk) + InpDeviationPoints > InpCutLossPoints)
     {
      RbSigLogWhy("SL_TOO_FAR");
      return;
     }

   double reward = buy ? g_rbSig.tp1 - entry : entry - g_rbSig.tp1;

   if(reward <= 0.0)
     {
      RbSigLogWhy("TP1_PASSED");
      return;
     }

   double rr = reward / risk;

   if(rr < InpRbMinRrTp1)
     {
      RbSigLogWhy("RR_LOW");
      return;
     }

   if(!RbStopsOk(g_rbSig.dir, g_rbSig.sl, g_rbSig.tpBroker))
     {
      RbSigLogWhy("STOP_LEVEL");
      return;
     }

   double equity = 0.0;

   if(!TryGetVirtualEquity(equity) || equity <= 0.0)
     {
      RbSigLogWhy("CAPITAL");
      return;
     }

   double lot = GetEffectiveLotForEquity(equity);

   if(!MathIsValidNumber(lot) || lot <= 0.0)
     {
      RbSigLogWhy("INVALID_LOT");
      return;
     }

   if(!BeginBasketCycle())
     {
      g_rbLastOpenFail = TimeCurrent();
      RbSigLogWhy("CYCLE_BLOCKED");
      return;
     }

   if(!OpenOneOrder(g_rbSig.dir, lot, "RB-" + g_rbSig.kind))
     {
      g_rbLastOpenFail = TimeCurrent();
      RbSigLogWhy("OPEN_FAILED");
      return;
     }

   g_emptySince = 0;
   g_rbEntryBar = iTime(_Symbol, InpRbEntryTF, 0);

   ulong ticket = RbFindPositionTicket(g_rbSig.dir);

   if(ticket == 0)
     {
      Print(CORE_LOG_PREFIX, " CRITICAL | เปิดไม้แล้วแต่ไม่พบ Position (Magic=", InpMagicNumber, ")");
      g_rbSig.active = false;
      return;
     }

   g_rbPlan.active   = true;
   g_rbPlan.ticket   = ticket;
   g_rbPlan.dir      = g_rbSig.dir;
   g_rbPlan.sl       = g_rbSig.sl;
   g_rbPlan.tp1      = g_rbSig.tp1;
   g_rbPlan.tp2      = g_rbSig.tp2;
   g_rbPlan.tpBroker = g_rbSig.tpBroker;
   g_rbPlan.tries    = 0;
   g_rbPlan.applied  = false;
   g_rbPlan.entry    = (PositionSelectByTicket(ticket) ? PositionGetDouble(POSITION_PRICE_OPEN) : entry);
   g_rbPlan.atr      = g_rbSig.atr;
   g_rbPlan.rHigh    = g_rbSig.rHigh;
   g_rbPlan.rLow     = g_rbSig.rLow;
   RbPlanOnOpened();

   Print(CORE_LOG_PREFIX, " ENTRY ", (buy ? "BUY " : "SELL "), g_rbSig.kind,
         " #", ticket, " | Lot=", DoubleToString(lot, 2),
         " | Price=", DoubleToString(entry, _Digits),
         " | SL=", DoubleToString(g_rbSig.sl, _Digits),
         " TP1=", DoubleToString(g_rbSig.tp1, _Digits),
         " TP2=", DoubleToString(g_rbSig.tp2, _Digits),
         " | Risk=", DoubleToString(PriceToPoints(risk), 0), " pts",
         " RR1=", DoubleToString(rr, 2));

   g_rbSig.active = false;
   RbEnsureSlTp();
  }

//--- ข้อความสถานะบน Panel (ช่อง Entry)
string RbGateText()
  {
   string g = RbRegimeText(g_rbRegime) + (g_rbRange.valid ? " BOX" : " NOBOX");

   if(CoreBasketPositions() > 0)
      return(g + " IN_TRADE" + RbStateTag());

   if(g_rbSig.active)
      return("SIG_" + (g_rbSig.dir == POSITION_TYPE_BUY ? "BUY" : "SELL")
             + ":" + (g_rbLastWhyLogged == "" ? "WAIT" : g_rbLastWhyLogged));

   return(g);
  }

#endif // RANGEBOT_MANAGER_MQH