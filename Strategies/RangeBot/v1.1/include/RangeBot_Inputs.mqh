//+------------------------------------------------------------------+
//|                                              RangeBot_Inputs.mqh |
//|  Input เฉพาะกลยุทธ์ (ตอนนี้ยังไม่มี)                              |
//|  กติกา: ต้องมีสองภาษา ชื่อ ชนิด ลำดับ ค่าเริ่มต้นเหมือนกัน       |
//|  ตัวอย่างรูปแบบ ดู Hedge_Inputs.mqh ใน reference/Hedge_example/     |
//+------------------------------------------------------------------+
#ifndef RANGEBOT_INPUTS_MQH
#define RANGEBOT_INPUTS_MQH

//--- ชนิดบัญชีที่อนุญาตให้ RangeBot ทำงาน (เลือกใน Input)
#ifdef INPUT_LANG_EN
enum ENUM_RB_ACCOUNT_MODE
  {
   RB_ACCT_AUTO    = 0,   // AUTO (Hedging or Netting)
   RB_ACCT_HEDGING = 1,   // HEDGING accounts only
   RB_ACCT_NETTING = 2    // NETTING accounts only
  };
#else
enum ENUM_RB_ACCOUNT_MODE
  {
   RB_ACCT_AUTO    = 0,   // อัตโนมัติ (Hedging หรือ Netting)
   RB_ACCT_HEDGING = 1,   // เฉพาะบัญชี Hedging
   RB_ACCT_NETTING = 2    // เฉพาะบัญชี Netting
  };
#endif

input group "=== R. RangeBot ==="
#ifdef INPUT_LANG_EN
input ENUM_RB_ACCOUNT_MODE InpRbAccountMode = RB_ACCT_AUTO;   // InpRbAccountMode - Account type allowed (AUTO = Hedging or Netting)
#else
input ENUM_RB_ACCOUNT_MODE InpRbAccountMode = RB_ACCT_AUTO;   // ชนิดบัญชีที่อนุญาต (AUTO = Hedging หรือ Netting ก็ได้)
#endif

input group "=== R1. RangeBot General ==="
#ifdef INPUT_LANG_EN
input ENUM_TIMEFRAMES InpRbEntryTF = PERIOD_H1;   // InpRbEntryTF - Entry timeframe (decisions are made on a new bar of this TF)
input int    InpRbAtrPeriod        = 14;          // InpRbAtrPeriod - ATR period (range and SL/TP)
input bool   InpRbLogBar           = true;        // InpRbLogBar - Print one summary log line per new bar
input bool   InpRbDrawRange        = true;        // InpRbDrawRange - Draw range high/low lines on the chart
#else
input ENUM_TIMEFRAMES InpRbEntryTF = PERIOD_H1;   // ไทม์เฟรมเข้าเทรด (ตัดสินใจเมื่อเกิดแท่งใหม่ของ TF นี้)
input int    InpRbAtrPeriod        = 14;          // ช่วง ATR (ใช้กับกรอบและ SL/TP)
input bool   InpRbLogBar           = true;        // พิมพ์ Log สรุป 1 บรรทัดต่อแท่งใหม่
input bool   InpRbDrawRange        = true;        // วาดเส้นบน/ล่างของกรอบบนกราฟ
#endif

input group "=== R2. Regime ==="
#ifdef INPUT_LANG_EN
input int    InpRbAdxPeriod        = 14;          // InpRbAdxPeriod - ADX period
input double InpRbAdxRangeMax      = 20.0;        // InpRbAdxRangeMax - ADX at or below this can be RANGE
input double InpRbAdxTrendMin      = 25.0;        // InpRbAdxTrendMin - ADX at or above this can be TREND
input int    InpRbAdxRisingBars    = 3;           // InpRbAdxRisingBars - ADX must rise for this many bars to be TREND
input int    InpRbBbPeriod         = 20;          // InpRbBbPeriod - Bollinger period
input double InpRbBbDev            = 2.0;         // InpRbBbDev - Bollinger deviation
input int    InpRbBbwAvgPeriod     = 50;          // InpRbBbwAvgPeriod - Bars used for average Bollinger width
input double InpRbSqueezeFactor    = 1.0;         // InpRbSqueezeFactor - RANGE needs width <= factor x average width
input int    InpRbEmaFast          = 20;          // InpRbEmaFast - Fast EMA
input int    InpRbEmaMid           = 50;          // InpRbEmaMid - Mid EMA
input int    InpRbEmaSlow          = 200;         // InpRbEmaSlow - Slow EMA
input int    InpRbRegimeConfirmBars = 2;          // InpRbRegimeConfirmBars - Bars the same result must hold before switching regime
#else
input int    InpRbAdxPeriod        = 14;          // ช่วง ADX
input double InpRbAdxRangeMax      = 20.0;        // ADX ไม่เกินค่านี้ จึงเป็น RANGE ได้
input double InpRbAdxTrendMin      = 25.0;        // ADX ตั้งแต่ค่านี้ขึ้นไป จึงเป็น TREND ได้
input int    InpRbAdxRisingBars    = 3;           // ADX ต้องเพิ่มต่อเนื่องกี่แท่ง จึงเป็น TREND
input int    InpRbBbPeriod         = 20;          // ช่วง Bollinger
input double InpRbBbDev            = 2.0;         // ค่าเบี่ยงเบน Bollinger
input int    InpRbBbwAvgPeriod     = 50;          // จำนวนแท่งที่ใช้เฉลี่ยความกว้าง Bollinger
input double InpRbSqueezeFactor    = 1.0;         // RANGE ต้องมีความกว้าง <= ค่านี้ x ความกว้างเฉลี่ย
input int    InpRbEmaFast          = 20;          // EMA เร็ว
input int    InpRbEmaMid           = 50;          // EMA กลาง
input int    InpRbEmaSlow          = 200;         // EMA ช้า
input int    InpRbRegimeConfirmBars = 2;          // ผลต้องตรงกันกี่แท่งติดกัน จึงเปลี่ยนสภาพตลาด
#endif

input group "=== R3. Range ==="
#ifdef INPUT_LANG_EN
input int    InpRbRangeLookback      = 30;        // InpRbRangeLookback - Bars used to build the range
input int    InpRbRangeExcludeBars   = 1;         // InpRbRangeExcludeBars - Latest closed bars excluded (so a sweep wick does not widen the range)
input double InpRbRangeMinHeightAtr  = 2.0;       // InpRbRangeMinHeightAtr - Minimum range height (x ATR)
input double InpRbRangeMaxHeightAtr  = 6.0;       // InpRbRangeMaxHeightAtr - Maximum range height (x ATR)
input int    InpRbRangeMinTouches    = 2;         // InpRbRangeMinTouches - Minimum touches on each edge
input double InpRbRangeTouchTolAtr   = 0.25;      // InpRbRangeTouchTolAtr - Touch tolerance (x ATR)
input bool   InpRbUseRangeLock       = true;      // InpRbUseRangeLock - Keep the edges locked until break or expiry
#else
input int    InpRbRangeLookback      = 30;        // จำนวนแท่งที่ใช้สร้างกรอบ
input int    InpRbRangeExcludeBars   = 1;         // ไม่นับแท่งล่าสุดที่ปิดแล้วกี่แท่ง (ไส้ Sweep จะได้ไม่ขยายกรอบ)
input double InpRbRangeMinHeightAtr  = 2.0;       // ความสูงกรอบขั้นต่ำ (เท่าของ ATR)
input double InpRbRangeMaxHeightAtr  = 6.0;       // ความสูงกรอบสูงสุด (เท่าของ ATR)
input int    InpRbRangeMinTouches    = 2;         // จำนวนครั้งที่แตะขอบแต่ละด้านขั้นต่ำ
input double InpRbRangeTouchTolAtr   = 0.25;      // ระยะที่นับว่าแตะขอบ (เท่าของ ATR)
input bool   InpRbUseRangeLock       = true;      // ล็อกขอบกรอบไว้จนกว่าจะเบรกหรือหมดอายุ
#endif

#endif // RANGEBOT_INPUTS_MQH