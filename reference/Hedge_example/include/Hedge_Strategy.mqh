//+------------------------------------------------------------------+
//|                                                Hedge_Strategy.mqh|
//|  กลยุทธ์ Hedge: เปิดคู่ Buy+Sell แบบ Mirror-and-Verify,           |
//|  One Basket Only, Strict Manual Entry + ฟังก์ชัน Strategy_*       |
//|  ที่มา: ส่วน Hedge ของ Hedge1_Engine.mqh (dcf4a12) ไม่แก้ตรรกะ    |
//|  ต้อง include หลัง Core ทั้งหมด และ CoreUI_Theme.mqh              |
//+------------------------------------------------------------------+
#ifndef HEDGE_STRATEGY_MQH
#define HEDGE_STRATEGY_MQH

#define HEDGE_FAIL_COOLDOWN 60    // วินาทีพักหลังเปิดคู่ Hedge ล้มเหลว
#define HEDGE_RETRY_MAX     3     // จำนวน retry ฝั่งที่เปิดไม่สำเร็จ

//+------------------------------------------------------------------+
//| D-31: โควต้าจำนวนรอบเปิดคู่อัตโนมัติ (InpMaxAutoRounds)            |
//| 0 = ไม่จำกัด (พฤติกรรมเดิม ไม่แตะ State ใดๆ)                       |
//| - นับ +1 เมื่อรอบอัตโนมัติเปิดคู่สำเร็จจริง (IsExactHedgePair)       |
//| - ปุ่ม HEDGE OPEN ไม่นับและไม่ถูกบล็อก                            |
//| - รีเซ็ตเมื่อช่วง Session Block ใดๆ สิ้นสุด (Session กลับเป็น OPEN)  |
//| - State (ตัวนับ + รหัสรอบ) เก็บเป็น GV กันรีเซ็ตเองเมื่อรีสตาร์ท EA   |
//+------------------------------------------------------------------+
int      g_quotaCount = 0;   // จำนวนรอบอัตโนมัติที่เปิดแล้วในช่วงปัจจุบัน
datetime g_quotaEpoch = 0;   // เวลาจบช่วง Session Block ล่าสุดที่ใช้รีเซ็ตแล้ว

string HedgeQuotaCountGV() { return(CoreStateGVName("QN")); }
string HedgeQuotaEpochGV() { return(CoreStateGVName("QE")); }

//--- บันทึกตัวนับและรหัสรอบ (ตัวนับก่อน: ถ้าหยุดกลางคัน รอบถัดไปรีเซ็ตซ้ำได้ ไม่เสียหาย)
bool HedgeQuotaSave()
  {
   if((bool)MQLInfoInteger(MQL_TESTER))
      return(true);

   string nCount = HedgeQuotaCountGV();
   string nEpoch = HedgeQuotaEpochGV();

   if(StringLen(nCount) > 63 || StringLen(nEpoch) > 63)
     {
      Print(CORE_LOG_PREFIX, " QUOTA บันทึก State ไม่ได้ | Key ยาวเกิน 63 ตัวอักษร");
      return(false);
     }

   ResetLastError();

   if(GlobalVariableSet(nCount, (double)g_quotaCount) == 0
      || GlobalVariableSet(nEpoch, (double)g_quotaEpoch) == 0)
     {
      Print(CORE_LOG_PREFIX, " QUOTA บันทึก State ไม่สำเร็จ | error=", GetLastError(),
            " | ตัวนับมีผลจนกว่าจะรีสตาร์ท");
      return(false);
     }

   GlobalVariablesFlush();
   return(true);
  }

//--- โหลด State ตอนเริ่มระบบ อ่านไม่ได้/ผิดปกติ = ถือว่าหมดโควต้า (ปลอดภัยไว้ก่อน)
void HedgeQuotaLoad()
  {
   g_quotaCount = 0;
   g_quotaEpoch = 0;

   if((bool)MQLInfoInteger(MQL_TESTER))
      return;

   string nCount = HedgeQuotaCountGV();
   string nEpoch = HedgeQuotaEpochGV();

   if(StringLen(nCount) > 63 || StringLen(nEpoch) > 63)
     {
      Print(CORE_LOG_PREFIX, " QUOTA State Key ยาวเกิน 63 ตัวอักษร -> ไม่จำตัวนับข้ามการรีสตาร์ท");
      return;
     }

   bool   bad = false;
   double v   = 0.0;

   if(GlobalVariableCheck(nEpoch))
     {
      if(GlobalVariableGet(nEpoch, v) && MathIsValidNumber(v) && v >= 0.0)
         g_quotaEpoch = (datetime)(long)v;
      else
         bad = true;
     }

   if(GlobalVariableCheck(nCount))
     {
      if(GlobalVariableGet(nCount, v) && MathIsValidNumber(v) && v >= 0.0 && v <= 1000000.0)
         g_quotaCount = (int)v;
      else
         bad = true;
     }

   if(bad)
     {
      g_quotaCount = (InpMaxAutoRounds > 0) ? InpMaxAutoRounds : 0;
      g_quotaEpoch = 0;
      Print(CORE_LOG_PREFIX, " QUOTA State อ่านไม่ได้หรือไม่ถูกต้อง",
            " -> ถือว่าหมดโควต้า รอ Session Block สิ้นสุดเพื่อรีเซ็ต");
     }
  }

//--- เวลาจบล่าสุด (<= เวลาปัจจุบัน) ของช่วง Session Block ที่เปิดอยู่ 0 = ไม่มีช่วงที่ใช้ได้
datetime HedgeLastSessionEnd()
  {
   long now  = (long)TimeCurrent();
   long day0 = now - (now % 86400);
   long best = 0;

   for(int i = 0; i < 3; i++)
     {
      bool   blockOn  = false;
      bool   closeOn  = false;
      string startStr = "";
      string endStr   = "";

      SessionCloseConfig(i, blockOn, closeOn, startStr, endStr);

      if(!blockOn)
         continue;

      bool isActive = false;
      int  s = 0;
      int  e = 0;

      if(!GetSessionWindow(i, blockOn, startStr, endStr, isActive, s, e) || !isActive)
         continue;

      if(s == e)
         continue;

      long endT = day0 + (long)e * 60;

      if(endT > now)
         endT -= 86400;

      if(endT > best)
         best = endT;
     }

   return((datetime)best);
  }

//--- รีเซ็ตโควต้าเมื่อมีช่วง Session Block สิ้นสุดใหม่ (เรียกทุก Tick ใน HedgeOnTick)
void HedgeQuotaSync()
  {
   if(InpMaxAutoRounds <= 0)
      return;

   datetime epoch = HedgeLastSessionEnd();

   if(epoch <= g_quotaEpoch)
      return;

   int oldCount = g_quotaCount;

   g_quotaCount = 0;
   g_quotaEpoch = epoch;
   HedgeQuotaSave();

   Print(CORE_LOG_PREFIX, " QUOTA RESET | Session Block สิ้นสุด ",
         TimeToString(epoch, TIME_DATE | TIME_MINUTES),
         " | ตัวนับเดิม=", oldCount,
         " | โควต้า=", InpMaxAutoRounds);
  }

//--- นับ +1 หลังรอบอัตโนมัติเปิดคู่สำเร็จจริง
void HedgeQuotaConsume()
  {
   if(InpMaxAutoRounds <= 0)
      return;

   g_quotaCount++;
   HedgeQuotaSave();

   Print(CORE_LOG_PREFIX, " QUOTA USED | ", g_quotaCount, "/", InpMaxAutoRounds);

   if(g_quotaCount >= InpMaxAutoRounds)
      Print(CORE_LOG_PREFIX, " QUOTA_DONE | หมดโควต้ารอบอัตโนมัติ",
            " รอ Session Block สิ้นสุดเพื่อรีเซ็ต");
  }

//--- เรียกจาก Strategy_Init: ตรวจค่า โหลด State และเตือนการตั้งค่าที่ไม่ครบ
bool HedgeQuotaInit()
  {
   if(InpMaxAutoRounds < 0)
     {
      Alert(CORE_LOG_PREFIX, " InpMaxAutoRounds ต้องไม่ติดลบ (0 = ไม่จำกัด)");
      return(false);
     }

   if(InpMaxAutoRounds == 0)
      return(true);

   HedgeQuotaLoad();

   Print(CORE_LOG_PREFIX, " QUOTA เปิดใช้ | สูงสุด=", InpMaxAutoRounds,
         " รอบ/ช่วง | ใช้ไปแล้ว=", g_quotaCount,
         " | รีเซ็ตล่าสุด=",
         (g_quotaEpoch > 0 ? TimeToString(g_quotaEpoch, TIME_DATE | TIME_MINUTES) : "ยังไม่เคย"));

   if(!InpSession1Block && !InpSession2Block && !InpSession3Block)
      Print(CORE_LOG_PREFIX, " เตือน: InpMaxAutoRounds>0 แต่ไม่มี Session Block ที่เปิดอยู่",
            " โควต้าจะไม่รีเซ็ตเอง");

   if(!InpReopenOnEmpty)
      Print(CORE_LOG_PREFIX, " หมายเหตุ: InpReopenOnEmpty=false ปิดการเปิดอัตโนมัติอยู่",
            " โควต้าจึงไม่มีผล");

   return(true);
  }

datetime g_lastOpenFail = 0;      // เวลาที่เปิดคู่ Hedge ล้มเหลวล่าสุด

//+------------------------------------------------------------------+
//| ตรวจว่า Hedge Pair สมบูรณ์จริงหรือไม่                              |
//| ต้องมี Buy 1, Sell 1 และ Lot ทั้งสองฝั่งต้องตรงกัน                 |
//+------------------------------------------------------------------+
bool IsExactHedgePair(double expectedLot)
  {
   int buyCount  = CoreCountSide(POSITION_TYPE_BUY);
   int sellCount = CoreCountSide(POSITION_TYPE_SELL);

   double buyLot  = GetSideVolume(POSITION_TYPE_BUY);
   double sellLot = GetSideVolume(POSITION_TYPE_SELL);

   return(buyCount == 1
          && sellCount == 1
          && IsLotMatched(buyLot, expectedLot)
          && IsLotMatched(sellLot, expectedLot));
  }

//+------------------------------------------------------------------+
//| Rollback Position ของ Hedge ที่เปิดไม่สมบูรณ์                       |
//| พยายามปิดสูงสุด 3 รอบ และตรวจว่า Position หายจริง                 |
//+------------------------------------------------------------------+
bool RollbackHedgePair()
  {
   for(int attempt = 1; attempt <= HEDGE_RETRY_MAX; attempt++)
     {
      int buyCount  = CoreCountSide(POSITION_TYPE_BUY);
      int sellCount = CoreCountSide(POSITION_TYPE_SELL);

      if(buyCount == 0 && sellCount == 0)
        {
         Print(CORE_LOG_PREFIX, " HEDGE ROLLBACK สำเร็จ | Basket ว่าง");
         return(true);
        }

      Print(CORE_LOG_PREFIX, " HEDGE ROLLBACK รอบ ", attempt,
            " | Buy=", buyCount,
            " Sell=", sellCount);

      if(buyCount > 0)
         CloseOneSide(POSITION_TYPE_BUY, "HEDGE-ROLLBACK");

      if(sellCount > 0)
         CloseOneSide(POSITION_TYPE_SELL, "HEDGE-ROLLBACK");
     }

   int remainingBuy  = CoreCountSide(POSITION_TYPE_BUY);
   int remainingSell = CoreCountSide(POSITION_TYPE_SELL);

   //--- การปิดในรอบสุดท้ายอาจทำให้ Basket ว่างแล้ว
   if(remainingBuy == 0 && remainingSell == 0)
     {
      Print(CORE_LOG_PREFIX, " HEDGE ROLLBACK สำเร็จหลังรอบสุดท้าย",
            " | Basket ว่าง");
      return(true);
     }

   Print(CORE_LOG_PREFIX, " CRITICAL - HEDGE ROLLBACK ปิดไม่หมด",
         " | Buy=", remainingBuy,
         " Sell=", remainingSell);

   return(false);
  }

//+------------------------------------------------------------------+
//| เปิดคู่ Hedge (Buy + Sell) แบบ Mirror-and-Verify                  |
//| ส่งสองฝั่งติดกัน -> ตรวจ Position จริง -> Rollback หากไม่สมมาตร   |
//+------------------------------------------------------------------+
bool OpenHedgePair()
  {
   if(!g_engineReady)
      return(false);

   if(g_reportBlocksEntry)
     {
      Print(CORE_LOG_PREFIX, " HEDGE ENTRY BLOCKED",
            " | WAIT_REPORT");
      return(false);
     }

   //--- One Basket Only: ห้ามเปิด Hedge ใหม่ ถ้ายังมี Position ของ EA ค้างอยู่
   int existingBuy  = CoreCountSide(POSITION_TYPE_BUY);
   int existingSell = CoreCountSide(POSITION_TYPE_SELL);

   if(existingBuy > 0 || existingSell > 0)
     {
      Print(CORE_LOG_PREFIX, " ปฏิเสธการเปิด Hedge ใหม่ เพราะ Basket ยังไม่ว่าง",
            " | Buy=", existingBuy,
            " Sell=", existingSell);
      return(false);
     }

   double equity = 0.0;

   if(!TryGetVirtualEquity(equity))
     {
      Print(CORE_LOG_PREFIX, " HEDGE ENTRY BLOCKED",
            " | CAPITAL_UNAVAILABLE");
      return(false);
     }

   if(equity <= 0.0)
     {
      Print(CORE_LOG_PREFIX, " HEDGE ENTRY BLOCKED",
            " | CAPITAL_DEAD",
            " | Equity=", DoubleToString(equity, 2));
      return(false);
     }

   //--- ใช้ทุนที่ตรวจผ่านแล้ว ไม่อ่านทุนซ้ำในสูตร Lot
   double lot = GetEffectiveLotForEquity(equity);

   if(!MathIsValidNumber(lot) || lot <= 0.0)
     {
      Print(CORE_LOG_PREFIX, " HEDGE ENTRY BLOCKED",
            " | INVALID_LOT",
            " | Equity=", DoubleToString(equity, 2));
      return(false);
     }

   //--- บันทึกฐาน Cycle ก่อนส่ง Order แรก
   if(!BeginBasketCycle())
      return(false);

   //--- เปิด Buy และ Sell รอบแรก
   OpenOneOrder(POSITION_TYPE_BUY,  lot, "HEDGE");
   OpenOneOrder(POSITION_TYPE_SELL, lot, "HEDGE");

   //--- Retry เฉพาะฝั่งที่ Position ยังไม่เกิดจริง
   //--- หากมี Position เกิน 1 ไม้ จะไม่ Retry เพิ่ม เพื่อกัน Hedge ซ้อน
   for(int attempt = 1; attempt <= HEDGE_RETRY_MAX; attempt++)
     {
      int buyCount  = CoreCountSide(POSITION_TYPE_BUY);
      int sellCount = CoreCountSide(POSITION_TYPE_SELL);

      if(buyCount > 1 || sellCount > 1)
         break;

      if(buyCount == 1 && sellCount == 1)
         break;

      if(buyCount == 0)
        {
         Print(CORE_LOG_PREFIX, " Retry เปิด Buy รอบ ", attempt);
         OpenOneOrder(POSITION_TYPE_BUY, lot, "HEDGE-RETRY");
        }

      if(sellCount == 0)
        {
         Print(CORE_LOG_PREFIX, " Retry เปิด Sell รอบ ", attempt);
         OpenOneOrder(POSITION_TYPE_SELL, lot, "HEDGE-RETRY");
        }
     }

   //--- ตรวจ Position จริง ไม่ใช้แค่ผลลัพธ์จาก OrderSend
   if(IsExactHedgePair(lot))
     {
      g_emptySince = 0;

      Print(CORE_LOG_PREFIX, " เปิดคู่ Hedge สำเร็จจริง",
            " | Buy=", CoreCountSide(POSITION_TYPE_BUY),
            " Lot=", DoubleToString(GetSideVolume(POSITION_TYPE_BUY), 2),
            " | Sell=", CoreCountSide(POSITION_TYPE_SELL),
            " Lot=", DoubleToString(GetSideVolume(POSITION_TYPE_SELL), 2));

      return(true);
     }

   //--- Position ไม่สมมาตร / Lot ไม่ตรง / Partial Fill / เปิดซ้อน
   int finalBuyCount  = CoreCountSide(POSITION_TYPE_BUY);
   int finalSellCount = CoreCountSide(POSITION_TYPE_SELL);

   double finalBuyLot  = GetSideVolume(POSITION_TYPE_BUY);
   double finalSellLot = GetSideVolume(POSITION_TYPE_SELL);

   Print(CORE_LOG_PREFIX, " Hedge Pair ไม่สมบูรณ์ -> Rollback",
         " | Buy=", finalBuyCount,
         " Lot=", DoubleToString(finalBuyLot, 2),
         " | Sell=", finalSellCount,
         " Lot=", DoubleToString(finalSellLot, 2),
         " | ExpectedLot=", DoubleToString(lot, 2));

   RollbackHedgePair();
   return(false);
  }

//+------------------------------------------------------------------+
//| พยายามเปิดรอบใหม่เมื่อ Basket ว่าง                                |
//+------------------------------------------------------------------+
void TryOpenNewRound()
  {
   if(!InpReopenOnEmpty)
     { g_gateReason = "AUTO_OFF"; return; }

   //--- D-31: หมดโควต้ารอบอัตโนมัติ (ถ้าผู้ใช้กด OFF อยู่ ให้ CanOpenAuto รายงาน PAUSED ตามเดิม)
   if(InpMaxAutoRounds > 0 && !CoreIsPaused() && g_quotaCount >= InpMaxAutoRounds)
     { g_gateReason = "QUOTA_DONE"; return; }

   if(g_lastOpenFail > 0 && TimeCurrent() - g_lastOpenFail < HEDGE_FAIL_COOLDOWN)
     { g_gateReason = "COOLDOWN"; return; }

   string reason = "";
   if(!CanOpenAuto(g_emptySince, reason))
     { g_gateReason = reason; return; }

   Print(CORE_LOG_PREFIX, " AUTO READY -> เปิด Hedge ใหม่ | Spread=",
         DoubleToString(GetSpreadPoints(), 1),
         " / Max=", InpMaxSpreadPoints,
         " | Timeout=", InpTimeoutSeconds,
         " sec | Lot=", DoubleToString(GetEffectiveLot(), 2));

   if(OpenHedgePair())
     {
      g_lastOpenFail = 0;
      HedgeQuotaConsume();   // D-31: นับเฉพาะรอบอัตโนมัติที่เปิดคู่สำเร็จจริง
     }
   else
      g_lastOpenFail = TimeCurrent();
  }

//--- Strict One Basket: ไม่มีระบบเปิดคืนขาที่หาย
//--- การเปิดรอบใหม่ทำผ่าน TryOpenNewRound() เมื่อ Basket ว่างเท่านั้น

//+------------------------------------------------------------------+
//| หัวใจของกลยุทธ์ Hedge เรียกทุก Tick (หลัง Protect ทำงานเสร็จ)      |
//| (เดิมชื่อ EngineOnTick)                                          |
//+------------------------------------------------------------------+
void HedgeOnTick()
  {
   if(!g_engineReady)
      return;

   HedgeQuotaSync();   // D-31: รีเซ็ตโควต้าเมื่อช่วง Session Block สิ้นสุด

   int buys  = CoreCountSide(POSITION_TYPE_BUY);
   int sells = CoreCountSide(POSITION_TYPE_SELL);

   if(buys + sells == 0)
     {
      //--- เริ่มนับ Timeout เมื่อ Basket ว่าง
      if(g_emptySince == 0)
         g_emptySince = TimeCurrent();

      TryOpenNewRound();
     }
   else
     {
      //--- มี Position ค้างอย่างน้อยหนึ่งไม้ = Basket ยังไม่ว่าง
      //--- ไม่เปิดขาที่หาย และไม่เปิดคู่ Hedge เพิ่ม
      g_emptySince = 0;

      if(buys > 0 && sells > 0)
         g_gateReason = "BASKET_RUNNING";
      else
         g_gateReason = "WAIT_BASKET_EMPTY";
     }
  }

//+------------------------------------------------------------------+
//| Strict Manual Entry: ห้ามเปิด BUY / SELL เดี่ยว                    |
//| HEDGE เปิดได้เฉพาะ Basket ว่าง ตามกฎ OpenHedgePair()               |
//| คำสั่งปิดยังใช้ได้ ไม่ถูก Session/Timeout บล็อก                   |
//+------------------------------------------------------------------+
bool ManualBuy()
  {
   Print(CORE_LOG_PREFIX, " STRICT_BASKET BLOCKED MANUAL BUY",
         " | Use HEDGE OPEN (B+S)");
   return(false);
  }

bool ManualSell()
  {
   Print(CORE_LOG_PREFIX, " STRICT_BASKET BLOCKED MANUAL SELL",
         " | Use HEDGE OPEN (B+S)");
   return(false);
  }

bool ManualHedge()
  {
   if(!g_engineReady)
      return(false);

   //--- สวิตช์ ON/OFF: OFF = ห้ามเปิดออเดอร์ใหม่ทุกทาง รวมปุ่มมือ (D-13)
   if(CoreIsPaused())
     {
      Print(CORE_LOG_PREFIX, " HEDGE ENTRY BLOCKED",
            " | PAUSED");
      return(false);
     }

   //--- รีเฟรช Report Gate ก่อน Manual Entry
   //--- Manual ยังข้าม Auto Session/Timeout/Spread ตามกติกาเดิม
   ReportOnTick();

   return(OpenHedgePair());
  }

//====================================================================
// ฟังก์ชันตามสัญญา Core_StrategyAPI
//====================================================================

string Strategy_Title()
  {
   return("Hedge 1.0");
  }

string Strategy_Version()
  {
   return("1.0.1");
  }

ENUM_ACCT_SUPPORT Strategy_AccountSupport()
  {
   return(ACCT_HEDGING_ONLY);
  }

bool Strategy_Init()
  {
   return(HedgeQuotaInit());
  }

void Strategy_OnTick()
  {
   HedgeOnTick();
  }

void Strategy_CloseAll(string tag)
  {
   CloseOneSide(POSITION_TYPE_BUY,  tag);
   CloseOneSide(POSITION_TYPE_SELL, tag);
  }

int Strategy_ButtonCount()
  {
   return(3);
  }

//--- ช่อง 1-2 = BUY/SELL LOCKED, ช่อง 3 = HEDGE OPEN (ตำแหน่งตาม Core_Panel)
bool Strategy_ButtonDef(int index, SStrategyButton &def)
  {
   if(index == 0)
     {
      def.id        = "BUY";
      def.text      = "BUY LOCKED";
      def.bg        = CUI_BTN_REFILL;
      def.border    = CUI_BORDER;
      def.tooltip   = "Strict Basket: single BUY blocked. Use HEDGE OPEN (B+S).";
      def.textColor = CUI_LABEL;
      return(true);
     }

   if(index == 1)
     {
      def.id        = "SELL";
      def.text      = "SELL LOCKED";
      def.bg        = CUI_BTN_REFILL;
      def.border    = CUI_BORDER;
      def.tooltip   = "Strict Basket: single SELL blocked. Use HEDGE OPEN (B+S).";
      def.textColor = CUI_LABEL;
      return(true);
     }

   if(index == 2)
     {
      def.id        = "HEDGE";
      def.text      = "HEDGE OPEN (B+S)";
      def.bg        = CUI_BTN_HEDGE;
      def.border    = CUI_FRAME_HEDGE;
      def.tooltip   = "";
      def.textColor = CLR_NONE;
      return(true);
     }

   return(false);
  }

void Strategy_OnButton(string id)
  {
   if(id == "BUY")
      ManualBuy();
   else if(id == "SELL")
      ManualSell();
   else if(id == "HEDGE")
      ManualHedge();
  }

string Strategy_GateText()
  {
   string gate = GetEngineGateText();

   //--- D-31: ต่อท้ายตัวนับ/โควต้า ยกเว้น READY (Core_Panel เทียบข้อความ READY เพื่อใช้สีเขียว)
   if(InpMaxAutoRounds > 0 && InpReopenOnEmpty && gate != "READY")
      gate += " " + IntegerToString(g_quotaCount) + "/" + IntegerToString(InpMaxAutoRounds);

   return(gate);
  }

#endif // HEDGE_STRATEGY_MQH