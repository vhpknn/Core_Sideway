//+------------------------------------------------------------------+
//|                                                  Core_Utils.mqh  |
//|  ไม้บรรทัดกลาง: หน่วย Point ตามทศนิยม Broker + สเปรด             |
//|  + ตัวช่วยแปลงค่า/จัดรูปแบบข้อความสำหรับทุกโมดูล                  |
//|  ที่มา: Hedge1_Utils.mqh (dcf4a12) ตัด Legacy Import (D-01)      |
//+------------------------------------------------------------------+
#ifndef CORE_UTILS_MQH
#define CORE_UTILS_MQH

#include "Core_Inputs.mqh"

//--- คำนำหน้า Log ของ Core (EA กำหนดเองก่อน include ได้)
#ifndef CORE_LOG_PREFIX
   #define CORE_LOG_PREFIX "Core:"
#endif

//--- State เงิน/รายงานไม่ผูก Point Digits เพราะไม่ได้เก็บระยะราคา
//--- รูปแบบ: <TAG>S_<บัญชี>_<Symbol>_<Magic>_<ชื่อ>
string CoreStateGVName(string suffix)
  {
   return(STRATEGY_TAG
          + "S_"
          + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN))
          + "_"
          + _Symbol
          + "_"
          + IntegerToString(InpMagicNumber)
          + "_"
          + suffix);
  }

bool CoreStateInit()
  {
   //--- ตรวจความยาว Key ทุกตัว (CSTART เพิ่มใหม่ ตรวจเฉพาะความยาว)
   string keySuffixes[] = {"REFILL", "RPD", "RNET", "CSTART", "PAUSE",
                           "RFCNT", "RESET", "RSCNT", "LOCK"};

   //--- ตรวจค่าเฉพาะ State ที่เดิมตรวจอยู่แล้ว
   string valueSuffixes[] = {"REFILL", "RPD", "RNET"};

   for(int i = 0; i < ArraySize(keySuffixes); i++)
     {
      string name = CoreStateGVName(keySuffixes[i]);

      if(StringLen(name) > 63)
        {
         Alert(CORE_LOG_PREFIX, " State Key ยาวเกิน 63 ตัวอักษร: ", name);
         return(false);
        }
     }

   for(int i = 0; i < ArraySize(valueSuffixes); i++)
     {
      string name = CoreStateGVName(valueSuffixes[i]);

      //--- ยังไม่มี State: ปล่อยให้โมดูลเจ้าของสร้างเอง
      if(!GlobalVariableCheck(name))
         continue;

      double value = 0.0;

      if(!GlobalVariableGet(name, value)
         || !MathIsValidNumber(value))
        {
         Alert(CORE_LOG_PREFIX, " อ่าน State ไม่สำเร็จหรือค่าไม่ถูกต้อง: ",
               name);
         return(false);
        }

      //--- REFILL ต้องไม่ติดลบ
      if(valueSuffixes[i] == "REFILL" && value < 0.0)
        {
         Alert(CORE_LOG_PREFIX, " REFILL State ต้องไม่ติดลบ");
         return(false);
        }

      //--- วันเริ่มรอบรายงานต้องมากกว่า 0
      if(valueSuffixes[i] == "RPD" && value <= 0.0)
        {
         Alert(CORE_LOG_PREFIX, " Report State ไม่ถูกต้อง");
         return(false);
        }

      //--- RNET เป็นยอดสุทธิ จึงติดลบได้
      //--- ฐาน Cycle ใหม่ถูกกำหนดโดย Engine ก่อนส่ง Order
     }

   return(true);
  }

//+------------------------------------------------------------------+
//| ขนาด 1 Point ตามทศนิยมที่ผู้ใช้กำหนด (InpPointDigits)             |
//| เช่น ตั้ง 2 ตำแหน่ง = 1 Point เท่ากับ 0.01 (ราคาทอง)             |
//| ทำให้ "1000 Points" หมายถึงราคาเคลื่อน $10.00 เสมอ               |
//| ไม่สนว่าโบรกเกอร์ quote กี่หลัก                                  |
//+------------------------------------------------------------------+
double CorePoint()
  {
   int digits = InpPointDigits;
   if(digits < 0)
      digits = 0;
   if(digits > 8)
      digits = 8;
   return(MathPow(10.0, -digits));
  }

//+------------------------------------------------------------------+
//| แปลงจำนวน Points เป็นระยะราคา (เช่น 1000 pts -> 10.00)           |
//+------------------------------------------------------------------+
double PointsToPrice(double points)
  {
   return(points * CorePoint());
  }

//+------------------------------------------------------------------+
//| แปลงระยะราคาเป็นจำนวน Points (เช่น 10.00 -> 1000 pts)             |
//+------------------------------------------------------------------+
double PriceToPoints(double priceDiff)
  {
   double pt = CorePoint();
   if(pt <= 0.0)
      return(0.0);
   return(priceDiff / pt);
  }

//+------------------------------------------------------------------+
//| สเปรดปัจจุบันเป็น Points (ตามหน่วยของ InpPointDigits)            |
//| Panel ใช้แสดง เช่น "45 / Trigger 25"                             |
//+------------------------------------------------------------------+
double GetSpreadPoints()
  {
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(ask <= 0.0 || bid <= 0.0)
     {
      Print(CORE_LOG_PREFIX, " อ่านราคา Ask/Bid ไม่ได้ error=", GetLastError());
      return(999999.0);   // ค่าสูงสุด = ไม่อนุญาตให้เปิดไม้ กันเปิดตอนราคาพัง
     }
   return(PriceToPoints(ask - bid));
  }

//+------------------------------------------------------------------+
//| จัดรูปแบบเงินสำหรับ Panel เช่น +$197.58 / -$75.07                 |
//+------------------------------------------------------------------+
string FormatMoney(double v)
  {
   string sign = (v >= 0.0) ? "+" : "-";
   double a = MathAbs(v);
   return(sign + "$" + DoubleToString(a, 2));
  }

//+------------------------------------------------------------------+
//| จัดรูปแบบ Points สำหรับ Panel เช่น 1000 pts / 0.04                 |
//+------------------------------------------------------------------+
string FormatPoints(double pts)
  {
   return(DoubleToString(pts, 0) + " pts");
  }

#endif // CORE_UTILS_MQH