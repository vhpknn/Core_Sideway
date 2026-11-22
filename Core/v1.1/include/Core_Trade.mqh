//+------------------------------------------------------------------+
//|                                                   Core_Trade.mqh |
//|  ส่งคำสั่งระดับต่ำ: ปิดไม้ / แก้ SL / ปิดทั้งฝั่ง + ตัวช่วยตรวจ    |
//|  ใช้ OrderSend ตรงทั้งหมด ไม่พึ่งไลบรารี CTrade (ใช้ได้ทุก MT5)  |
//|  ที่มา: แยกจาก Hedge1_Engine.mqh (dcf4a12) ไม่แก้ตรรกะ            |
//|  ใช้ร่วมกันโดย Core_Protect และ Core_Engine                       |
//+------------------------------------------------------------------+
#ifndef CORE_TRADE_MQH
#define CORE_TRADE_MQH

#include "Core_Inputs.mqh"
#include "Core_Utils.mqh"

//--- true = Engine เริ่มแล้ว (EngineInit ใน Core_Engine เป็นผู้ตั้งค่า)
bool g_engineReady = false;

//+------------------------------------------------------------------+
//| โหมด Filling ที่โบรกเกอร์รองรับ (ใช้ได้กับทุกเวอร์ชั่น MT5)      |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING GetSymbolFilling()
  {
   long fillFlags = SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if((fillFlags & SYMBOL_FILLING_FOK) != 0)
      return(ORDER_FILLING_FOK);
   if((fillFlags & SYMBOL_FILLING_IOC) != 0)
      return(ORDER_FILLING_IOC);
   return(ORDER_FILLING_RETURN);
  }

//+------------------------------------------------------------------+
//| ตรวจว่าคำสั่ง Trade ทำสำเร็จจริงที่ฝั่ง Server หรือไม่             |
//| หมายเหตุ: OrderSend=true แปลว่า Terminal ส่ง Request ได้           |
//| แต่ต้องตรวจ retcode ต่อ จึงจะรู้ว่า Broker ทำสำเร็จจริง             |
//+------------------------------------------------------------------+
bool IsTradeRetcodeDone(uint retcode)
  {
   return(retcode == TRADE_RETCODE_DONE);
  }

//+------------------------------------------------------------------+
//| ปิดไม้รายตัวด้วย ticket ผ่าน OrderSend ตรงๆ                        |
//+------------------------------------------------------------------+
bool RawPositionClose(ulong ticket, string tag)
  {
   if(!PositionSelectByTicket(ticket))
     {
      Print(CORE_LOG_PREFIX, " [", tag, "] ไม่พบไม้ #", ticket, " (ปิดไปแล้ว?)");
      return(false);
     }
   ENUM_POSITION_TYPE ptype = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   double volume = PositionGetDouble(POSITION_VOLUME);

   MqlTradeRequest req;
   MqlTradeResult  res;
   ZeroMemory(req);
   ZeroMemory(res);
   req.action       = TRADE_ACTION_DEAL;
   req.position     = ticket;
   req.symbol       = _Symbol;
   req.volume       = volume;
   req.deviation    = InpDeviationPoints;
   req.magic        = (ulong)InpMagicNumber;
   req.type_filling = GetSymbolFilling();
   req.type         = (ptype == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
   req.price        = (ptype == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                                                  : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   req.comment      = tag;

   if(!OrderSend(req, res))
     {
      Print(CORE_LOG_PREFIX, " [", tag, "] ส่งคำสั่งปิดไม้ #", ticket,
            " ล้มเหลว retcode=", res.retcode,
            " (", res.comment, ") error=", GetLastError());
      return(false);
     }

   //--- สำคัญ: OrderSend ผ่าน ไม่ได้แปลว่าปิดสำเร็จเสมอไป
   if(!IsTradeRetcodeDone(res.retcode))
     {
      Print(CORE_LOG_PREFIX, " [", tag, "] Broker ปฏิเสธ/ปิดไม่สมบูรณ์ #", ticket,
            " retcode=", res.retcode,
            " (", res.comment, ")",
            " | Position ยังต้องถือว่าเปิดอยู่");
      return(false);
     }

   Print(CORE_LOG_PREFIX, " [", tag, "] ปิดไม้ #", ticket,
         " สำเร็จจริง | ราคา=", DoubleToString(res.price, _Digits),
         " | volume=", DoubleToString(res.volume, 2));
   return(true);
  }

//+------------------------------------------------------------------+
//| แก้ SL/TP ของไม้ด้วย ticket ผ่าน OrderSend ตรงๆ                   |
//+------------------------------------------------------------------+
bool RawPositionModify(ulong ticket, double newSL, double keepTP, string tag)
  {
   MqlTradeRequest req;
   MqlTradeResult  res;
   ZeroMemory(req);
   ZeroMemory(res);
   req.action   = TRADE_ACTION_SLTP;
   req.position = ticket;
   req.symbol   = _Symbol;
   req.sl       = NormalizeDouble(newSL, _Digits);
   req.tp       = keepTP;

   if(!OrderSend(req, res))
     {
      Print(CORE_LOG_PREFIX, " [", tag, "] ส่งคำสั่งแก้ SL ไม้ #", ticket,
            " ล้มเหลว retcode=", res.retcode,
            " (", res.comment, ") error=", GetLastError());
      return(false);
     }

   //--- สำคัญ: ต้องตรวจว่าฝั่ง Broker ยอมแก้ SL จริง
   if(!IsTradeRetcodeDone(res.retcode))
     {
      Print(CORE_LOG_PREFIX, " [", tag, "] Broker ปฏิเสธการแก้ SL #", ticket,
            " retcode=", res.retcode,
            " (", res.comment, ")",
            " | SL เดิมยังอาจคงอยู่");
      return(false);
     }

   Print(CORE_LOG_PREFIX, " [", tag, "] แก้ SL สำเร็จจริง #", ticket,
         " | New SL=", DoubleToString(req.sl, _Digits));
   return(true);
  }

//+------------------------------------------------------------------+
//| ปิดไม้ทั้งหมดของฝั่งที่ระบุ (Magic + คู่เงิน) คืนจำนวนที่ปิดสำเร็จ |
//+------------------------------------------------------------------+
int CloseOneSide(ENUM_POSITION_TYPE dir, string tag)
  {
   if(!g_engineReady)
      return(0);
   int closed = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
         continue;
      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) != dir)
         continue;

      if(RawPositionClose(ticket, tag))
         closed++;
     }
   return(closed);
  }

//+------------------------------------------------------------------+
//| รวม Volume ของ Position ฝั่งที่ระบุ                               |
//| ใช้ตรวจว่า Lot จริงตรงกับ Lot ที่ระบบขอหรือไม่                     |
//+------------------------------------------------------------------+
double GetSideVolume(ENUM_POSITION_TYPE dir)
  {
   double totalVolume = 0.0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
         continue;

      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) != dir)
         continue;

      totalVolume += PositionGetDouble(POSITION_VOLUME);
     }

   return(totalVolume);
  }

//+------------------------------------------------------------------+
//| ตรวจว่า Volume ที่เปิดจริงตรงกับ Lot ที่ร้องขอหรือไม่              |
//+------------------------------------------------------------------+
bool IsLotMatched(double actualLot, double expectedLot)
  {
   double volumeStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(volumeStep <= 0.0)
      volumeStep = 0.01;

   //--- ยอมให้ต่างได้ไม่เกินครึ่งหนึ่งของ Volume Step
   return(MathAbs(actualLot - expectedLot) < volumeStep * 0.5);
  }

#endif // CORE_TRADE_MQH