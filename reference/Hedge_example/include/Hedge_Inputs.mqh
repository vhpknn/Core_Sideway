//+------------------------------------------------------------------+
//|                                                  Hedge_Inputs.mqh|
//|  Input เฉพาะกลยุทธ์ Hedge (ย้ายมาจากกลุ่ม 2 ของ Hedge1_Inputs)    |
//+------------------------------------------------------------------+
#ifndef HEDGE_INPUTS_MQH
#define HEDGE_INPUTS_MQH

input group "=== H. Hedge Strategy ==="
#ifdef INPUT_LANG_EN
input bool InpReopenOnEmpty = true;   // InpReopenOnEmpty - Open a new Hedge pair only when the basket is empty
#else
input bool InpReopenOnEmpty = true;   // เปิดคู่ Hedge รอบใหม่เมื่อ Basket ว่างเท่านั้น
#endif

#ifdef INPUT_LANG_EN
input int  InpMaxAutoRounds = 0;      // InpMaxAutoRounds - Max AUTO Hedge rounds per session period (0 = unlimited). Resets when a Session Block window ends
#else
input int  InpMaxAutoRounds = 0;      // จำกัดจำนวนรอบเปิดคู่อัตโนมัติต่อช่วง (0 = ไม่จำกัด) รีเซ็ตเมื่อช่วง Session Block สิ้นสุด
#endif

#endif // HEDGE_INPUTS_MQH