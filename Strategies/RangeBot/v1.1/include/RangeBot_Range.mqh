//+------------------------------------------------------------------+
//|                                               RangeBot_Range.mqh |
//|  RangeDetector + RangeLock (Blueprint A4.1) + ATR + เส้นกรอบบนกราฟ |
//|  ต้อง include หลัง RangeBot_Regime.mqh                            |
//+------------------------------------------------------------------+
#ifndef RANGEBOT_RANGE_MQH
#define RANGEBOT_RANGE_MQH

struct SRbRange
  {
   bool   valid;        // มีกรอบที่ใช้ได้ (ตรวจใหม่หรือล็อกไว้)
   bool   locked;       // กรอบถูกล็อก
   double high;
   double low;
   double height;
   double atr;          // ATR ของแท่ง shift 1
   int    touchHigh;
   int    touchLow;
   int    lockBars;     // จำนวนแท่งนับตั้งแต่ล็อก
   string reason;       // เหตุผลสถานะล่าสุด
  };

SRbRange g_rbRange;
int      g_rbAtrH        = INVALID_HANDLE;
bool     g_rbForceUpdate = false;   // true = บังคับคำนวณใหม่ใน Tick ถัดไป (ปุ่ม RESET RANGE)

#define RB_OBJ_HI "RNGRB_HI"
#define RB_OBJ_LO "RNGRB_LO"

void RbRangeClear()
  {
   g_rbRange.valid     = false;
   g_rbRange.locked    = false;
   g_rbRange.high      = 0.0;
   g_rbRange.low       = 0.0;
   g_rbRange.height    = 0.0;
   g_rbRange.atr       = 0.0;
   g_rbRange.touchHigh = 0;
   g_rbRange.touchLow  = 0;
   g_rbRange.lockBars  = 0;
   g_rbRange.reason    = "";
  }

void RbRangeDeinit()
  {
   RbReleaseHandle(g_rbAtrH);
   ObjectDelete(0, RB_OBJ_HI);
   ObjectDelete(0, RB_OBJ_LO);
  }

bool RbRangeInit()
  {
   g_rbAtrH = iATR(_Symbol, InpRbEntryTF, InpRbAtrPeriod);

   if(g_rbAtrH == INVALID_HANDLE)
     {
      Alert(CORE_LOG_PREFIX, " สร้าง ATR ไม่สำเร็จ | error=", GetLastError());
      return(false);
     }

   RbRangeClear();
   return(true);
  }

bool RbReadAtr(const int shift, double &atr)
  {
   double buf[];
   ArraySetAsSeries(buf, true);

   if(CopyBuffer(g_rbAtrH, 0, shift, 1, buf) != 1)
      return(false);

   atr = buf[0];
   return(MathIsValidNumber(atr) && atr > 0.0);
  }

//--- หากรอบจากแท่ง shift (1+Exclude) ถึง (Lookback+Exclude)
//--- คืน true = กรอบใช้ได้ | reason = "NO_DATA" ให้ผู้เรียกลองใหม่
bool RbRangeDetect(const double atr, double &hi, double &lo,
                   int &touchH, int &touchL, string &reason)
  {
   double highs[];
   double lows[];
   int    start = 1 + InpRbRangeExcludeBars;
   int    count = InpRbRangeLookback;

   if(CopyHigh(_Symbol, InpRbEntryTF, start, count, highs) != count
      || CopyLow(_Symbol, InpRbEntryTF, start, count, lows) != count)
     {
      reason = "NO_DATA";
      return(false);
     }

   hi = highs[ArrayMaximum(highs)];
   lo = lows[ArrayMinimum(lows)];

   double height = hi - lo;

   if(height < InpRbRangeMinHeightAtr * atr)
     {
      reason = "TOO_NARROW";
      return(false);
     }

   if(height > InpRbRangeMaxHeightAtr * atr)
     {
      reason = "TOO_WIDE";
      return(false);
     }

   double tol = InpRbRangeTouchTolAtr * atr;

   touchH = 0;
   touchL = 0;

   for(int i = 0; i < count; i++)
     {
      if(highs[i] >= hi - tol)
         touchH++;
      if(lows[i] <= lo + tol)
         touchL++;
     }

   if(touchH < InpRbRangeMinTouches || touchL < InpRbRangeMinTouches)
     {
      reason = "FEW_TOUCHES";
      return(false);
     }

   reason = "OK";
   return(true);
  }

//--- อัปเดตกรอบเมื่อเกิดแท่งใหม่ คืน false = ข้อมูลยังไม่พร้อม ให้ลองใหม่
bool RbRangeUpdate(const ENUM_RB_REGIME regime)
  {
   double atr = 0.0;

   if(!RbReadAtr(1, atr))
      return(false);

   //--- ไม่ใช่ RANGE: ปลดล็อกและล้างกรอบ
   if(regime != RB_REGIME_RANGE)
     {
      if(g_rbRange.locked)
         Print(CORE_LOG_PREFIX, " RANGE UNLOCK | NOT_RANGE | Regime=", RbRegimeText(regime));

      RbRangeClear();
      g_rbRange.atr    = atr;
      g_rbRange.reason = "NOT_RANGE";
      return(true);
     }

   //--- กรอบล็อกอยู่: ตรวจเงื่อนไขปลดล็อก (ปิดนอกกรอบเกิน 0.5 ATR / ครบ Lookback แท่ง)
   if(InpRbUseRangeLock && g_rbRange.locked)
     {
      double c[];
      ArraySetAsSeries(c, true);

      if(CopyClose(_Symbol, InpRbEntryTF, 1, 1, c) != 1)
         return(false);

      string why = "";

      if(c[0] > g_rbRange.high + 0.5 * atr)
         why = "BREAK_UP";
      else if(c[0] < g_rbRange.low - 0.5 * atr)
         why = "BREAK_DOWN";
      else if(g_rbRange.lockBars + 1 >= InpRbRangeLookback)
         why = "LOCK_EXPIRED";

      if(why == "")
        {
         g_rbRange.lockBars++;
         g_rbRange.atr    = atr;
         g_rbRange.valid  = true;
         g_rbRange.reason = "LOCKED";
         return(true);
        }

      Print(CORE_LOG_PREFIX, " RANGE UNLOCK | ", why,
            " | High=", DoubleToString(g_rbRange.high, _Digits),
            " Low=", DoubleToString(g_rbRange.low, _Digits));

      RbRangeClear();
     }

   //--- หากรอบใหม่
   double hi = 0.0;
   double lo = 0.0;
   int    th = 0;
   int    tl = 0;
   string reason = "";

   bool ok = RbRangeDetect(atr, hi, lo, th, tl, reason);

   if(!ok && reason == "NO_DATA")
      return(false);

   RbRangeClear();
   g_rbRange.atr    = atr;
   g_rbRange.reason = reason;

   if(!ok)
      return(true);

   g_rbRange.valid     = true;
   g_rbRange.locked    = InpRbUseRangeLock;
   g_rbRange.high      = hi;
   g_rbRange.low       = lo;
   g_rbRange.height    = hi - lo;
   g_rbRange.touchHigh = th;
   g_rbRange.touchLow  = tl;
   g_rbRange.lockBars  = 0;

   Print(CORE_LOG_PREFIX, " RANGE FOUND", (InpRbUseRangeLock ? " + LOCK" : ""),
         " | Low=", DoubleToString(lo, _Digits),
         " High=", DoubleToString(hi, _Digits),
         " | H/ATR=", DoubleToString(g_rbRange.height / atr, 2),
         " | Touch H/L=", th, "/", tl);

   return(true);
  }

//--- ปุ่ม RESET RANGE: ปลดล็อกและบังคับหากรอบใหม่ใน Tick ถัดไป (ไม่ปิดไม้ ไม่แตะทุน)
void RbRangeResetRequest()
  {
   Print(CORE_LOG_PREFIX, " RESET RANGE | ปลดล็อกกรอบและหากรอบใหม่ใน Tick ถัดไป");
   RbRangeClear();
   g_rbForceUpdate = true;
  }

void RbHLine(const string name, const double price, const color clr)
  {
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);

   ObjectSetDouble(0, name, OBJPROP_PRICE, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
  }

void RbDrawRange()
  {
   if(!InpRbDrawRange || !g_rbRange.valid)
     {
      ObjectDelete(0, RB_OBJ_HI);
      ObjectDelete(0, RB_OBJ_LO);
      return;
     }

   RbHLine(RB_OBJ_HI, g_rbRange.high, clrTomato);
   RbHLine(RB_OBJ_LO, g_rbRange.low,  clrDodgerBlue);
   ChartRedraw();
  }

#endif // RANGEBOT_RANGE_MQH