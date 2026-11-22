//+------------------------------------------------------------------+
//|                                                 Core_Pending.mqh |
//|  ออเดอร์ค้าง (Pending) ระดับต่ำ: วาง / แก้ / ลบ / นับ (Core v1.1)  |
//|  ใช้ OrderSend ตรง ตรวจ retcode ถูกปฏิเสธ = คืนค่าล้มเหลว ไม่วนซ้ำ  |
//|  ตรวจ Stops Level, Freeze Level, Tick Size ก่อนส่ง                |
//|  ไม่แก้นิยาม Basket ของ Core (Basket ยังนับเฉพาะ Position)         |
//|  ต้อง include หลัง Core_Trade.mqh                                |
//+------------------------------------------------------------------+
#ifndef CORE_PENDING_MQH
#define CORE_PENDING_MQH

#include "Core_Inputs.mqh"
#include "Core_Utils.mqh"
#include "Core_Trade.mqh"

//--- ชนิดออเดอร์ค้างที่รองรับ (ไม่รวม STOP_LIMIT)
bool CoreIsPendingType(ENUM_ORDER_TYPE t)
  {
   return(t == ORDER_TYPE_BUY_LIMIT
          || t == ORDER_TYPE_SELL_LIMIT
          || t == ORDER_TYPE_BUY_STOP
          || t == ORDER_TYPE_SELL_STOP);
  }

bool CorePendingIsBuySide(ENUM_ORDER_TYPE t)
  {
   return(t == ORDER_TYPE_BUY_LIMIT || t == ORDER_TYPE_BUY_STOP);
  }

double CorePendingTick()
  {
   double t = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   if(t <= 0.0)
      t = _Point;

   return(t);
  }

//--- ปัดราคาตาม Tick Size ของโบรกเกอร์
double CorePendingNormalize(double price)
  {
   double t = CorePendingTick();
   return(NormalizeDouble(MathRound(price / t) * t, _Digits));
  }

//--- ระยะขั้นต่ำจากตลาด = Stops Level (อย่างน้อย 1 tick)
double CorePendingMinDistance()
  {
   long   lv = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double d  = (double)lv * _Point;

   return(MathMax(d, CorePendingTick()));
  }

//+------------------------------------------------------------------+
//| ราคา pending ต้องอยู่ถูกฝั่งและห่างตลาดไม่ต่ำกว่า Stops Level      |
//+------------------------------------------------------------------+
bool CorePendingCheckLevel(ENUM_ORDER_TYPE type, double price, string &reason)
  {
   reason = "";

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(ask <= 0.0 || bid <= 0.0 || price <= 0.0)
     {
      reason = "PRICE_UNAVAILABLE";
      return(false);
     }

   double minD = CorePendingMinDistance();
   double eps  = CorePendingTick() / 2.0;
   bool   ok   = false;

   switch(type)
     {
      case ORDER_TYPE_BUY_LIMIT:
         ok = (price <= ask - minD + eps);
         break;
      case ORDER_TYPE_SELL_LIMIT:
         ok = (price >= bid + minD - eps);
         break;
      case ORDER_TYPE_BUY_STOP:
         ok = (price >= ask + minD - eps);
         break;
      case ORDER_TYPE_SELL_STOP:
         ok = (price <= bid - minD + eps);
         break;
      default:
         reason = "NOT_PENDING_TYPE";
         return(false);
     }

   if(!ok)
      reason = "TOO_CLOSE_OR_WRONG_SIDE | price=" + DoubleToString(price, _Digits)
               + " ask=" + DoubleToString(ask, _Digits)
               + " bid=" + DoubleToString(bid, _Digits)
               + " minDistance=" + DoubleToString(minD, _Digits);

   return(ok);
  }

//--- SL ต้องอยู่ถูกฝั่งของราคา pending (0 = ไม่ใช้ SL)
bool CorePendingSlSideOk(ENUM_ORDER_TYPE type, double price, double sl)
  {
   if(sl <= 0.0)
      return(true);

   if(CorePendingIsBuySide(type))
      return(sl < price);

   return(sl > price);
  }

//+------------------------------------------------------------------+
//| วาง pending คืน ticket (0 = ไม่สำเร็จ)                             |
//| ส่ง SL ไปกับ pending ได้ (sl = 0 คือไม่ใส่) Lot ผู้เรียกคำนวณมาแล้ว |
//+------------------------------------------------------------------+
ulong RawPendingPlace(ENUM_ORDER_TYPE type, double lot, double price,
                      double sl, string tag)
  {
   if(!g_engineReady)
      return(0);

   if(!CoreIsPendingType(type))
     {
      Print(CORE_LOG_PREFIX, " [", tag, "] PENDING PLACE BLOCKED | ชนิดออเดอร์ไม่รองรับ");
      return(0);
     }

   price = CorePendingNormalize(price);

   if(sl > 0.0)
      sl = CorePendingNormalize(sl);

   string why = "";

   if(!CorePendingCheckLevel(type, price, why))
     {
      Print(CORE_LOG_PREFIX, " [", tag, "] PENDING PLACE BLOCKED | ", why);
      return(0);
     }

   if(!CorePendingSlSideOk(type, price, sl))
     {
      Print(CORE_LOG_PREFIX, " [", tag, "] PENDING PLACE BLOCKED | SL อยู่ผิดฝั่ง",
            " | price=", DoubleToString(price, _Digits),
            " sl=", DoubleToString(sl, _Digits));
      return(0);
     }

   //--- รอบแรกใช้ RETURN (ยืนยันแล้วจาก Probe) ถ้าโบรกเกอร์ไม่รับ ลอง Filling ของ Core 1 ครั้ง
   for(int attempt = 0; attempt < 2; attempt++)
     {
      MqlTradeRequest req;
      MqlTradeResult  res;
      ZeroMemory(req);
      ZeroMemory(res);

      req.action       = TRADE_ACTION_PENDING;
      req.symbol       = _Symbol;
      req.volume       = lot;
      req.type         = type;
      req.price        = price;
      req.sl           = sl;
      req.tp           = 0.0;
      req.type_filling = (attempt == 0) ? ORDER_FILLING_RETURN : GetSymbolFilling();
      req.type_time    = ORDER_TIME_GTC;
      req.magic        = (ulong)InpMagicNumber;
      req.comment      = InpTradeComment;

      ResetLastError();
      bool sent = OrderSend(req, res);

      if(attempt == 0 && res.retcode == TRADE_RETCODE_INVALID_FILL)
        {
         Print(CORE_LOG_PREFIX, " [", tag, "] PENDING Filling RETURN ไม่รับ ลอง Filling ของ Core");
         continue;
        }

      if(!sent || !IsTradeRetcodeDone(res.retcode))
        {
         Print(CORE_LOG_PREFIX, " [", tag, "] PENDING PLACE FAILED",
               " | retcode=", res.retcode, " (", res.comment, ")",
               " | error=", GetLastError(),
               " | price=", DoubleToString(price, _Digits),
               " sl=", DoubleToString(sl, _Digits));
         return(0);
        }

      Print(CORE_LOG_PREFIX, " [", tag, "] PENDING PLACED #", res.order,
            " | ", EnumToString(type),
            " | price=", DoubleToString(price, _Digits),
            " sl=", DoubleToString(sl, _Digits),
            " | lot=", DoubleToString(lot, 2));

      return(res.order);
     }

   return(0);
  }

//+------------------------------------------------------------------+
//| เลื่อน pending (ราคา + SL) คืน true เมื่อสำเร็จหรือไม่มีอะไรเปลี่ยน |
//+------------------------------------------------------------------+
bool RawPendingModify(ulong ticket, double newPrice, double newSL, string tag)
  {
   if(!g_engineReady)
      return(false);

   if(!OrderSelect(ticket))
     {
      Print(CORE_LOG_PREFIX, " [", tag, "] PENDING MODIFY BLOCKED | ไม่พบออเดอร์ #", ticket);
      return(false);
     }

   if(OrderGetString(ORDER_SYMBOL) != _Symbol
      || OrderGetInteger(ORDER_MAGIC) != InpMagicNumber)
     {
      Print(CORE_LOG_PREFIX, " [", tag, "] PENDING MODIFY BLOCKED | ออเดอร์ #", ticket,
            " ไม่ใช่ของ EA นี้");
      return(false);
     }

   ENUM_ORDER_TYPE type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);

   if(!CoreIsPendingType(type))
      return(false);

   double   curPrice = OrderGetDouble(ORDER_PRICE_OPEN);
   double   curSL    = OrderGetDouble(ORDER_SL);
   double   curTP    = OrderGetDouble(ORDER_TP);
   datetime expiry   = (datetime)OrderGetInteger(ORDER_TIME_EXPIRATION);
   ENUM_ORDER_TYPE_TIME timeType = (ENUM_ORDER_TYPE_TIME)OrderGetInteger(ORDER_TYPE_TIME);

   newPrice = CorePendingNormalize(newPrice);

   if(newSL > 0.0)
      newSL = CorePendingNormalize(newSL);

   double tick = CorePendingTick();

   //--- ไม่เปลี่ยนอะไร ไม่ต้องส่ง (Broker จะตอบ NO_CHANGES)
   if(MathAbs(newPrice - curPrice) < tick / 2.0
      && MathAbs(newSL - curSL) < tick / 2.0)
      return(true);

   //--- Freeze Level: pending เดิมอยู่ใกล้ตลาดเกินไป Broker ไม่ให้แก้
   long fz = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);

   if(fz > 0)
     {
      double ref  = CorePendingIsBuySide(type) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                                               : SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double dist = MathAbs(curPrice - ref);

      if(dist <= (double)fz * _Point)
        {
         Print(CORE_LOG_PREFIX, " [", tag, "] PENDING MODIFY BLOCKED #", ticket,
               " | อยู่ในช่วง Freeze Level | distance=", DoubleToString(dist, _Digits));
         return(false);
        }
     }

   string why = "";

   if(!CorePendingCheckLevel(type, newPrice, why))
     {
      Print(CORE_LOG_PREFIX, " [", tag, "] PENDING MODIFY BLOCKED #", ticket, " | ", why);
      return(false);
     }

   if(!CorePendingSlSideOk(type, newPrice, newSL))
     {
      Print(CORE_LOG_PREFIX, " [", tag, "] PENDING MODIFY BLOCKED #", ticket,
            " | SL อยู่ผิดฝั่ง");
      return(false);
     }

   MqlTradeRequest req;
   MqlTradeResult  res;
   ZeroMemory(req);
   ZeroMemory(res);

   req.action     = TRADE_ACTION_MODIFY;
   req.order      = ticket;
   req.symbol     = _Symbol;
   req.price      = newPrice;
   req.sl         = newSL;
   req.tp         = curTP;
   req.type_time  = timeType;
   req.expiration = expiry;

   ResetLastError();
   bool sent = OrderSend(req, res);

   if(sent && (IsTradeRetcodeDone(res.retcode)
               || res.retcode == TRADE_RETCODE_NO_CHANGES))
     {
      Print(CORE_LOG_PREFIX, " [", tag, "] PENDING MODIFIED #", ticket,
            " | price=", DoubleToString(newPrice, _Digits),
            " sl=", DoubleToString(newSL, _Digits));
      return(true);
     }

   Print(CORE_LOG_PREFIX, " [", tag, "] PENDING MODIFY FAILED #", ticket,
         " | retcode=", res.retcode, " (", res.comment, ")",
         " | error=", GetLastError());
   return(false);
  }

//+------------------------------------------------------------------+
//| ลบ pending คืน true เมื่อลบสำเร็จ หรือออเดอร์ไม่อยู่แล้ว            |
//| (ถูก Fill หรือถูกลบไปพอดี ถือว่าไม่มีให้ลบ)                        |
//+------------------------------------------------------------------+
bool RawPendingDelete(ulong ticket, string tag)
  {
   if(!g_engineReady)
      return(false);

   if(!OrderSelect(ticket))
      return(true);

   if(OrderGetString(ORDER_SYMBOL) != _Symbol
      || OrderGetInteger(ORDER_MAGIC) != InpMagicNumber)
     {
      Print(CORE_LOG_PREFIX, " [", tag, "] PENDING DELETE BLOCKED | ออเดอร์ #", ticket,
            " ไม่ใช่ของ EA นี้");
      return(false);
     }

   MqlTradeRequest req;
   MqlTradeResult  res;
   ZeroMemory(req);
   ZeroMemory(res);

   req.action = TRADE_ACTION_REMOVE;
   req.order  = ticket;

   ResetLastError();
   bool sent = OrderSend(req, res);

   if(sent && IsTradeRetcodeDone(res.retcode))
     {
      Print(CORE_LOG_PREFIX, " [", tag, "] PENDING DELETED #", ticket);
      return(true);
     }

   //--- ถูกเปลี่ยนสถานะไปพอดีระหว่างส่งคำสั่ง
   if(!OrderSelect(ticket))
      return(true);

   Print(CORE_LOG_PREFIX, " [", tag, "] PENDING DELETE FAILED #", ticket,
         " | retcode=", res.retcode, " (", res.comment, ")",
         " | error=", GetLastError());
   return(false);
  }

//+------------------------------------------------------------------+
//| รวม ticket ของ pending ทั้งหมดของ EA นี้ (Magic + Symbol)           |
//+------------------------------------------------------------------+
int CorePendingTickets(ulong &tickets[])
  {
   ArrayResize(tickets, 0);
   int n = 0;

   for(int i = 0; i < OrdersTotal(); i++)
     {
      ulong t = OrderGetTicket(i);

      if(t == 0)
         continue;

      if(OrderGetString(ORDER_SYMBOL) != _Symbol)
         continue;

      if(OrderGetInteger(ORDER_MAGIC) != InpMagicNumber)
         continue;

      if(!CoreIsPendingType((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE)))
         continue;

      ArrayResize(tickets, n + 1);
      tickets[n] = t;
      n++;
     }

   return(n);
  }

//--- นับ pending ตามฝั่ง (Buy = BUY_LIMIT + BUY_STOP, Sell = SELL_LIMIT + SELL_STOP)
int CorePendingCount(ENUM_POSITION_TYPE side)
  {
   ulong tk[];
   int total = CorePendingTickets(tk);
   int n = 0;

   for(int i = 0; i < total; i++)
     {
      if(!OrderSelect(tk[i]))
         continue;

      bool buy = CorePendingIsBuySide((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE));

      if((side == POSITION_TYPE_BUY && buy)
         || (side == POSITION_TYPE_SELL && !buy))
         n++;
     }

   return(n);
  }

int CorePendingTotal()
  {
   ulong tk[];
   return(CorePendingTickets(tk));
  }

//--- อ่านรายละเอียด pending ตาม ticket
bool CorePendingInfo(ulong ticket, ENUM_ORDER_TYPE &type, double &price, double &sl)
  {
   if(!OrderSelect(ticket))
      return(false);

   type  = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
   price = OrderGetDouble(ORDER_PRICE_OPEN);
   sl    = OrderGetDouble(ORDER_SL);
   return(true);
  }

//--- ลบ pending ทั้งหมดของฝั่งที่ระบุ คืนจำนวนที่ลบสำเร็จ
int CorePendingDeleteSide(ENUM_POSITION_TYPE side, string tag)
  {
   ulong tk[];
   int total = CorePendingTickets(tk);
   int removed = 0;

   for(int i = total - 1; i >= 0; i--)
     {
      if(!OrderSelect(tk[i]))
         continue;

      bool buy = CorePendingIsBuySide((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE));

      if((side == POSITION_TYPE_BUY && !buy)
         || (side == POSITION_TYPE_SELL && buy))
         continue;

      if(RawPendingDelete(tk[i], tag))
         removed++;
     }

   return(removed);
  }

//--- ลบ pending ทั้งหมดของ EA นี้ คืนจำนวนที่ลบสำเร็จ
int CorePendingDeleteAll(string tag)
  {
   ulong tk[];
   int total = CorePendingTickets(tk);
   int removed = 0;

   for(int i = total - 1; i >= 0; i--)
      if(RawPendingDelete(tk[i], tag))
         removed++;

   return(removed);
  }

#endif // CORE_PENDING_MQH