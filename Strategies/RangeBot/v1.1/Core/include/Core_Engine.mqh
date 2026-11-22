//+------------------------------------------------------------------+
//|                                                  Core_Engine.mqh |
//|  ประตูเปิดรอบใหม่ (Report + ทุน + Session + Timeout + Spread       |
//|  + สวิตช์ ON/OFF) + เริ่มรอบ Basket + ส่งออเดอร์ตลาด              |
//|  ที่มา: ส่วน Core ของ Hedge1_Engine.mqh (dcf4a12) ไม่แก้ตรรกะ       |
//|  ตรรกะเฉพาะ Hedge (เปิดคู่ Buy+Sell, Rollback, Manual) อยู่ที่     |
//|  Hedge_Strategy.mqh                                              |
//+------------------------------------------------------------------+
#ifndef CORE_ENGINE_MQH
#define CORE_ENGINE_MQH

#include "Core_Inputs.mqh"
#include "Core_Utils.mqh"
#include "Core_Capital.mqh"
#include "Core_Session.mqh"
#include "Core_Basket.mqh"
#include "Core_Report.mqh"
#include "Core_Trade.mqh"
#include "Core_Pause.mqh"

datetime g_emptySince = 0;        // เวลาที่ Basket ของ EA ว่างล่าสุด

string   g_gateReason = "INIT";   // เหตุผลล่าสุดที่ยังไม่เปิดรอบใหม่ (แสดงบน Panel)

//+------------------------------------------------------------------+
//| เริ่มระบบ Engine (เรียกจาก OnInit ของ EA หลัก)                     |
//+------------------------------------------------------------------+
void EngineInit()
  {
   g_engineReady = true;
   Print(CORE_LOG_PREFIX, " Engine พร้อมทำงาน Magic=", InpMagicNumber,
         " EffectiveLot=", DoubleToString(GetEffectiveLot(), 2));
  }

//+------------------------------------------------------------------+
//| เปิดไม้ 1 ฝั่งด้วย OrderSend ตรงๆ + ตรวจผล + log slippage        |
//| ตามกฎ Mirror-and-Verify                                          |
//+------------------------------------------------------------------+
bool OpenOneOrder(ENUM_POSITION_TYPE dir, double lot, string tag)
  {
   if(!g_engineReady)
      return(false);

   MqlTradeRequest req;
   MqlTradeResult  res;
   ZeroMemory(req);
   ZeroMemory(res);
   req.action       = TRADE_ACTION_DEAL;
   req.symbol       = _Symbol;
   req.volume       = lot;
   req.magic        = (ulong)InpMagicNumber;
   req.deviation    = InpDeviationPoints;
   req.type_filling = GetSymbolFilling();
   req.comment      = InpTradeComment;
   if(dir == POSITION_TYPE_BUY)
     {
      req.type  = ORDER_TYPE_BUY;
      req.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      //--- ส่ง Cut Loss SL ไปพร้อม Buy Order ตั้งแต่ต้น
      req.sl = NormalizeDouble(
                  req.price - PointsToPrice(InpCutLossPoints),
                  _Digits
               );
     }
   else
     {
      req.type  = ORDER_TYPE_SELL;
      req.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);

      //--- ส่ง Cut Loss SL ไปพร้อม Sell Order ตั้งแต่ต้น
      req.sl = NormalizeDouble(
                  req.price + PointsToPrice(InpCutLossPoints),
                  _Digits
               );
     }

   //--- Guard: ห้ามเปิดไม้หากราคาหรือ SL คำนวณผิดปกติ
   if(req.price <= 0.0 || req.sl <= 0.0)
     {
      Print(CORE_LOG_PREFIX, " [", tag, "] ปฏิเสธการเปิด Order เพราะราคา/SL ไม่ถูกต้อง",
            " | Price=", DoubleToString(req.price, _Digits),
            " | SL=", DoubleToString(req.sl, _Digits));
      return(false);
     }

   if(!OrderSend(req, res))
     {
      Print(CORE_LOG_PREFIX, " [", tag, "] ส่งคำสั่งเปิดออเดอร์ล้มเหลว retcode=", res.retcode,
            " (", res.comment, ") error=", GetLastError());
      return(false);
     }

   if(res.retcode != TRADE_RETCODE_DONE
      && res.retcode != TRADE_RETCODE_DONE_PARTIAL)
     {
      Print(CORE_LOG_PREFIX, " [", tag, "] เปิดออเดอร์ล้มเหลว retcode=", res.retcode,
            " (", res.comment, ")");
      return(false);
     }

   if(res.price > 0.0 && CorePoint() > 0.0)
     {
      double slipPts = MathAbs(res.price - req.price) / CorePoint();
      if(slipPts > 0.0)
         Print(CORE_LOG_PREFIX, " [", tag, "] slippage ", DoubleToString(slipPts, 1),
               " pts (", DoubleToString(req.price, _Digits), " -> ",
               DoubleToString(res.price, _Digits), ")");
     }
   return(true);
  }

//+------------------------------------------------------------------+
//| บันทึกฐาน Cycle ของ Basket ก่อนส่ง Order แรกของรอบ                |
//| (กลยุทธ์เรียกก่อนส่งออเดอร์แรกของรอบทุกครั้ง)                     |
//+------------------------------------------------------------------+
bool BeginBasketCycle()
  {
   double baseline = 0.0;

   if(!TryGetClosedNet(baseline))
     {
      Print(CORE_LOG_PREFIX, " CYCLE START BLOCKED",
            " | Closed history unavailable");
      return(false);
     }

   datetime startedAt = TimeCurrent();

   if(startedAt <= 0)
     {
      Print(CORE_LOG_PREFIX, " CYCLE START BLOCKED",
            " | Server time unavailable");
      return(false);
     }

   string netName = CoreStateGVName("RNET");
   string startName = CoreStateGVName("CSTART");

   if(StringLen(netName) > 63 || StringLen(startName) > 63)
     {
      Print(CORE_LOG_PREFIX, " CYCLE START BLOCKED",
            " | State key too long");
      return(false);
     }

   //--- ทำเครื่องหมายว่า State ยังไม่พร้อมก่อนเขียนฐานใหม่
   ResetLastError();

   if(GlobalVariableSet(startName, 0.0) == 0)
     {
      Print(CORE_LOG_PREFIX, " CYCLE START FAILED",
            " | Invalidate state error=", GetLastError());
      return(false);
     }

   GlobalVariablesFlush();

   ResetLastError();

   if(GlobalVariableSet(netName, baseline) == 0)
     {
      Print(CORE_LOG_PREFIX, " CYCLE START FAILED",
            " | Save baseline error=", GetLastError());
      return(false);
     }

   ResetLastError();

   if(GlobalVariableSet(startName, (double)startedAt) == 0)
     {
      Print(CORE_LOG_PREFIX, " CYCLE START FAILED",
            " | Save start time error=", GetLastError());
      return(false);
     }

   GlobalVariablesFlush();

   Print(CORE_LOG_PREFIX, " CYCLE START",
         " | Baseline=", DoubleToString(baseline, 2),
         " | Time=",
         TimeToString(startedAt, TIME_DATE | TIME_SECONDS));

   return(true);
  }

//+------------------------------------------------------------------+
//| ประตูเปิดรอบใหม่อัตโนมัติ                                          |
//| (สวิตช์ ON/OFF + Report + ทุน + Session + Timeout + สเปรด)        |
//| เก็บเหตุผลไว้แสดงบน Panel                                        |
//+------------------------------------------------------------------+
bool CanOpenAuto(datetime sinceTime, string &reason)
  {
   //--- สวิตช์ OFF ต่อกราฟ ตรวจก่อนทุกเงื่อนไข
   if(CoreIsPaused())
     { reason = "PAUSED"; return(false); }

   if(g_reportBlocksEntry)
     { reason = "WAIT_REPORT"; return(false); }

   double equity = 0.0;

   if(!TryGetVirtualEquity(equity))
     { reason = "CAPITAL_UNAVAILABLE"; return(false); }

   if(equity <= 0.0)
     { reason = "CAPITAL_DEAD"; return(false); }
   if(IsAutoBlockedBySession())
     { reason = "SESSION_BLOCK"; return(false); }
   if(InpUseTimeout)
     {
      if(sinceTime == 0 || TimeCurrent() - sinceTime < InpTimeoutSeconds)
        { reason = "WAIT_TIMEOUT"; return(false); }
     }
   if(InpUseSpreadCheck)
     {
      if(GetSpreadPoints() > InpMaxSpreadPoints)
        { reason = "WAIT_SPREAD"; return(false); }
     }
   reason = "READY";
   return(true);
  }

//+------------------------------------------------------------------+
//| ข้อมูลสำหรับ Panel: เวลา Timeout คงเหลือ (วินาที)                |
//+------------------------------------------------------------------+
int GetTimeoutRemaining()
  {
   if(!InpUseTimeout || g_emptySince == 0)
      return(0);

   int remain = InpTimeoutSeconds
                - (int)(TimeCurrent() - g_emptySince);

   if(remain < 0)
      remain = 0;

   return(remain);
  }

//--- ข้อความสถานะล่าสุดว่าทำไมยังไม่เปิดรอบใหม่ (สำหรับ Panel)
string GetEngineGateText() { return(g_gateReason); }

#endif // CORE_ENGINE_MQH