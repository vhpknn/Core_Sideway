//+------------------------------------------------------------------+
//|                                                 Core_Capital.mqh |
//|  Virtual Capital + สูตรบันได Lot + REFILL + หยุดเมื่อทุนหมด      |
//|  ที่มา: Hedge1_Capital.mqh (dcf4a12) ย้ายโดยไม่แก้ตรรกะ          |
//+------------------------------------------------------------------+
#ifndef CORE_CAPITAL_MQH
#define CORE_CAPITAL_MQH

#include "Core_Inputs.mqh"
#include "Core_Utils.mqh"

//--- ชื่อตัวแปรถาวรของ Terminal ใช้เก็บยอด REFILL สะสม (กันหายเวลารีสตาร์ท EA)
string RefillGVName()
  {
   return(CoreStateGVName("REFILL"));
  }

//--- อ่านตัวเลข State ของทุน (ไม่มี/ผิดปกติ = 0)
double CapitalStateGet(string suffix)
  {
   string name = CoreStateGVName(suffix);

   if(!GlobalVariableCheck(name))
      return(0.0);

   double v = 0.0;

   if(!GlobalVariableGet(name, v)
      || !MathIsValidNumber(v)
      || v < 0.0)
      return(0.0);

   return(v);
  }

//--- เพิ่มค่าให้ State ของทุน (ใช้กับตัวนับครั้งและยอด RESET)
bool CapitalStateAdd(string suffix, double delta)
  {
   double v = CapitalStateGet(suffix);

   ResetLastError();

   if(GlobalVariableSet(CoreStateGVName(suffix), v + delta) == 0)
     {
      Print(CORE_LOG_PREFIX, " State บันทึกไม่สำเร็จ | ", suffix,
            " | error=", GetLastError());
      return(false);
     }

   return(true);
  }

//+------------------------------------------------------------------+
//| สถิติ Lock Profit: คิดผลสุทธิ "ต่อไม้ (Position)" แล้วแยกบวก/ลบ   |
//|   profit = ผลรวมของไม้ที่สุทธิเป็นบวก (กำไรที่ Lock)               |
//|   loss   = ผลรวมของไม้ที่สุทธิเป็นลบ (ค่าติดลบ)                    |
//| เก็บแคชไว้ คำนวณใหม่เฉพาะเมื่อจำนวนดีลในประวัติเปลี่ยน             |
//+------------------------------------------------------------------+
bool TryGetLockStats(double &profit, double &loss)
  {
   profit = 0.0;
   loss = 0.0;

   static int    s_total  = -1;
   static long   s_magic  = -1;
   static string s_symbol = "";
   static double s_profit = 0.0;
   static double s_loss   = 0.0;

   if(!HistorySelect(0, TimeCurrent() + 60))
     {
      Print(CORE_LOG_PREFIX, " HistorySelect ล้มเหลว (Lock) error=",
            GetLastError());
      return(false);
     }

   int total = HistoryDealsTotal();

   if(total == s_total && s_magic == InpMagicNumber && s_symbol == _Symbol)
     {
      profit = s_profit;
      loss = s_loss;
      return(true);
     }

   ulong  ids[];
   double nets[];
   int    count = 0;

   for(int i = 0; i < total; i++)
     {
      ulong ticket = HistoryDealGetTicket(i);

      if(ticket == 0)
         return(false);

      long magic = 0;
      long posId = 0;
      string symbol = "";

      if(!HistoryDealGetInteger(ticket, DEAL_MAGIC, magic)
         || !HistoryDealGetString(ticket, DEAL_SYMBOL, symbol)
         || !HistoryDealGetInteger(ticket, DEAL_POSITION_ID, posId))
         return(false);

      if(magic != InpMagicNumber || symbol != _Symbol)
         continue;

      double p = 0.0;
      double sw = 0.0;
      double cm = 0.0;

      if(!HistoryDealGetDouble(ticket, DEAL_PROFIT, p)
         || !HistoryDealGetDouble(ticket, DEAL_SWAP, sw)
         || !HistoryDealGetDouble(ticket, DEAL_COMMISSION, cm))
         return(false);

      double v = p + sw + cm;

      if(!MathIsValidNumber(v))
         return(false);

      int idx = -1;

      for(int j = 0; j < count; j++)
        {
         if(ids[j] == (ulong)posId)
           {
            idx = j;
            break;
           }
        }

      if(idx < 0)
        {
         ArrayResize(ids, count + 1, 64);
         ArrayResize(nets, count + 1, 64);
         ids[count] = (ulong)posId;
         nets[count] = 0.0;
         idx = count;
         count++;
        }

      nets[idx] += v;
     }

   for(int j = 0; j < count; j++)
     {
      if(nets[j] > 0.0)
         profit += nets[j];
      else if(nets[j] < 0.0)
         loss += nets[j];
     }

   s_total = total;
   s_magic = InpMagicNumber;
   s_symbol = _Symbol;
   s_profit = profit;
   s_loss = loss;

   return(true);
  }

//+------------------------------------------------------------------+
//| กำไรขาดทุนสุทธิที่ปิดไปแล้ว (นับจากประวัติตาม Magic + คู่เงิน)     |
//| นับทุกดีลของบอทนี้ รวมค่าคอมมิชชั่น/สวอปฝั่งเปิดด้วย              |
//| เพื่อให้ยอด Virtual Equity ตรงกับเน็ตจริงที่เกิดกับบัญชี           |
//+------------------------------------------------------------------+
bool TryGetClosedNet(double &net)
  {
   net = 0.0;

   if(!HistorySelect(0, TimeCurrent() + 60))
     {
      Print(CORE_LOG_PREFIX, " HistorySelect ล้มเหลว error=",
            GetLastError());
      return(false);
     }

   int total = HistoryDealsTotal();

   for(int i = 0; i < total; i++)
     {
      ulong ticket = HistoryDealGetTicket(i);

      if(ticket == 0)
        {
         Print(CORE_LOG_PREFIX, " อ่าน History Deal ไม่สำเร็จ",
               " | index=", i,
               " | error=", GetLastError());
         net = 0.0;
         return(false);
        }

      long magic = 0;
      string symbol = "";

      if(!HistoryDealGetInteger(ticket, DEAL_MAGIC, magic)
         || !HistoryDealGetString(ticket, DEAL_SYMBOL, symbol))
        {
         Print(CORE_LOG_PREFIX, " อ่าน Closed Deal Identity ไม่สำเร็จ",
               " | Deal=", ticket,
               " | error=", GetLastError());
         net = 0.0;
         return(false);
        }

      if(magic != InpMagicNumber || symbol != _Symbol)
         continue;

      double profit = 0.0;
      double swap = 0.0;
      double commission = 0.0;

      if(!HistoryDealGetDouble(ticket, DEAL_PROFIT, profit)
         || !HistoryDealGetDouble(ticket, DEAL_SWAP, swap)
         || !HistoryDealGetDouble(ticket, DEAL_COMMISSION, commission))
        {
         Print(CORE_LOG_PREFIX, " อ่าน Closed Deal Values ไม่สำเร็จ",
               " | Deal=", ticket,
               " | error=", GetLastError());
         net = 0.0;
         return(false);
        }

      if(!MathIsValidNumber(profit)
         || !MathIsValidNumber(swap)
         || !MathIsValidNumber(commission))
        {
         Print(CORE_LOG_PREFIX, " Closed Deal Values ไม่ถูกต้อง",
               " | Deal=", ticket);
         net = 0.0;
         return(false);
        }

      net += profit + swap + commission;
     }

   if(!MathIsValidNumber(net))
     {
      Print(CORE_LOG_PREFIX, " Closed Net ไม่ถูกต้อง");
      net = 0.0;
      return(false);
     }

   return(true);
  }

double GetClosedNet()
  {
   double net = 0.0;

   if(!TryGetClosedNet(net))
      return(0.0);

   return(net);
  }

//+------------------------------------------------------------------+
//| ยอด REFILL สะสมทั้งหมด (อ่านจาก Terminal Global Variable)         |
//+------------------------------------------------------------------+
bool TryGetTotalRefill(double &total)
  {
   total = 0.0;
   string name = RefillGVName();

   //--- ไม่มี Key หมายถึงยังไม่มียอด REFILL
   if(!GlobalVariableCheck(name))
      return(true);

   if(!GlobalVariableGet(name, total)
      || !MathIsValidNumber(total)
      || total < 0.0)
     {
      Print(CORE_LOG_PREFIX, " REFILL State อ่านไม่ได้หรือไม่ถูกต้อง");
      total = 0.0;
      return(false);
     }

   return(true);
  }

double GetTotalRefill()
  {
   double total = 0.0;

   if(!TryGetTotalRefill(total))
      return(0.0);

   return(total);
  }

//+------------------------------------------------------------------+
//| กดปุ่ม REFILL หนึ่งครั้ง = เติมทุนเสมือนตามค่า InpRefillAmount     |
//+------------------------------------------------------------------+
bool AddRefill()
  {
   double previous = 0.0;

   if(!TryGetTotalRefill(previous))
     {
      Print(CORE_LOG_PREFIX, " REFILL FAILED",
            " | Existing state unavailable");
      return(false);
     }

   if(!MathIsValidNumber(InpRefillAmount)
      || InpRefillAmount <= 0.0)
     {
      Print(CORE_LOG_PREFIX, " REFILL FAILED",
            " | Invalid refill amount");
      return(false);
     }

   double total = previous + InpRefillAmount;

   if(!MathIsValidNumber(total) || total < 0.0)
     {
      Print(CORE_LOG_PREFIX, " REFILL FAILED",
            " | Invalid total");
      return(false);
     }

   ResetLastError();

   if(GlobalVariableSet(RefillGVName(), total) == 0)
     {
      Print(CORE_LOG_PREFIX, " REFILL FAILED",
            " | Save error=", GetLastError());
      return(false);
     }

   GlobalVariablesFlush();

   //--- นับจำนวนครั้งที่ REFILL (ใช้แสดงสถานะ ไม่มีผลกับยอดทุน)
   CapitalStateAdd("RFCNT", 1.0);

   return(true);
  }

//+------------------------------------------------------------------+
//| ทุนเสมือนปัจจุบัน = ทุนเริ่มต้น + REFILL สะสม + กำไรขาดทุนที่ปิดแล้ว|
//| (ไม่รวมกำไรลอยตัว ตรงกับตัวเลขบน Panel ตาม Blueprint)             |
//+------------------------------------------------------------------+
bool TryGetVirtualEquity(double &equity)
  {
   equity = 0.0;

   double refill = 0.0;
   double closedNet = 0.0;

   if(!TryGetTotalRefill(refill))
      return(false);

   double resetTotal = CapitalStateGet("RESET");

   if(InpLockProfit)
     {
      //--- Lock Profit: ทุนเทรด = ทุนเริ่มต้น + เติม + ขาดทุนสะสม (กำไรไม่เข้าทุน)
      double lockProfit = 0.0;
      double lockLoss = 0.0;

      if(!TryGetLockStats(lockProfit, lockLoss))
         return(false);

      closedNet = lockLoss;
     }
   else
     {
      if(!TryGetClosedNet(closedNet))
         return(false);
     }

   equity = InpInitialCapital + refill + resetTotal + closedNet;

   if(!MathIsValidNumber(equity))
     {
      Print(CORE_LOG_PREFIX, " Virtual Equity ไม่ถูกต้อง");
      equity = 0.0;
      return(false);
     }

   return(true);
  }

double GetVirtualEquity()
  {
   double equity = 0.0;

   if(!TryGetVirtualEquity(equity))
      return(0.0);

   return(equity);
  }

//--- สถิติสำหรับแสดงสถานะ (Panel เรียกใช้ใน PHASE B2)
int    GetRefillCount() { return((int)MathRound(CapitalStateGet("RFCNT"))); }
int    GetResetCount()  { return((int)MathRound(CapitalStateGet("RSCNT"))); }
double GetTotalReset()  { return(CapitalStateGet("RESET")); }

//+------------------------------------------------------------------+
//| RESET: เติมทุนเทรดให้กลับเท่าทุนเริ่มต้นในครั้งเดียว               |
//| เติมเฉพาะส่วนที่ขาด (ทุนเริ่มต้น - ทุนปัจจุบัน) ถ้าไม่ขาดจะไม่ทำ   |
//+------------------------------------------------------------------+
bool DoCapitalReset()
  {
   double equity = 0.0;

   if(!TryGetVirtualEquity(equity))
     {
      Print(CORE_LOG_PREFIX, " RESET FAILED | อ่านทุนไม่ได้");
      return(false);
     }

   double need = InpInitialCapital - equity;

   if(!MathIsValidNumber(need) || need <= 0.0000001)
     {
      Print(CORE_LOG_PREFIX, " RESET SKIPPED | ทุนไม่ต่ำกว่าทุนเริ่มต้น",
            " | Equity=$", DoubleToString(equity, 2));
      return(false);
     }

   if(!CapitalStateAdd("RESET", need))
      return(false);

   CapitalStateAdd("RSCNT", 1.0);
   GlobalVariablesFlush();

   double after = 0.0;
   TryGetVirtualEquity(after);

   Print(CORE_LOG_PREFIX, " RESET SAVED +$", DoubleToString(need, 2),
         " | Virtual Equity=$", DoubleToString(after, 2),
         " | Reset ", GetResetCount(), " ครั้ง");

   return(true);
  }

//+------------------------------------------------------------------+
//| ปรับขนาด Lot ให้อยู่ในกฎของโบรกเกอร์ (min / max / step)            |
//+------------------------------------------------------------------+
double NormalizeVolume(double lot)
  {
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(!MathIsValidNumber(lot)
      || !MathIsValidNumber(minLot)
      || !MathIsValidNumber(maxLot)
      || !MathIsValidNumber(step)
      || lot <= 0.0
      || minLot <= 0.0
      || maxLot < minLot
      || step <= 0.0)
      return(0.0);

   lot = MathMax(minLot, MathMin(lot, maxLot));

   double units = lot / step;

   if(!MathIsValidNumber(units))
      return(0.0);

   units = MathFloor(units + 0.000000001);

   double normalized = NormalizeDouble(units * step, 8);

   if(normalized < minLot)
      normalized = NormalizeDouble(minLot, 8);

   if(normalized <= 0.0 || normalized > maxLot + 0.00000001)
      return(0.0);

   //--- ถ้าปริมาณที่ได้ไม่ตรง Step ให้ปฏิเสธแทนการส่งค่าผิด
   double checkUnits = normalized / step;

   if(!MathIsValidNumber(checkUnits)
      || MathAbs(checkUnits - MathRound(checkUnits)) > 0.0000001)
      return(0.0);

   return(normalized);
  }

//+------------------------------------------------------------------+
//| สูตรบันได Lot (คำนวณทุกครั้งที่ต้องการใช้ ขยับได้ทั้งขึ้น-ลง)        |
//|   step      = floor(ทุนรวม ÷ InpLotStepMoney)  ปัดเศษทิ้ง          |
//|   Lot       = InpBaseLot + (step - 1) x InpLotIncrement            |
//|   เพดาน     = InpMaxLotStep x InpLotIncrement (ค่า 0 = ไม่จำกัด)   |
//| ตัวอย่าง: ทุน 50=0.01 / 120=0.02 / 230=0.04 / เกิน300=หั่นเหลือ0.04 |
//+------------------------------------------------------------------+
double GetEffectiveLotForEquity(double equity)
  {
   if(!MathIsValidNumber(equity) || equity <= 0.0)
      return(0.0);

   if(!InpAutoLot)
      return(NormalizeVolume(InpBaseLot));

   if(InpLotStepMoney <= 0.0 || InpLotIncrement <= 0.0)
      return(0.0);

   double steps = MathFloor(equity / InpLotStepMoney);

   if(!MathIsValidNumber(steps))
      return(0.0);

   if(steps < 1.0)
      steps = 1.0;

   double lot = InpBaseLot + (steps - 1.0) * InpLotIncrement;

   if(!MathIsValidNumber(lot) || lot <= 0.0)
      return(0.0);

   double cap = 0.0;

   if(InpMaxLotStep > 0)
     {
      cap = InpMaxLotStep * InpLotIncrement;
      lot = MathMin(lot, cap);
     }

   double normalized = NormalizeVolume(lot);

   if(normalized <= 0.0)
      return(0.0);

   //--- ห้าม Broker minimum ดัน Lot เกินเพดาน Auto-Lot ที่กำหนด
   if(cap > 0.0 && normalized > cap + 0.00000001)
      return(0.0);

   return(normalized);
  }

double GetEffectiveLot()
  {
   double equity = 0.0;

   if(!TryGetVirtualEquity(equity))
      return(0.0);

   return(GetEffectiveLotForEquity(equity));
  }

//+------------------------------------------------------------------+
//| กติกาหยุด: ทุนเสมือนติดลบ/เหลือ $0 = หยุดเปิดไม้ใหม่ รอกด REFILL    |
//+------------------------------------------------------------------+
bool IsCapitalDead()
  {
   double equity = 0.0;

   //--- Fail-closed: ไม่อนุญาตเปิดเพิ่มเมื่ออ่านทุนไม่ได้
   if(!TryGetVirtualEquity(equity))
      return(true);

   return(equity <= 0.0);
  }

#endif // CORE_CAPITAL_MQH