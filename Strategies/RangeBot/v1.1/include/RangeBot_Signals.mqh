//+------------------------------------------------------------------+
//|                                              RangeBot_Signals.mqh |
//|  สัญญาณเข้า: ZONE / SWEEP + Trigger + ตัวกรอง (Blueprint A4.2-A4.4) |
//|  ประเมินเมื่อเกิดแท่งใหม่ จากแท่งที่ปิดแล้ว (shift 1 ขึ้นไป)         |
//|  ต้อง include หลัง RangeBot_Range.mqh                              |
//+------------------------------------------------------------------+
#ifndef RANGEBOT_SIGNALS_MQH
#define RANGEBOT_SIGNALS_MQH

int g_rbHtfEmaH = INVALID_HANDLE;
int g_rbHtfAtrH = INVALID_HANDLE;
int g_rbRsiH    = INVALID_HANDLE;
int g_rbStochH  = INVALID_HANDLE;

MqlRates g_rbR[];   // แท่ง EntryTF แบบ Series: [1] = แท่งที่ปิดล่าสุด

struct SRbSignal
  {
   bool               active;
   ENUM_POSITION_TYPE dir;
   string             kind;       // ZONE หรือ SWEEP
   double             sl;
   double             tp1;
   double             tp2;
   double             tpBroker;   // TP ที่ตั้งกับโบรก
  };

SRbSignal g_rbSig;
string    g_rbSigWhy       = "";   // เหตุผลที่ประเมินแท่งนี้แล้วไม่มีสัญญาณ
string    g_rbLastWhyLogged = "";  // เหตุผลล่าสุดที่รอเปิดไม้ (Log เฉพาะตอนเปลี่ยน)
datetime  g_rbEntryBar     = 0;    // แท่งที่เปิดไม้ไปแล้ว (กันเข้าซ้ำในแท่งเดียว)

void RbSignalsDeinit()
  {
   RbReleaseHandle(g_rbHtfEmaH);
   RbReleaseHandle(g_rbHtfAtrH);
   RbReleaseHandle(g_rbRsiH);
   RbReleaseHandle(g_rbStochH);
  }

bool RbValidateSignalInputs()
  {
   bool ok = true;

   if(InpRbHtfEma < 1 || InpRbHtfBufferAtr < 0.0)
     { Alert(CORE_LOG_PREFIX, " HtfEma ต้อง >= 1 และ HtfBufferAtr ต้องไม่ติดลบ"); ok = false; }

   if(InpRbZoneEntryPct <= 0.0 || InpRbZoneEntryPct > 50.0)
     { Alert(CORE_LOG_PREFIX, " ZoneEntryPct ต้องอยู่ในช่วง (0, 50]"); ok = false; }

   if(InpRbSweepMinAtr < 0.0 || InpRbSweepMinAtr >= InpRbSweepMaxAtr || InpRbSweepMinWickRatio <= 0.0)
     { Alert(CORE_LOG_PREFIX, " ต้องมี 0 <= SweepMinAtr < SweepMaxAtr และ SweepMinWickRatio > 0"); ok = false; }

   if(InpRbRsiPeriod < 2 || InpRbRsiBuy <= 0.0 || InpRbRsiBuy >= InpRbRsiSell || InpRbRsiSell >= 100.0)
     { Alert(CORE_LOG_PREFIX, " RSI: Period >= 2 และ 0 < RsiBuy < RsiSell < 100"); ok = false; }

   if(InpRbStochK < 1 || InpRbStochD < 1 || InpRbStochSlow < 1
      || InpRbStochLow < 0.0 || InpRbStochLow >= InpRbStochHigh || InpRbStochHigh > 100.0)
     { Alert(CORE_LOG_PREFIX, " Stoch: K/D/Slow >= 1 และ 0 <= Low < High <= 100"); ok = false; }

   if(InpRbCandlePinWickRatio <= 0.0)
     { Alert(CORE_LOG_PREFIX, " CandlePinWickRatio ต้องมากกว่า 0"); ok = false; }

   if(InpRbAdxSlopeBars < 1)
     { Alert(CORE_LOG_PREFIX, " AdxSlopeBars ต้อง >= 1"); ok = false; }

   if(InpRbPercentBBuy >= InpRbPercentBSell)
     { Alert(CORE_LOG_PREFIX, " PercentBBuy ต้องน้อยกว่า PercentBSell"); ok = false; }

   if(InpRbAtrVolAvgPeriod < 2 || InpRbAtrVolMin <= 0.0 || InpRbAtrVolMin >= InpRbAtrVolMax)
     { Alert(CORE_LOG_PREFIX, " AtrVol: AvgPeriod >= 2 และ 0 < Min < Max"); ok = false; }

   if(InpRbZoneSlAtr <= 0.0 || InpRbSweepSlAtr <= 0.0 || InpRbTp1BufferAtr < 0.0 || InpRbMinRrTp1 <= 0.0)
     { Alert(CORE_LOG_PREFIX, " ZoneSlAtr/SweepSlAtr/MinRrTp1 ต้อง > 0 และ Tp1BufferAtr ต้องไม่ติดลบ"); ok = false; }

   return(ok);
  }

//--- สร้าง Handle เฉพาะที่ใช้จริง
bool RbSignalsInit()
  {
   g_rbSig.active = false;
   g_rbSigWhy = "";
   g_rbLastWhyLogged = "";
   g_rbEntryBar = 0;

   if(InpRbRangeDirection == RB_DIR_FOLLOW_HTF)
     {
      g_rbHtfEmaH = iMA(_Symbol, InpRbHigherTF, InpRbHtfEma, 0, MODE_EMA, PRICE_CLOSE);
      g_rbHtfAtrH = iATR(_Symbol, InpRbHigherTF, InpRbAtrPeriod);

      if(g_rbHtfEmaH == INVALID_HANDLE || g_rbHtfAtrH == INVALID_HANDLE)
        {
         Alert(CORE_LOG_PREFIX, " สร้าง Indicator ของ HTF ไม่สำเร็จ | error=", GetLastError());
         RbSignalsDeinit();
         return(false);
        }
     }

   if(InpRbTriggerType == RB_TRIG_RSI)
     {
      g_rbRsiH = iRSI(_Symbol, InpRbEntryTF, InpRbRsiPeriod, PRICE_CLOSE);

      if(g_rbRsiH == INVALID_HANDLE)
        {
         Alert(CORE_LOG_PREFIX, " สร้าง RSI ไม่สำเร็จ | error=", GetLastError());
         RbSignalsDeinit();
         return(false);
        }
     }

   if(InpRbTriggerType == RB_TRIG_STOCH)
     {
      g_rbStochH = iStochastic(_Symbol, InpRbEntryTF, InpRbStochK, InpRbStochD,
                               InpRbStochSlow, MODE_SMA, STO_LOWHIGH);

      if(g_rbStochH == INVALID_HANDLE)
        {
         Alert(CORE_LOG_PREFIX, " สร้าง Stochastic ไม่สำเร็จ | error=", GetLastError());
         RbSignalsDeinit();
         return(false);
        }
     }

   return(true);
  }

bool RbBufAt(const int handle, const int buffer, const int shift, double &v)
  {
   double b[];
   ArraySetAsSeries(b, true);

   if(CopyBuffer(handle, buffer, shift, 1, b) != 1)
      return(false);

   v = b[0];
   return(MathIsValidNumber(v));
  }

//--- ทิศของ HTF: +1 ขึ้น / -1 ลง / 0 ไม่มีทิศ / 99 ข้อมูลไม่พร้อม
int RbHtfBias()
  {
   double ema = 0.0;
   double atr = 0.0;
   double cl[];
   ArraySetAsSeries(cl, true);

   if(!RbBufAt(g_rbHtfEmaH, 0, 1, ema)
      || !RbBufAt(g_rbHtfAtrH, 0, 1, atr)
      || CopyClose(_Symbol, InpRbHigherTF, 1, 1, cl) != 1)
      return(99);

   double buf = InpRbHtfBufferAtr * atr;

   if(cl[0] - ema > buf)
      return(1);
   if(ema - cl[0] > buf)
      return(-1);

   return(0);
  }

//--- ADX ชันขึ้นหรือไม่: 1 ใช่ / 0 ไม่ / -1 ข้อมูลไม่พร้อม
int RbAdxRising()
  {
   int n = InpRbAdxSlopeBars;
   double a[];
   ArraySetAsSeries(a, true);

   if(CopyBuffer(g_rbAdxH, 0, 0, n + 2, a) != n + 2)
      return(-1);

   return(a[1] > a[1 + n] ? 1 : 0);
  }

//--- ATR[1] / ค่าเฉลี่ย ATR อยู่ในช่วงที่กำหนดหรือไม่: 1 ใช่ / 0 ไม่ / -1 ข้อมูลไม่พร้อม
int RbAtrVolOk()
  {
   int n = InpRbAtrVolAvgPeriod;
   double a[];
   ArraySetAsSeries(a, true);

   if(CopyBuffer(g_rbAtrH, 0, 0, n + 2, a) != n + 2)
      return(-1);

   double sum = 0.0;

   for(int i = 1; i <= n; i++)
      sum += a[i];

   double avg = sum / n;

   if(avg <= 0.0)
      return(-1);

   double ratio = a[1] / avg;
   return((ratio >= InpRbAtrVolMin && ratio <= InpRbAtrVolMax) ? 1 : 0);
  }

//--- %B ของแท่งที่ต่ำสุด/สูงสุดใน 3 แท่งล่าสุด (ใช้ Buffer BB ที่คัดลอกไว้ตอนอัปเดต Regime)
bool RbPercentBOk(const ENUM_POSITION_TYPE dir)
  {
   int m = 1;

   for(int i = 2; i <= 3; i++)
     {
      if(dir == POSITION_TYPE_BUY)
        {
         if(g_rbR[i].low < g_rbR[m].low)
            m = i;
        }
      else
        {
         if(g_rbR[i].high > g_rbR[m].high)
            m = i;
        }
     }

   double w = g_rbUpBuf[m] - g_rbLoBuf[m];

   if(w <= 0.0)
      return(false);

   double pb = (g_rbR[m].close - g_rbLoBuf[m]) / w;

   if(dir == POSITION_TYPE_BUY)
      return(pb <= InpRbPercentBBuy);

   return(pb >= InpRbPercentBSell);
  }

bool RbCandleOk(const bool buy)
  {
   double o = g_rbR[1].open;
   double h = g_rbR[1].high;
   double l = g_rbR[1].low;
   double c = g_rbR[1].close;
   double body  = MathMax(MathAbs(c - o), _Point);
   double range = h - l;

   if(buy)
     {
      double wick = MathMin(o, c) - l;

      //--- Pin Bar: ไส้ล่างยาว และปิดใน 1/3 บนของแท่ง
      if(range > 0.0 && wick >= InpRbCandlePinWickRatio * body && (c - l) >= range * 2.0 / 3.0)
         return(true);

      //--- Bullish Engulfing: เนื้อแท่ง 1 คลุมเนื้อแท่ง 2 (แท่ง 2 เป็นแท่งลง)
      if(InpRbCandleUseEngulfing)
        {
         double o2 = g_rbR[2].open;
         double c2 = g_rbR[2].close;

         if(c > o && c2 < o2 && o <= c2 && c >= o2)
            return(true);
        }

      return(false);
     }

   double wickUp = h - MathMax(o, c);

   if(range > 0.0 && wickUp >= InpRbCandlePinWickRatio * body && (h - c) >= range * 2.0 / 3.0)
      return(true);

   if(InpRbCandleUseEngulfing)
     {
      double o2 = g_rbR[2].open;
      double c2 = g_rbR[2].close;

      if(c < o && c2 > o2 && o >= c2 && c <= o2)
         return(true);
     }

   return(false);
  }

bool RbTriggerOk(const ENUM_POSITION_TYPE dir)
  {
   bool buy = (dir == POSITION_TYPE_BUY);

   if(InpRbTriggerType == RB_TRIG_NONE)
      return(true);

   if(InpRbTriggerType == RB_TRIG_RSI)
     {
      double r[];
      ArraySetAsSeries(r, true);

      if(CopyBuffer(g_rbRsiH, 0, 0, 5, r) != 5)
         return(false);

      if(buy)
         return(MathMin(r[2], MathMin(r[3], r[4])) <= InpRbRsiBuy && r[1] > r[2]);

      return(MathMax(r[2], MathMax(r[3], r[4])) >= InpRbRsiSell && r[1] < r[2]);
     }

   if(InpRbTriggerType == RB_TRIG_STOCH)
     {
      double k[];
      double d[];
      ArraySetAsSeries(k, true);
      ArraySetAsSeries(d, true);

      if(CopyBuffer(g_rbStochH, 0, 0, 3, k) != 3 || CopyBuffer(g_rbStochH, 1, 0, 3, d) != 3)
         return(false);

      if(buy)
         return(k[2] < InpRbStochLow && k[1] > d[1] && k[1] > k[2]);

      return(k[2] > InpRbStochHigh && k[1] < d[1] && k[1] < k[2]);
     }

   return(RbCandleOk(buy));
  }

bool RbCheckZone(const ENUM_POSITION_TYPE dir)
  {
   double h = g_rbRange.height;
   double zone = h * InpRbZoneEntryPct / 100.0;

   if(dir == POSITION_TYPE_BUY)
     {
      if(!(g_rbR[1].low <= g_rbRange.low + zone))
         return(false);
      if(!(g_rbR[1].close > g_rbRange.low && g_rbR[1].close > g_rbR[1].open))
         return(false);
     }
   else
     {
      if(!(g_rbR[1].high >= g_rbRange.high - zone))
         return(false);
      if(!(g_rbR[1].close < g_rbRange.high && g_rbR[1].close < g_rbR[1].open))
         return(false);
     }

   if(!RbTriggerOk(dir))
      return(false);

   if(InpRbUsePercentB && !RbPercentBOk(dir))
      return(false);

   return(true);
  }

bool RbCheckSweep(const ENUM_POSITION_TYPE dir)
  {
   double atr  = g_rbRange.atr;
   double o    = g_rbR[1].open;
   double c    = g_rbR[1].close;
   double body = MathMax(MathAbs(c - o), _Point);
   double depth = 0.0;
   double wick  = 0.0;

   if(dir == POSITION_TYPE_BUY)
     {
      depth = g_rbRange.low - g_rbR[1].low;
      wick  = MathMin(o, c) - g_rbR[1].low;

      if(!(c > g_rbRange.low))
         return(false);
     }
   else
     {
      depth = g_rbR[1].high - g_rbRange.high;
      wick  = g_rbR[1].high - MathMax(o, c);

      if(!(c < g_rbRange.high))
         return(false);
     }

   if(depth < InpRbSweepMinAtr * atr || depth > InpRbSweepMaxAtr * atr)
      return(false);

   if(wick < InpRbSweepMinWickRatio * body)
      return(false);

   if(InpRbSweepRequireTrigger && !RbTriggerOk(dir))
      return(false);

   return(true);
  }

//--- คำนวณ SL/TP จากกรอบและแท่งสัญญาณ แล้วเก็บเป็นสัญญาณที่รอเปิด
void RbBuildSignal(const ENUM_POSITION_TYPE dir, const string kind)
  {
   double atr = g_rbRange.atr;
   double hi  = g_rbRange.high;
   double lo  = g_rbRange.low;
   double h   = g_rbRange.height;
   double sl, tp1, tp2;

   if(dir == POSITION_TYPE_BUY)
     {
      sl  = (kind == "SWEEP") ? g_rbR[1].low - InpRbSweepSlAtr * atr
                              : lo - InpRbZoneSlAtr * atr;
      tp1 = hi - InpRbTp1BufferAtr * atr;
      tp2 = hi + h;
     }
   else
     {
      sl  = (kind == "SWEEP") ? g_rbR[1].high + InpRbSweepSlAtr * atr
                              : hi + InpRbZoneSlAtr * atr;
      tp1 = lo + InpRbTp1BufferAtr * atr;
      tp2 = lo - h;
     }

   g_rbSig.active   = true;
   g_rbSig.dir      = dir;
   g_rbSig.kind     = kind;
   g_rbSig.sl       = NormalizeDouble(sl, _Digits);
   g_rbSig.tp1      = NormalizeDouble(tp1, _Digits);
   g_rbSig.tp2      = NormalizeDouble(tp2, _Digits);
   g_rbSig.tpBroker = InpRbUseTp2 ? g_rbSig.tp2 : g_rbSig.tp1;
   g_rbLastWhyLogged = "";

   Print(CORE_LOG_PREFIX, " SIGNAL ", (dir == POSITION_TYPE_BUY ? "BUY " : "SELL "), kind,
         " | SL=", DoubleToString(g_rbSig.sl, _Digits),
         " TP1=", DoubleToString(g_rbSig.tp1, _Digits),
         " TP2=", DoubleToString(g_rbSig.tp2, _Digits),
         " | Box ", DoubleToString(lo, _Digits), "-", DoubleToString(hi, _Digits),
         " ATR=", DoubleToString(atr, _Digits));
  }

//--- ประเมินสัญญาณเมื่อเกิดแท่งใหม่ (เรียกหลังอัปเดต Regime + Range)
void RbEvaluateSignal()
  {
   g_rbSig.active = false;
   g_rbSigWhy = "";

   if(g_rbEntryBar == iTime(_Symbol, InpRbEntryTF, 0))
     { g_rbSigWhy = "TRADED_THIS_BAR"; return; }

   if(g_rbRegime != RB_REGIME_RANGE || !g_rbRange.valid)
     { g_rbSigWhy = "NOT_RANGE"; return; }

   if(CoreBasketPositions() > 0)
     { g_rbSigWhy = "IN_TRADE"; return; }

   if(InpRbUseAdxSlope)
     {
      int s = RbAdxRising();

      if(s < 0) { g_rbSigWhy = "NO_DATA"; }
      else if(s == 1) { g_rbSigWhy = "ADX_RISING"; }

      if(g_rbSigWhy != "")
        { Print(CORE_LOG_PREFIX, " NOSIG | ", g_rbSigWhy); return; }
     }

   if(InpRbUseAtrVolFilter)
     {
      int v = RbAtrVolOk();

      if(v < 0) { g_rbSigWhy = "NO_DATA"; }
      else if(v == 0) { g_rbSigWhy = "ATR_VOL"; }

      if(g_rbSigWhy != "")
        { Print(CORE_LOG_PREFIX, " NOSIG | ", g_rbSigWhy); return; }
     }

   int bias = 0;

   if(InpRbRangeDirection == RB_DIR_FOLLOW_HTF)
     {
      bias = RbHtfBias();

      if(bias == 99) { g_rbSigWhy = "NO_DATA"; }
      else if(bias == 0) { g_rbSigWhy = "HTF_NONE"; }

      if(g_rbSigWhy != "")
        { Print(CORE_LOG_PREFIX, " NOSIG | ", g_rbSigWhy); return; }
     }

   ArraySetAsSeries(g_rbR, true);

   if(CopyRates(_Symbol, InpRbEntryTF, 0, 6, g_rbR) != 6)
     { g_rbSigWhy = "NO_DATA"; Print(CORE_LOG_PREFIX, " NOSIG | NO_DATA"); return; }

   bool allowBuy  = (InpRbRangeDirection == RB_DIR_BOTH_EDGES || bias > 0);
   bool allowSell = (InpRbRangeDirection == RB_DIR_BOTH_EDGES || bias < 0);
   bool useZone   = (InpRbEntryType != RB_ENTRY_SWEEP);
   bool useSweep  = (InpRbEntryType != RB_ENTRY_ZONE);

   for(int pass = 0; pass < 2; pass++)
     {
      ENUM_POSITION_TYPE dir = (pass == 0) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;

      if(dir == POSITION_TYPE_BUY && !allowBuy)
         continue;
      if(dir == POSITION_TYPE_SELL && !allowSell)
         continue;

      string kind = "";

      //--- เกิดทั้ง ZONE และ SWEEP ในแท่งเดียว ใช้ SWEEP
      if(useSweep && RbCheckSweep(dir))
         kind = "SWEEP";
      else if(useZone && RbCheckZone(dir))
         kind = "ZONE";

      if(kind == "")
         continue;

      RbBuildSignal(dir, kind);
      return;
     }

   g_rbSigWhy = "NO_SIGNAL";
   Print(CORE_LOG_PREFIX, " NOSIG | NO_SIGNAL", (bias != 0 ? (bias > 0 ? " (bias UP)" : " (bias DOWN)") : ""));
  }

#endif // RANGEBOT_SIGNALS_MQH