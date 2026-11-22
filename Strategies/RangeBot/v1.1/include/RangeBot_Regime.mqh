//+------------------------------------------------------------------+
//|                                              RangeBot_Regime.mqh |
//|  สภาพตลาด (Regime): RANGE / TREND_UP / TREND_DOWN / NEUTRAL      |
//|  คำนวณเมื่อเกิดแท่งใหม่ จากแท่งที่ปิดแล้ว (shift 1 ขึ้นไป)          |
//|  ต้อง include หลัง RangeBot_Inputs.mqh                            |
//|  หมายเหตุ: กฎใน RbClassify() เป็นข้อเสนอ รอยืนยันกับ Trend Bot    |
//+------------------------------------------------------------------+
#ifndef RANGEBOT_REGIME_MQH
#define RANGEBOT_REGIME_MQH

enum ENUM_RB_REGIME
  {
   RB_REGIME_UNKNOWN    = 0,
   RB_REGIME_RANGE      = 1,
   RB_REGIME_TREND_UP   = 2,
   RB_REGIME_TREND_DOWN = 3,
   RB_REGIME_NEUTRAL    = 4
  };

int g_rbAdxH  = INVALID_HANDLE;
int g_rbBbH   = INVALID_HANDLE;
int g_rbEmaFH = INVALID_HANDLE;
int g_rbEmaMH = INVALID_HANDLE;
int g_rbEmaSH = INVALID_HANDLE;

double g_rbAdxBuf[];
double g_rbMidBuf[];
double g_rbUpBuf[];
double g_rbLoBuf[];
double g_rbEfBuf[];
double g_rbEmBuf[];
double g_rbEsBuf[];

ENUM_RB_REGIME g_rbRegime    = RB_REGIME_UNKNOWN;   // สถานะที่ยืนยันแล้ว
ENUM_RB_REGIME g_rbRegimeRaw = RB_REGIME_UNKNOWN;   // ผลของแท่งล่าสุด (ก่อนยืนยัน)
double         g_rbAdx       = 0.0;                 // ADX ของแท่ง shift 1
double         g_rbBbwRatio  = 0.0;                 // BBW / ค่าเฉลี่ย ของแท่ง shift 1

string RbRegimeText(ENUM_RB_REGIME r)
  {
   switch(r)
     {
      case RB_REGIME_RANGE:      return("RANGE");
      case RB_REGIME_TREND_UP:   return("TREND_UP");
      case RB_REGIME_TREND_DOWN: return("TREND_DOWN");
      case RB_REGIME_NEUTRAL:    return("NEUTRAL");
     }
   return("UNKNOWN");
  }

void RbReleaseHandle(int &h)
  {
   if(h != INVALID_HANDLE)
     {
      IndicatorRelease(h);
      h = INVALID_HANDLE;
     }
  }

void RbRegimeDeinit()
  {
   RbReleaseHandle(g_rbAdxH);
   RbReleaseHandle(g_rbBbH);
   RbReleaseHandle(g_rbEmaFH);
   RbReleaseHandle(g_rbEmaMH);
   RbReleaseHandle(g_rbEmaSH);
  }

bool RbRegimeInit()
  {
   g_rbAdxH  = iADX(_Symbol, InpRbEntryTF, InpRbAdxPeriod);
   g_rbBbH   = iBands(_Symbol, InpRbEntryTF, InpRbBbPeriod, 0, InpRbBbDev, PRICE_CLOSE);
   g_rbEmaFH = iMA(_Symbol, InpRbEntryTF, InpRbEmaFast, 0, MODE_EMA, PRICE_CLOSE);
   g_rbEmaMH = iMA(_Symbol, InpRbEntryTF, InpRbEmaMid,  0, MODE_EMA, PRICE_CLOSE);
   g_rbEmaSH = iMA(_Symbol, InpRbEntryTF, InpRbEmaSlow, 0, MODE_EMA, PRICE_CLOSE);

   if(g_rbAdxH == INVALID_HANDLE || g_rbBbH == INVALID_HANDLE
      || g_rbEmaFH == INVALID_HANDLE || g_rbEmaMH == INVALID_HANDLE
      || g_rbEmaSH == INVALID_HANDLE)
     {
      Alert(CORE_LOG_PREFIX, " สร้าง Indicator ของ Regime ไม่สำเร็จ | error=", GetLastError());
      RbRegimeDeinit();
      return(false);
     }

   g_rbRegime    = RB_REGIME_UNKNOWN;
   g_rbRegimeRaw = RB_REGIME_UNKNOWN;
   return(true);
  }

//--- คัดลอก Buffer แบบ Series (index 0 = แท่งปัจจุบัน, 1 = แท่งที่ปิดล่าสุด)
bool RbCopyBuf(int handle, int buffer, int count, double &arr[])
  {
   ArraySetAsSeries(arr, true);
   int got = CopyBuffer(handle, buffer, 0, count, arr);
   return(got == count);
  }

//--- จัดกลุ่มแท่ง shift s (ใช้ Buffer ที่คัดลอกไว้แล้ว) | UNKNOWN = ข้อมูลไม่พอ
ENUM_RB_REGIME RbClassify(const int s, double &ratio)
  {
   ratio = 0.0;

   int    n   = InpRbBbwAvgPeriod;
   double sum = 0.0;

   for(int k = 0; k < n; k++)
     {
      int i = s + k;

      if(g_rbMidBuf[i] <= 0.0)
         return(RB_REGIME_UNKNOWN);

      sum += (g_rbUpBuf[i] - g_rbLoBuf[i]) / g_rbMidBuf[i];
     }

   double avg = sum / n;

   if(avg <= 0.0)
      return(RB_REGIME_UNKNOWN);

   ratio = ((g_rbUpBuf[s] - g_rbLoBuf[s]) / g_rbMidBuf[s]) / avg;

   bool rising = true;

   for(int k = 0; k < InpRbAdxRisingBars; k++)
     {
      if(!(g_rbAdxBuf[s + k] > g_rbAdxBuf[s + k + 1]))
        {
         rising = false;
         break;
        }
     }

   bool emaUp   = (g_rbEfBuf[s] > g_rbEmBuf[s] && g_rbEmBuf[s] > g_rbEsBuf[s]);
   bool emaDown = (g_rbEfBuf[s] < g_rbEmBuf[s] && g_rbEmBuf[s] < g_rbEsBuf[s]);

   if(g_rbAdxBuf[s] >= InpRbAdxTrendMin && rising)
     {
      if(emaUp)
         return(RB_REGIME_TREND_UP);
      if(emaDown)
         return(RB_REGIME_TREND_DOWN);
     }

   if(g_rbAdxBuf[s] <= InpRbAdxRangeMax && ratio <= InpRbSqueezeFactor)
      return(RB_REGIME_RANGE);

   return(RB_REGIME_NEUTRAL);
  }

//--- อัปเดต Regime (เรียกเมื่อเกิดแท่งใหม่) คืน false = ข้อมูลยังไม่พร้อม ให้ลองใหม่
bool RbRegimeUpdate()
  {
   int c    = InpRbRegimeConfirmBars;
   int nAdx = InpRbAdxRisingBars + c + 2;
   int nBb  = InpRbBbwAvgPeriod + c + 2;
   int nEma = c + 2;

   if(!RbCopyBuf(g_rbAdxH, 0, nAdx, g_rbAdxBuf)
      || !RbCopyBuf(g_rbBbH, 0, nBb, g_rbMidBuf)
      || !RbCopyBuf(g_rbBbH, 1, nBb, g_rbUpBuf)
      || !RbCopyBuf(g_rbBbH, 2, nBb, g_rbLoBuf)
      || !RbCopyBuf(g_rbEmaFH, 0, nEma, g_rbEfBuf)
      || !RbCopyBuf(g_rbEmaMH, 0, nEma, g_rbEmBuf)
      || !RbCopyBuf(g_rbEmaSH, 0, nEma, g_rbEsBuf))
      return(false);

   ENUM_RB_REGIME first      = RB_REGIME_UNKNOWN;
   double         ratioFirst = 0.0;
   bool           same       = true;

   for(int s = 1; s <= c; s++)
     {
      double ratio = 0.0;
      ENUM_RB_REGIME r = RbClassify(s, ratio);

      if(r == RB_REGIME_UNKNOWN)
         return(false);

      if(s == 1)
        {
         first      = r;
         ratioFirst = ratio;
        }
      else if(r != first)
         same = false;
     }

   g_rbRegimeRaw = first;
   g_rbAdx       = g_rbAdxBuf[1];
   g_rbBbwRatio  = ratioFirst;

   ENUM_RB_REGIME next = g_rbRegime;

   if(same)
      next = first;
   else if(g_rbRegime == RB_REGIME_UNKNOWN)
      next = RB_REGIME_NEUTRAL;

   if(next != g_rbRegime)
     {
      Print(CORE_LOG_PREFIX, " REGIME ", RbRegimeText(g_rbRegime),
            " -> ", RbRegimeText(next),
            " | ADX=", DoubleToString(g_rbAdx, 1),
            " | BBWr=", DoubleToString(g_rbBbwRatio, 2));
      g_rbRegime = next;
     }

   return(true);
  }

#endif // RANGEBOT_REGIME_MQH