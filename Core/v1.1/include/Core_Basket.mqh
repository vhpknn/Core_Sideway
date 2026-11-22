//+------------------------------------------------------------------+
//|                                                  Core_Basket.mqh |
//|  นับ Position ของ EA นี้ (Symbol + Magic) แยกตามทิศทาง            |
//|  ที่มา: CountSide() ใน Hedge1_Engine.mqh (dcf4a12) ตรรกะเดียวกัน  |
//|  ไฟล์นี้อยู่ใต้ Report และ Engine เพื่อไม่ให้ include วนกัน       |
//|  การนับออเดอร์ค้าง (Pending) เพิ่มใน Core v1.1                    |
//+------------------------------------------------------------------+
#ifndef CORE_BASKET_MQH
#define CORE_BASKET_MQH

#include "Core_Inputs.mqh"
#include "Core_Utils.mqh"

//+------------------------------------------------------------------+
//| นับไม้ของบอทนี้ตามฝั่ง (Magic + คู่เงิน)                          |
//+------------------------------------------------------------------+
int CoreCountSide(ENUM_POSITION_TYPE type)
  {
   int count = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);

      if(ticket == 0)
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
         continue;

      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) == type)
         count++;
     }

   return(count);
  }

//+------------------------------------------------------------------+
//| จำนวน Position ทั้งหมดของบอทนี้ (Buy + Sell)                      |
//+------------------------------------------------------------------+
int CoreBasketPositions()
  {
   return(CoreCountSide(POSITION_TYPE_BUY)
          + CoreCountSide(POSITION_TYPE_SELL));
  }

#endif // CORE_BASKET_MQH